% Copyright: Mohan Parthasarathy 2026
function run_PINN_ForcedODE(app, trainParams, user_params)
    %% 1. Setup & Parsing
    k_true = user_params{1}; 
    Q_str  = user_params{2};
    noise_pct = trainParams.Noise; 
    max_epochs = trainParams.MaxEpochs; 
    warmup_epochs = trainParams.WarmupEpochs;
    
    % Safely parse the user's Q(t) string into an anonymous function
    try
        Q_fun = str2func("@(t) " + Q_str); 
        Q_fun(0); % Test evaluation
    catch
        app.LogTextArea.Value = ["ERROR: Invalid Q(t) syntax. Use MATLAB syntax (e.g., sin(2*t))."; app.LogTextArea.Value]; 
        return; 
    end
    
    t_min = 0; t_max = 5; 
    t = linspace(t_min, t_max, 60)';
    
    app.LogTextArea.Value = ["Generating Empirically Forced Data..."; app.LogTextArea.Value]; 
    drawnow;
    
    % Generate True Data using ODE45
    ode_fun = @(t,y) k_true * y + Q_fun(t); 
    [~, y_true] = ode45(ode_fun, t, 1.0);
    
    % Corrupt with noise, ensuring positivity for log transform
    rng(42); 
    y_noisy = y_true .* (1 + (noise_pct/100) * randn(size(y_true))); 
    y_noisy = max(1e-4, y_noisy); 
    
    % The Logarithmic Transformation: u = ln(y)
    u_data = log(y_noisy); 
    u_mean = mean(u_data); 
    u_std = std(u_data) + 1e-6; 
    u_norm_data = (u_data - u_mean) / u_std;
    
    t_norm = 2*(t - t_min)/(t_max - t_min) - 1; 
    dt_scale = (t_max - t_min)/2;
    
    dlT = dlarray(t_norm', 'CB'); 
    dlU = dlarray(u_norm_data', 'CB'); 
    dlTf = dlarray(linspace(-1,1,1000), 'CB'); 
    
    %% 2. Network Architecture (Predicting stable variable u)
    layers = [
        featureInputLayer(1)
        fullyConnectedLayer(50)
        tanhLayer
        fullyConnectedLayer(50)
        tanhLayer
        fullyConnectedLayer(1)
    ];
    dlnet = dlnetwork(layerGraph(layers));
    k_est = dlarray(0.1);
    
    %% 3. Plot Initialization
    cla(app.TopAxes); hold(app.TopAxes, 'on');
    t_dense = linspace(t_min, t_max, 200);
    plot(app.TopAxes, t_dense, Q_fun(t_dense), 'r-', 'LineWidth', 2);
    title(app.TopAxes, ['Environmental Forcing Q(t) = ' char(Q_str)]); 
    
    cla(app.BottomAxes); hold(app.BottomAxes, 'on');
    plot(app.BottomAxes, t, y_noisy, 'k.', 'MarkerSize', 12, 'DisplayName', 'Noisy Population Data');
    hPred = animatedline(app.BottomAxes, 'Color', '#0072BD', 'LineWidth', 2, 'DisplayName', 'PINN Recovered State');
    legend(app.BottomAxes, 'Location', 'northwest');
    
    %% 4. Training Loop
    avgNet=[]; sqNet=[]; avgK=[]; sqK=[];
    app.LogTextArea.Value = ["Executing Log-Transformed Training..."; app.LogTextArea.Value]; 
    drawnow;
    
    phase2_end = warmup_epochs + floor((max_epochs - warmup_epochs) * 0.6);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        if epoch <= warmup_epochs
            lam=0; lr=0.005; phase="Mapping Data"; upd_k=false;
        elseif epoch <= phase2_end
            lam=0.1; lr=0.005; phase="Solving Inverse"; upd_k=true; 
        else
            lam=1.0; lr=0.001; phase="Physics Fine Tune"; upd_k=true; 
        end
        
        [loss, gNet, gK] = dlfeval(@lossLogODE, dlnet, k_est, dlT, dlU, dlTf, dt_scale, u_mean, u_std, lam, Q_fun, t_min, t_max);
        
        [dlnet, avgNet, sqNet] = adamupdate(dlnet, gNet, avgNet, sqNet, epoch, lr);
        if upd_k, [k_est, avgK, sqK] = adamupdate(k_est, gK, avgK, sqK, epoch, lr); end
        
        if mod(epoch, 100) == 0
            if mod(epoch, 500) == 0 || epoch == 1
                app.LogTextArea.Value = [sprintf("Ep %d (%s) | Loss: %.4e", epoch, phase, extractdata(loss)); app.LogTextArea.Value]; 
            end
            
            % Inverse transform for visualization: y = exp(u*std + mu)
            t_eval_norm = dlarray(linspace(-1,1,100), 'CB'); 
            t_eval_real = linspace(t_min, t_max, 100);
            u_pred_norm = extractdata(forward(dlnet, t_eval_norm));
            y_pred_real = exp(u_pred_norm * u_std + u_mean);
            
            clearpoints(hPred); 
            addpoints(hPred, t_eval_real, y_pred_real);
            drawnow limitrate;
        end
    end
    
    final_k = extractdata(k_est);
    err = abs(final_k - k_true) / k_true * 100;
    app.UITable.Data = {'Intrinsic k', k_true, final_k, err};
    app.LogTextArea.Value = ["Explore Phase Complete."; app.LogTextArea.Value];
end

function [loss, gNet, gK] = lossLogODE(net, k, Td, Ud, Tf, dt_s, u_mu, u_sig, lam, Q_fun, t_min, t_max)
    U_pred = forward(net, Td); 
    lD = mse(U_pred, Ud);
    
    if lam > 0
        U_f_norm = forward(net, Tf); 
        U_f_real = U_f_norm * u_sig + u_mu;
        
        dU_norm = dlgradient(sum(U_f_norm,'all'), Tf); 
        dU_dt = dU_norm * (u_sig / dt_s);
        
        T_real = (Tf + 1)/2 * (t_max - t_min) + t_min; 
        Q_val = Q_fun(T_real);
        
        % Residual: u' - k - Q(t)*e^(-u) = 0
        res = dU_dt - k - Q_val .* exp(-U_f_real); 
        lP = mean(res.^2, 'all');
    else 
        lP = dlarray(0); 
    end
    
    loss = 10*lD + lam*lP; 
    gNet = dlgradient(loss, net.Learnables); 
    gK = dlgradient(loss, k);
end
