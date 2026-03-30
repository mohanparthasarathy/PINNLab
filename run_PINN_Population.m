% Copyright: Mohan Parthasarathy 2026
function run_PINN_Population(app, trainParams, k_true)
    %% 1. Setup
    noise_pct = trainParams.Noise; 
    max_epochs = trainParams.MaxEpochs; 
    warmup_epochs = trainParams.WarmupEpochs;
    
    y0 = 1; t = linspace(0,5,50)'; y_true = y0 * exp(k_true * t);
    
    app.LogTextArea.Value = ["Generating Synthetic Population Data..."; app.LogTextArea.Value]; drawnow;
    
    rng(42); 
    y_noisy = y_true + (noise_pct/100)*std(y_true)*randn(size(y_true));
    
    t_min=0; t_max=5; dt_scale=(t_max-t_min)/2; t_norm = 2*(t - t_min)/(t_max - t_min) - 1;
    dlT_data = dlarray(t_norm', 'CB'); dlY_data = dlarray(y_noisy', 'CB'); dlT_f = dlarray(linspace(-1,1,1000), 'CB');
    
    %% 2. Network
    dlnet = dlnetwork(layerGraph([featureInputLayer(1); fullyConnectedLayer(50); tanhLayer; fullyConnectedLayer(50); tanhLayer; fullyConnectedLayer(1)]));
    k = dlarray(0.5); % Bad initial guess
    
    %% 3. Plot Setup (FIXED LEGENDS)
    cla(app.TopAxes); hold(app.TopAxes, 'on');
    plot(app.TopAxes, t, y_noisy, 'k.', 'MarkerSize', 10, 'DisplayName', 'Noisy Data');
    hPred = animatedline(app.TopAxes, 'Color', 'b', 'LineWidth', 2, 'DisplayName', 'PINN Est');
    legend(app.TopAxes, 'Location', 'best');
    
    cla(app.BottomAxes); hold(app.BottomAxes, 'on');
    hK = animatedline(app.BottomAxes, 'Color', 'r', 'LineWidth', 1.5, 'DisplayName', 'Growth k');
    yline(app.BottomAxes, k_true, 'k--', 'HandleVisibility','off');
    legend(app.BottomAxes, 'Location', 'best');
    
    %% 4. Training
    avgY=[]; sqAvgY=[]; avgK=[]; sqAvgK=[];
    app.LogTextArea.Value = ["Starting Training Loop..."; app.LogTextArea.Value]; drawnow;
    rem_eps = max_epochs - warmup_epochs; phase2_end = warmup_epochs + floor(rem_eps * 0.7);
    
    for epoch = 1:max_epochs
        if app.StopFlag, break; end
        
        if epoch <= warmup_epochs
            lam=0; lr=1e-3; phase="Fit Data"; upd_net=true; upd_k=false; dw=1;
        elseif epoch <= phase2_end
            lam=1; lr=0.01; phase="Find k"; upd_net=false; upd_k=true; dw=1;
        else
            lam=1; lr=1e-4; phase="Fine Tune"; upd_net=true; upd_k=true; dw=20; 
        end
        
        [loss, gY, gK] = dlfeval(@lossPop, dlnet, k, dlT_data, dlY_data, dlT_f, dt_scale, lam, dw);
        
        if upd_net
            [dlnet, avgY, sqAvgY] = adamupdate(dlnet, gY, avgY, sqAvgY, epoch, lr); 
        end
        if upd_k
            [k, avgK, sqAvgK] = adamupdate(k, gK, avgK, sqAvgK, epoch, lr); 
        end
        
        if mod(epoch, 100) == 0
            kval = extractdata(k);
            if mod(epoch, 500) == 0 || epoch < 200
                app.LogTextArea.Value = [sprintf("Ep %d (%s) | L %.4f", epoch, phase, extractdata(loss)); app.LogTextArea.Value]; 
            end
            t_eval = dlarray(linspace(-1,1,100), 'CB'); y_eval = extractdata(forward(dlnet, t_eval));
            clearpoints(hPred); addpoints(hPred, linspace(0,5,100), y_eval);
            addpoints(hK, epoch, kval);
            drawnow limitrate;
        end
    end
    
    app.UITable.Data = {'Growth Rate (k)', k_true, extractdata(k), abs(extractdata(k)-k_true)/k_true*100};
    app.LogTextArea.Value = ["Done."; app.LogTextArea.Value];
end

function [loss, gY, gK] = lossPop(net, k, Td, Yd, Tf, dt_s, lam, dw)
    Yp = forward(net, Td); 
    lD = mse(Yp, Yd);
    
    if lam>0
        Yf = forward(net, Tf); 
        dY = dlgradient(sum(Yf,'all'), Tf) / dt_s;
        lP = mse(dY - k.*Yf, zeros(size(Yf),'like',Yf));
    else 
        lP=dlarray(0); 
    end
    
    loss = dw*lD + lam*lP; 
    gY = dlgradient(loss, net.Learnables); 
    gK = dlgradient(loss, k);
end
