% Copyright: Mohan Parthasarathy 2026
function run_PINN_ForcedODE(app, trainParams, user_params)
    %% 1. Setup & Parsing
    k_true = user_params{1}; 
    k_init = user_params{2};
    Q_str  = user_params{3};
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
    rng(42); % Reproducible network initialization for classroom demonstrations
    layers = [
        featureInputLayer(1)
        fullyConnectedLayer(50)
        tanhLayer
        fullyConnectedLayer(50)
        tanhLayer
        fullyConnectedLayer(1)
    ];
    dlnet = dlnetwork(layerGraph(layers));
    k_est = dlarray(k_init);
    
    %% 3. Plot Initialization
    cla(app.TopAxes); hold(app.TopAxes, 'on');
    plot(app.TopAxes, t, y_noisy, 'k.', 'MarkerSize', 12, 'DisplayName', 'Noisy Population Data');
    hPred = animatedline(app.TopAxes, 'Color', '#0072BD', 'LineWidth', 2, 'DisplayName', 'PINN Recovered State');
    yyaxis(app.TopAxes, 'right');
    app.TopAxes.YAxis(2).Visible = 'on';
    t_dense = linspace(t_min, t_max, 200);
    plot(app.TopAxes, t_dense, Q_fun(t_dense), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Q(t)');
    ylabel(app.TopAxes, 'Forcing Q(t)');
    yyaxis(app.TopAxes, 'left');
    ylabel(app.TopAxes, 'Population y(t)');
    title(app.TopAxes, ['Forced ODE: Q(t) = ' char(Q_str)]);
    legend(app.TopAxes, 'Location', 'northwest');
    
    yyaxis(app.TopAxes, 'left');

    cla(app.BottomAxes);
    yyaxis(app.BottomAxes, 'right');
    ylabel(app.BottomAxes, '');
    cla(app.BottomAxes);
    
    yyaxis(app.BottomAxes, 'left');
    cla(app.BottomAxes);
    hold(app.BottomAxes, 'on');
    
    hK = animatedline(app.BottomAxes, 'Color', 'r', 'LineWidth', 1.5, 'DisplayName', 'Estimated k');
    yline(app.BottomAxes, k_true, 'k--', 'DisplayName', 'True k');
    title(app.BottomAxes, 'Parameter Convergence');
    xlabel(app.BottomAxes, 'Epoch');
    ylabel(app.BottomAxes, 'k');
    legend(app.BottomAxes, 'Location', 'best');
    if numel(app.BottomAxes.YAxis) > 1
        app.BottomAxes.YAxis(2).Label.String = '';
        app.BottomAxes.YAxis(2).Visible = 'off';
    end
    yyaxis(app.BottomAxes, 'left');

    %% 4. Training Loop
    avgNet=[]; sqNet=[]; avgK=[]; sqK=[];
    app.LogTextArea.Value = [
        "Executing Log-Transformed Training...";
        sprintf("True k = %.4g | Initial k = %.4g", k_true, k_init);
        "Log-state training active: optimizing u(t)=log(y(t)) for numerical stability.";
        "Log columns: L_total, L_data, L_phys, w_data, w_phys.";
        app.LogTextArea.Value
    ]; 
    drawnow;
    
    phase2_end = warmup_epochs + floor((max_epochs - warmup_epochs) * 0.6);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        if epoch <= warmup_epochs
            lam=0; lr=0.005; phase="Fit Data"; upd_k=false;
        elseif epoch <= phase2_end
            lam=0.1; lr=0.005; phase="Find Params"; upd_k=true; 
        else
            lam=1.0; lr=0.001; phase="Fine Tune"; upd_k=true; 
        end
        
        [loss, gNet, gK, lD, lP] = dlfeval(@lossLogODE, dlnet, k_est, dlT, dlU, dlTf, dt_scale, u_mean, u_std, lam, Q_fun, t_min, t_max);
        
        [dlnet, avgNet, sqNet] = adamupdate(dlnet, gNet, avgNet, sqNet, epoch, lr);
        if upd_k, [k_est, avgK, sqK] = adamupdate(k_est, gK, avgK, sqK, epoch, lr); end
        
        if mod(epoch, 100) == 0
            if mod(epoch, 500) == 0 || epoch == 1
                app.LogTextArea.Value = [sprintf("Ep %d | Phase: %s | L_total=%.4e | L_data=%.4e | L_phys=%.4e | w_data=10 | w_phys=%g | log_state=on", epoch, char(phase), extractdata(loss), extractdata(lD), extractdata(lP), lam); app.LogTextArea.Value]; 
            end
            
            % Inverse transform for visualization: y = exp(u*std + mu)
            t_eval_norm = dlarray(linspace(-1,1,100), 'CB'); 
            t_eval_real = linspace(t_min, t_max, 100);
            u_pred_norm = extractdata(forward(dlnet, t_eval_norm));
            y_pred_real = exp(u_pred_norm * u_std + u_mean);
            
            clearpoints(hPred); 
            addpoints(hPred, t_eval_real, y_pred_real);
            addpoints(hK, epoch, extractdata(k_est));
            drawnow limitrate;
        end
    end
    
    final_k = extractdata(k_est);
    err = abs(final_k - k_true) / k_true * 100;
    app.UITable.ColumnName = {'Param', 'True Value', 'Initial Guess', 'Estimate', 'Err %'};
    app.UITable.Data = {'Intrinsic k', k_true, k_init, final_k, err};
    app.LogTextArea.Value = ["Explore Phase Complete."; app.LogTextArea.Value];
end

function [loss, gNet, gK, lD, lP] = lossLogODE(net, k, Td, Ud, Tf, dt_s, u_mu, u_sig, lam, Q_fun, t_min, t_max)
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
