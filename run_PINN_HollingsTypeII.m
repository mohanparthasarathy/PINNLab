% Copyright: Mohan Parthasarathy 2026
function run_PINN_HollingsTypeII(app, trainParams, input_params, use_real_data)
    %% 1. Data Ingestion / Generation
    max_epochs = trainParams.MaxEpochs;
    warmup_epochs = trainParams.WarmupEpochs;
    
    if use_real_data
        % Open file explorer for user to select a CSV
        [file, path] = uigetfile('*.csv', 'Select Empirical Data CSV');
        if isequal(file, 0)
            app.LogTextArea.Value = ["Data upload canceled by user."; app.LogTextArea.Value];
            return;
        end
        
        app.LogTextArea.Value = ["Ingesting Dataset: " + string(file) + "..."; app.LogTextArea.Value]; drawnow;
        
        try
            tbl = readtable(fullfile(path, file));
            varNames = tbl.Properties.VariableNames;
            
            % Check if it's the specific Hare/Lynx dataset
            if ismember('Year', varNames) && ismember('Hare', varNames) && ismember('Lynx', varNames)
                t_raw = tbl.Year;
                Y_raw = [tbl.Hare, tbl.Lynx]'; 
            else
                % Generic Fallback: Col 1 = Time, Col 2 = State 1, Col 3 = State 2
                app.LogTextArea.Value = ["Custom data detected. Mapping Col 1 to Time, Col 2 to Prey, Col 3 to Predator."; app.LogTextArea.Value]; drawnow;
                t_raw = table2array(tbl(:,1));
                Y_raw = table2array(tbl(:, 2:3))'; 
            end
            
            % Zero-index the time vector
            t = t_raw - min(t_raw);
            t_min = min(t); t_max = max(t);
            
        catch ME
            app.LogTextArea.Value = ["ERROR reading CSV: " + string(ME.message); app.LogTextArea.Value];
            return;
        end
        
        % For real data, input_params from UI are INITIAL GUESSES
        p_true_ref = input_params(:); 
        p_scale = input_params(:); % Use user guesses as the mathematical scale
    else
        app.LogTextArea.Value = ["Generating Synthetic Holling's Data..."; app.LogTextArea.Value]; drawnow;
        % For synthetic data, input_params from UI are TRUE PARAMETERS
        noise_pct = trainParams.Noise;
        p_true_ref = input_params(:);
        
        t_min = 0; t_max = 20; 
        t = linspace(t_min, t_max, 100)';
        
        % Generate True ODE Solution
        ode_fun = @(t,y) [
            p_true_ref(1)*y(1)*(1 - y(1)/p_true_ref(2)) - (p_true_ref(3)*y(1)*y(2))/(p_true_ref(4) + y(1));
            -p_true_ref(5)*y(2) + (p_true_ref(6)*p_true_ref(3)*y(1)*y(2))/(p_true_ref(4) + y(1))
        ];
        [~, Y_true] = ode45(ode_fun, t, [20; 5]);
        
        % Corrupt with noise
        rng(42); 
        Y_raw = Y_true' + (noise_pct/100) .* std(Y_true') .* randn(size(Y_true'));
        Y_raw = max(0.1, Y_raw); % Ensure strictly positive biological populations
        
        % Set scale intentionally off the truth to simulate inverse search
        p_scale = p_true_ref .* 0.6; 
    end
    
    % Domain Normalization 
    t_norm = 2*(t - t_min)/(t_max - t_min) - 1; 
    dt_scale = (t_max - t_min)/2;
    
    Y_mu = mean(Y_raw, 2); 
    Y_sig = std(Y_raw, 0, 2) + 1e-6; 
    Y_norm = (Y_raw - Y_mu) ./ Y_sig;
    
    dlT = dlarray(t_norm', 'CB'); 
    dlY = dlarray(Y_norm, 'CB'); 
    dlTf = dlarray(linspace(-1, 1, 1000), 'CB');
    
    %% 2. Network Architecture & Parameter Initialization
    layers = [
        featureInputLayer(1)
        fullyConnectedLayer(64)
        tanhLayer
        fullyConnectedLayer(64)
        tanhLayer
        fullyConnectedLayer(64)
        tanhLayer
        fullyConnectedLayer(2)
    ];
    dlnet = dlnetwork(layerGraph(layers));
    
    % The network optimizes a normalized vector starting at 1.0
    p_est_norm = dlarray(ones(6,1)); 
    
    %% 3. Plot Initialization
    cla(app.TopAxes); hold(app.TopAxes, 'on');
    plot(app.TopAxes, t, Y_raw(1,:), 'b.', 'MarkerSize', 10, 'DisplayName', 'Prey Data');
    plot(app.TopAxes, t, Y_raw(2,:), 'r.', 'MarkerSize', 10, 'DisplayName', 'Predator Data');
    
    hPrey = animatedline(app.TopAxes, 'Color', 'b', 'LineWidth', 2, 'DisplayName', 'PINN Prey');
    hPred = animatedline(app.TopAxes, 'Color', 'r', 'LineWidth', 2, 'DisplayName', 'PINN Predator');
    legend(app.TopAxes, 'Location', 'northeast');
    
    cla(app.BottomAxes); hold(app.BottomAxes, 'on');
    colors = lines(6);
    hParams = gobjects(6,1);
    p_names = {'\alpha', 'K', '\beta', 'c', '\gamma', '\delta'};
    for i=1:6
        if ~use_real_data
            yline(app.BottomAxes, p_true_ref(i), '--', 'Color', colors(i,:), 'HandleVisibility', 'off');
        end
        hParams(i) = animatedline(app.BottomAxes, 'Color', colors(i,:), 'LineWidth', 1.5, 'DisplayName', p_names{i});
    end
    title(app.BottomAxes, 'High-Dimensional Parameter Convergence');
    legend(app.BottomAxes, 'Location', 'eastoutside');
    
    %% 4. Training Loop
    avgNet=[]; sqNet=[]; avgP=[]; sqP=[];
    app.LogTextArea.Value = ["Starting 6-Parameter Optimization..."; app.LogTextArea.Value]; drawnow;
    
    phase2_end = warmup_epochs + floor((max_epochs - warmup_epochs) * 0.7);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        % Phased Learning with Joint Unfreezing
        if epoch <= warmup_epochs
            lam = 0; lr_net = 1e-3; lr_p = 0; phase = "Data Mapping"; dw = 1;
        elseif epoch <= phase2_end
            % Let the network adjust slightly while params learn aggressively
            lam = 1.0; lr_net = 1e-4; lr_p = 5e-3; phase = "Physics Inverse"; dw = 1;
        else
            lam = 1.0; lr_net = 1e-4; lr_p = 1e-4; phase = "Fine Tuning"; dw = 20; 
        end
        
        [loss, gNet, gP] = dlfeval(@lossHollings, dlnet, p_est_norm, p_scale, dlT, dlY, dlTf, dt_scale, Y_mu, Y_sig, lam, dw);
        
        if lr_net > 0
            [dlnet, avgNet, sqNet] = adamupdate(dlnet, gNet, avgNet, sqNet, epoch, lr_net);
        end
        if lr_p > 0
            [p_est_norm, avgP, sqP] = adamupdate(p_est_norm, gP, avgP, sqP, epoch, lr_p); 
        end
        
        if mod(epoch, 100) == 0
            if mod(epoch, 500) == 0 || epoch < 200
                app.LogTextArea.Value = [sprintf("Ep %d (%s) | Loss: %.4e", epoch, phase, extractdata(loss)); app.LogTextArea.Value]; 
            end
            
            t_eval_norm = dlarray(linspace(-1, 1, 200), 'CB');
            t_eval_real = linspace(t_min, t_max, 200);
            
            Y_eval_norm = extractdata(forward(dlnet, t_eval_norm));
            Y_eval_real = Y_eval_norm .* Y_sig + Y_mu;
            
            clearpoints(hPrey); clearpoints(hPred);
            addpoints(hPrey, t_eval_real, Y_eval_real(1,:));
            addpoints(hPred, t_eval_real, Y_eval_real(2,:));
            
            % Re-scale parameters for plotting
            p_vals = abs(extractdata(p_est_norm)) .* p_scale;
            for i=1:6
                addpoints(hParams(i), epoch, p_vals(i)); 
            end
            drawnow limitrate;
        end
    end
    
    % Post-Run Table Update
    p_final = abs(extractdata(p_est_norm)) .* p_scale;
    if use_real_data
        app.UITable.Data = {
            'Alpha', input_params(1), p_final(1), 'N/A';
            'K (Capacity)', input_params(2), p_final(2), 'N/A';
            'Beta', input_params(3), p_final(3), 'N/A';
            'c (Half-Sat)', input_params(4), p_final(4), 'N/A';
            'Gamma', input_params(5), p_final(5), 'N/A';
            'Delta', input_params(6), p_final(6), 'N/A';
        };
    else
        app.UITable.Data = {
            'Alpha', p_true_ref(1), p_final(1), abs(p_final(1)-p_true_ref(1))/p_true_ref(1)*100;
            'K (Capacity)', p_true_ref(2), p_final(2), abs(p_final(2)-p_true_ref(2))/p_true_ref(2)*100;
            'Beta', p_true_ref(3), p_final(3), abs(p_final(3)-p_true_ref(3))/p_true_ref(3)*100;
            'c (Half-Sat)', p_true_ref(4), p_final(4), abs(p_final(4)-p_true_ref(4))/p_true_ref(4)*100;
            'Gamma', p_true_ref(5), p_final(5), abs(p_final(5)-p_true_ref(5))/p_true_ref(5)*100;
            'Delta', p_true_ref(6), p_final(6), abs(p_final(6)-p_true_ref(6))/p_true_ref(6)*100;
        };
    end
    app.LogTextArea.Value = ["Optimization Complete."; app.LogTextArea.Value];
end

% Core Loss Function
function [loss, gNet, gP_norm] = lossHollings(net, p_norm, p_scale, Td, Yd, Tf, dt_s, Y_mu, Y_sig, lam, dw)
    
    % 1. Data Loss
    Yp = forward(net, Td); 
    lD = mean((Yp - Yd).^2, 'all'); 
    
    % 2. Physics Loss
    if lam > 0
        Yf_norm = forward(net, Tf);
        Yf_real = Yf_norm .* Y_sig + Y_mu; 
        
        x = max(Yf_real(1,:), 0.1); 
        y = max(Yf_real(2,:), 0.1);
        
        p = abs(p_norm) .* p_scale;
        
        dX_dt = dlgradient(sum(Yf_norm(1,:),'all'), Tf) * (Y_sig(1) / dt_s);
        dY_dt = dlgradient(sum(Yf_norm(2,:),'all'), Tf) * (Y_sig(2) / dt_s);
        
        res_x = dX_dt - (p(1).*x.*(1 - x./p(2)) - (p(3).*x.*y)./(p(4) + x));
        res_y = dY_dt - (-p(5).*y + (p(6).*p(3).*x.*y)./(p(4) + x));
        
        lP = mean(res_x.^2, 'all') / (Y_sig(1)^2) + mean(res_y.^2, 'all') / (Y_sig(2)^2);
    else
        lP = dlarray(0);
    end
    
    loss = dw * lD + lam * lP;
    gNet = dlgradient(loss, net.Learnables); 
    gP_norm = dlgradient(loss, p_norm);
end
