% Copyright: Mohan Parthasarathy 2026
function run_PINN_HollingsTypeII(app, trainParams, true_params, init_params, use_real_data)
    %% 1. Data Ingestion / Generation
    max_epochs = trainParams.MaxEpochs;
    warmup_epochs = trainParams.WarmupEpochs;
    
    if use_real_data
        % Open file explorer for user to select a CSV. Default to the repository data folder when present.
        defaultDataFile = fullfile(fileparts(mfilename('fullpath')), 'data', 'hare_lynx_data.csv');
        if isfile(defaultDataFile)
            [file, path] = uigetfile('*.csv', 'Select Empirical Data CSV', defaultDataFile);
        else
            [file, path] = uigetfile('*.csv', 'Select Empirical Data CSV');
        end
        if isequal(file, 0)
            app.LogTextArea.Value = ["Data upload canceled by user."; app.LogTextArea.Value];
            return;
        end
        
        app.LogTextArea.Value = ["Ingesting Dataset: " + string(file) + "..."; app.LogTextArea.Value]; drawnow;
        app.LogTextArea.Value = ["Real-data mode: true parameters are unknown. Table values are initial guesses and fitted estimates, not recovery errors."; app.LogTextArea.Value]; drawnow;
        app.LogTextArea.Value = ["Real-data note: Hudson Bay trapping counts are noisy proxy observations; fitted parameters should be interpreted as model-calibration values, not biological ground truth."; app.LogTextArea.Value]; drawnow;
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
            
            % Zero-index the time vector and ensure numeric arrays
            t = double(t_raw(:) - min(t_raw));
            Y_raw = double(Y_raw);
            t_min = min(t); 
            t_max = max(t);            
        catch ME
            app.LogTextArea.Value = ["ERROR reading CSV: " + string(ME.message); app.LogTextArea.Value];
            return;
        end
        
        % For real data, init_params from UI are INITIAL GUESSES.
        % There are no true parameters for the historical dataset.
        p_true_ref = init_params(:);
        p_init = init_params(:);
        p_scale = max(abs(p_init), [0.5; 50; 0.5; 10; 0.5; 0.5]);
    else
        app.LogTextArea.Value = ["Generating Synthetic Holling's Data..."; app.LogTextArea.Value]; drawnow;
        % For synthetic data, true_params generate the data and init_params initialize the inverse search.
        noise_pct = trainParams.Noise;
        p_true_ref = true_params(:);
        p_init = init_params(:);
        
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
        
        % Use a stable positive scale; the actual initial guess is set below through invsoftplus.
        p_scale = max(abs(p_true_ref), [0.5; 10; 0.5; 2; 0.5; 0.5]);
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
    rng(42); % Reproducible network initialization for classroom demonstrations
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
    
    % The trainable normalized vector is initialized so that
    % softplus(p_est_norm).*p_scale equals the user-selected initial guess.
    p_init = max(p_init(:), 1e-6);
    init_ratio = p_init ./ p_scale;
    p_est_norm = dlarray(invsoftplus(init_ratio));
    
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
    if use_real_data
        app.LogTextArea.Value = [
            "Starting 6-Parameter Optimization...";
            sprintf("Initial guesses [alpha K beta c gamma delta] = [%.4g %.4g %.4g %.4g %.4g %.4g]", p_init(1), p_init(2), p_init(3), p_init(4), p_init(5), p_init(6));
            "Real-data mode: estimates are fitted calibration values, not recovered true parameters.";
            "Log columns: L_total, L_data, L_phys, w_data, w_phys.";
            app.LogTextArea.Value
        ]; 
    else
        app.LogTextArea.Value = [
            "Starting 6-Parameter Optimization...";
            sprintf("True params [alpha K beta c gamma delta] = [%.4g %.4g %.4g %.4g %.4g %.4g]", p_true_ref(1), p_true_ref(2), p_true_ref(3), p_true_ref(4), p_true_ref(5), p_true_ref(6));
            sprintf("Initial guesses [alpha K beta c gamma delta] = [%.4g %.4g %.4g %.4g %.4g %.4g]", p_init(1), p_init(2), p_init(3), p_init(4), p_init(5), p_init(6));
            "Log columns: L_total, L_data, L_phys, w_data, w_phys.";
            "Diagnostic note: inspect stagnant parameter traces and persistent physics residuals; Module 3 can fail from local minima, scaling, or identifiability issues.";
            app.LogTextArea.Value
        ];
    end
    drawnow;
    
    phase2_end = warmup_epochs + floor((max_epochs - warmup_epochs) * 0.7);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        if use_real_data
            % Real data are noisy and model-misspecified, so physics is weighted less aggressively.
            if epoch <= warmup_epochs
                lam = 0;
                lr_net = 1e-3;
                lr_p = 0;
                phase = "Data Mapping";
                dw = 1;
            elseif epoch <= phase2_end
                lam = 2.0;
                lr_net = 2e-5;
                lr_p = 2e-3;
                phase = "Physics Inverse";
                dw = 1;
            else
                lam = 1.0;
                lr_net = 5e-5;
                lr_p = 2e-4;
                phase = "Fine Tuning";
                dw = 1;
            end
        else
            % Synthetic data are generated from the model, so stronger physics weighting is appropriate.
            if epoch <= warmup_epochs
                lam = 0;
                lr_net = 1e-3;
                lr_p = 0;
                phase = "Data Mapping";
                dw = 1;
            elseif epoch <= phase2_end
                lam = 10.0;
                lr_net = 1e-5;
                lr_p = 5e-3;
                phase = "Physics Inverse";
                dw = 1;
            else
                lam = 5.0;
                lr_net = 5e-5;
                lr_p = 5e-4;
                phase = "Fine Tuning";
                dw = 1;
            end
        end
        [loss, gNet, gP, lD, lP] = dlfeval(@lossHollings, dlnet, p_est_norm, p_scale, dlT, dlY, dlTf, dt_scale, Y_mu, Y_sig, lam, dw);
        if any(isnan(extractdata(loss))) || any(isinf(extractdata(loss)))
            app.LogTextArea.Value = ["ERROR: NaN/Inf detected in optimization. Training stopped."; app.LogTextArea.Value];
            break;
        end
        if lr_net > 0
            [dlnet, avgNet, sqNet] = adamupdate(dlnet, gNet, avgNet, sqNet, epoch, lr_net);
        end
        if lr_p > 0
            [p_est_norm, avgP, sqP] = adamupdate(p_est_norm, gP, avgP, sqP, epoch, lr_p); 
        end
        
        if mod(epoch, 100) == 0
            if mod(epoch, 500) == 0 || epoch < 200
                app.LogTextArea.Value = [sprintf("Ep %d | Phase: %s | L_total=%.4e | L_data=%.4e | L_phys=%.4e | w_data=%g | w_phys=%g", epoch, char(phase), extractdata(loss), extractdata(lD), extractdata(lP), dw, lam); app.LogTextArea.Value]; 
            end
            
            t_eval_norm = dlarray(linspace(-1, 1, 200), 'CB');
            t_eval_real = linspace(t_min, t_max, 200);
            
            Y_eval_norm = extractdata(forward(dlnet, t_eval_norm));
            Y_eval_real = Y_eval_norm .* Y_sig + Y_mu;
            
            clearpoints(hPrey); clearpoints(hPred);
            addpoints(hPrey, t_eval_real, Y_eval_real(1,:));
            addpoints(hPred, t_eval_real, Y_eval_real(2,:));
            
            % Re-scale parameters for plotting
            p_vals = softplus(extractdata(p_est_norm)) .* p_scale;
            for i=1:6
                addpoints(hParams(i), epoch, p_vals(i)); 
            end
            drawnow limitrate;
        end
    end
    
    % Post-Run Table Update
    p_final = softplus(extractdata(p_est_norm)) .* p_scale;
    if use_real_data
        app.UITable.ColumnName = {'Param', 'Initial Guess', 'Estimate', 'Note'};
    else
        app.UITable.ColumnName = {'Param', 'True Value', 'Initial Guess', 'Estimate', 'Err %'};
    end
    
    if use_real_data
        app.UITable.Data = {
            'Alpha', p_init(1), p_final(1), 'Fitted';
            'K (Capacity)', p_init(2), p_final(2), 'Fitted';
            'Beta', p_init(3), p_final(3), 'Fitted';
            'c (Half-Sat)', p_init(4), p_final(4), 'Fitted';
            'Gamma', p_init(5), p_final(5), 'Fitted';
            'Delta', p_init(6), p_final(6), 'Fitted';
        };
    
        if p_final(2) > 300 || p_final(4) > 100
            app.LogTextArea.Value = ["Diagnostic warning: K or c is very large. The model may be using carrying capacity or half-saturation as flexible fitting parameters rather than biologically meaningful estimates."; app.LogTextArea.Value];
        end
    else
        app.UITable.Data = {
            'Alpha', p_true_ref(1), p_init(1), p_final(1), abs(p_final(1)-p_true_ref(1))/p_true_ref(1)*100;
            'K (Capacity)', p_true_ref(2), p_init(2), p_final(2), abs(p_final(2)-p_true_ref(2))/p_true_ref(2)*100;
            'Beta', p_true_ref(3), p_init(3), p_final(3), abs(p_final(3)-p_true_ref(3))/p_true_ref(3)*100;
            'c (Half-Sat)', p_true_ref(4), p_init(4), p_final(4), abs(p_final(4)-p_true_ref(4))/p_true_ref(4)*100;
            'Gamma', p_true_ref(5), p_init(5), p_final(5), abs(p_final(5)-p_true_ref(5))/p_true_ref(5)*100;
            'Delta', p_true_ref(6), p_init(6), p_final(6), abs(p_final(6)-p_true_ref(6))/p_true_ref(6)*100;
        };
    end
    if ~use_real_data
        maxErr = max(abs((p_final - p_true_ref)./p_true_ref))*100;
        if maxErr > 50
            app.LogTextArea.Value = [sprintf("WARNING: One or more parameters have high error (max %.1f%%). Treat this as a diagnostic/failure-mode example and consider rerunning with adjusted hyperparameters or restart seed.", maxErr); app.LogTextArea.Value];
        end
    end
    app.LogTextArea.Value = ["Optimization Complete. Inspect L_data, L_phys, parameter traces, and biological plausibility."; app.LogTextArea.Value];
end

% Core Loss Function
function [loss, gNet, gP_norm, lD, lP] = lossHollings(net, p_norm, p_scale, Td, Yd, Tf, dt_s, Y_mu, Y_sig, lam, dw)
    
    % 1. Data Loss
    Yp = forward(net, Td); 
    lD = mean((Yp - Yd).^2, 'all'); 
    
    % 2. Physics Loss
    if lam > 0
        Yf_norm = forward(net, Tf);
        Yf_real = Yf_norm .* Y_sig + Y_mu; 
        
        x = softplus(Yf_real(1,:)) + 1e-3;
        y = softplus(Yf_real(2,:)) + 1e-3;
        
        p = softplus(p_norm) .* p_scale;
        p(2) = min(p(2),500);   % K
        p(4) = min(p(4),200);   % c
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

function y = softplus(x)
    y = max(x,0) + log(1 + exp(-abs(x)));
end

function x = invsoftplus(y)
    y = max(y, 1e-8);
    x = log(exp(y) - 1);
end
