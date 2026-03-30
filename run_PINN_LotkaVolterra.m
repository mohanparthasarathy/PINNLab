% Copyright: Mohan Parthasarathy 2026
function run_PINN_LotkaVolterra(app, trainParams, user_params)
    %% 1. Setup & Data Generation
    noise_pct = trainParams.Noise; 
    max_epochs = trainParams.MaxEpochs; 
    warmup_epochs = trainParams.WarmupEpochs;
    p_true = user_params; 
    
    app.LogTextArea.Value = ["Generating LV Data..."; app.LogTextArea.Value]; drawnow;
    
    % Generate True Data
    [t_sol, U_sol] = ode45(@(t,u) lv_rhs(t,u,p_true), linspace(0,10,100), [1;1]);
    
    rng(42);
    x_n = U_sol(:,1) + (noise_pct/100)*randn(size(U_sol(:,1)));
    y_n = U_sol(:,2) + (noise_pct/100)*randn(size(U_sol(:,2)));
    
    % Input Normalization (Time only, keeping Output raw for better gradients)
    t_min = 0; t_max = 10; dt_scale = (t_max-t_min)/2; 
    t_norm = 2*(t_sol-t_min)/(t_max-t_min)-1;
    
    dlT = dlarray(t_norm', 'CB'); 
    dlU = dlarray([x_n, y_n]', 'CB');
    dlT_f = dlarray(linspace(-1,1,2000), 'CB');
    
    %% 2. Network Architecture (3x64)
    layers = [
        featureInputLayer(1); 
        fullyConnectedLayer(64); tanhLayer; 
        fullyConnectedLayer(64); tanhLayer; 
        fullyConnectedLayer(64); tanhLayer; 
        fullyConnectedLayer(2)
    ];
    dlnet = dlnetwork(layerGraph(layers));
    
    % Parameter Struct
    P = struct('a', dlarray(1.0), 'b', dlarray(1.0), 'g', dlarray(1.0), 'd', dlarray(1.0));
    
    %% 3. Plot Setup
    cla(app.TopAxes); hold(app.TopAxes, 'on');
    plot(app.TopAxes, t_sol, x_n, 'b.', 'MarkerSize', 8, 'DisplayName', 'Prey Data');
    plot(app.TopAxes, t_sol, y_n, 'r.', 'MarkerSize', 8, 'DisplayName', 'Predator Data');
    hX = animatedline(app.TopAxes, 'Color','b','LineWidth',2, 'DisplayName', 'Prey Est');
    hY = animatedline(app.TopAxes, 'Color','r','LineWidth',2, 'DisplayName', 'Predator Est');
    legend(app.TopAxes, 'Location', 'northeast'); 
    
    cla(app.BottomAxes); hold(app.BottomAxes, 'on');
    hA = animatedline(app.BottomAxes,'Color','m', 'LineWidth', 1.5, 'DisplayName', '\alpha'); 
    hB = animatedline(app.BottomAxes,'Color','c', 'LineWidth', 1.5, 'DisplayName', '\beta');
    hG = animatedline(app.BottomAxes,'Color','g', 'LineWidth', 1.5, 'DisplayName', '\gamma'); 
    hD = animatedline(app.BottomAxes,'Color','k', 'LineWidth', 1.5, 'DisplayName', '\delta'); 
    
    yline(app.BottomAxes, p_true(1), 'm--', 'HandleVisibility','off'); 
    yline(app.BottomAxes, p_true(2), 'c--', 'HandleVisibility','off');
    yline(app.BottomAxes, p_true(3), 'g--', 'HandleVisibility','off');
    yline(app.BottomAxes, p_true(4), 'k--', 'HandleVisibility','off');
    legend(app.BottomAxes, 'Location', 'eastoutside'); 
    
    %% 4. Training Loop
    avgNet=[]; sqAvgNet=[]; 
    avgP = struct('a',[],'b',[],'g',[],'d',[]); 
    sqAvgP = avgP;
    
    app.LogTextArea.Value = ["Starting Training Loop..."; app.LogTextArea.Value]; drawnow;
    rem_eps = max_epochs - warmup_epochs; 
    phase2_end = warmup_epochs + floor(rem_eps * 0.7);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        % Phase Logic
        if epoch <= warmup_epochs
            lam = 0; lr = 1e-3; upd_n = true; upd_p = false; dw = 1; phase = "Fit Data";
        elseif epoch <= phase2_end
            lam = 1; lr = 0.02; upd_n = false; upd_p = true; dw = 1; phase = "Find Params";
        else
            lam = 1; lr = 1e-4; upd_n = true; upd_p = true; dw = 20; phase = "Fine Tune"; 
        end
        
        % Gradients
        [loss, gN, gP] = dlfeval(@lossLV, dlnet, P, dlT, dlU, dlT_f, dt_scale, lam, dw);
        
        % Updates
        if upd_n
            [dlnet, avgNet, sqAvgNet] = adamupdate(dlnet, gN, avgNet, sqAvgNet, epoch, lr); 
        end
        if upd_p
            fns = fieldnames(P);
            for i=1:4
                [P.(fns{i}), avgP.(fns{i}), sqAvgP.(fns{i})] = adamupdate(P.(fns{i}), gP.(fns{i}), avgP.(fns{i}), sqAvgP.(fns{i}), epoch, lr); 
            end
        end
        
        % Visualization
        if mod(epoch, 100) == 0
            av = extractdata(P.a); gv = extractdata(P.g);
            
            if mod(epoch, 500) == 0 || epoch < 200
                app.LogTextArea.Value = [sprintf("Ep %d (%s) | L %.4f", epoch, phase, extractdata(loss)); app.LogTextArea.Value]; 
            end
            
            U_eval = extractdata(forward(dlnet, dlarray(linspace(-1,1,100),'CB')));
            clearpoints(hX); addpoints(hX, linspace(0,10,100), U_eval(1,:));
            clearpoints(hY); addpoints(hY, linspace(0,10,100), U_eval(2,:));
            
            addpoints(hA, epoch, av); 
            addpoints(hB, epoch, extractdata(P.b));
            addpoints(hG, epoch, gv); 
            addpoints(hD, epoch, extractdata(P.d));
            drawnow limitrate;
        end
    end
    
    % Final Table Update
    vals = [extractdata(P.a), extractdata(P.b), extractdata(P.g), extractdata(P.d)];
    app.UITable.Data = {
        'Alpha (Growth)', p_true(1), vals(1), abs(vals(1)-p_true(1))/p_true(1)*100;
        'Beta (Predation)', p_true(2), vals(2), abs(vals(2)-p_true(2))/p_true(2)*100;
        'Gamma (Decay)', p_true(3), vals(3), abs(vals(3)-p_true(3))/p_true(3)*100;
        'Delta (Reprod.)', p_true(4), vals(4), abs(vals(4)-p_true(4))/p_true(4)*100
    };
    app.LogTextArea.Value = ["Lotka-Volterra Execution Done."; app.LogTextArea.Value];
end

% Numerical ODE Generator
function dudt = lv_rhs(~, u, p)
    dudt = [p(1)*u(1) - p(2)*u(1)*u(2); -p(3)*u(2) + p(4)*u(1)*u(2)]; 
end

% Core Loss Function
function [l, gN, gP] = lossLV(net, p, Td, Ud, Tf, dt, lam, dw)
    % 1. Data Loss
    Up = forward(net, Td); 
    lD = mean((Up - Ud).^2, 'all'); % Safe explicit MSE
    
    % 2. Physics Loss
    if lam > 0
        Uf = forward(net, Tf); 
        X = Uf(1,:); 
        Y = Uf(2,:);
        
        dX = dlgradient(sum(X,'all'), Tf) / dt; 
        dY = dlgradient(sum(Y,'all'), Tf) / dt;
        
        res_X = dX - (p.a.*X - p.b.*X.*Y);
        res_Y = dY - (-p.g.*Y + p.d.*X.*Y);
        
        lP = mean(res_X.^2, 'all') + mean(res_Y.^2, 'all');
    else 
        lP = dlarray(0); 
    end
    
    % 3. Composite Loss and Gradients
    l = dw*lD + lam*lP; 
    gN = dlgradient(l, net.Learnables); 
    
    fns = fieldnames(p); 
    for i=1:4
        gP.(fns{i}) = dlgradient(l, p.(fns{i})); 
    end
end
