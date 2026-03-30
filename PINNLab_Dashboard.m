% Copyright: Mohan Parthasarathy 2026
% PINNLab: An Interactive Educational Dashboard for Data-Driven Modeling
% Organized via the 5E Instructional Framework (Ecological Dynamics)

classdef PINNLab_Dashboard < matlab.apps.AppBase
    
    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        GridLayout           matlab.ui.container.GridLayout
        
        % Left Panel (Configuration)
        ConfigurationPanel   matlab.ui.container.Panel
        ModelDropDown        matlab.ui.control.DropDown
        NoiseEditField       matlab.ui.control.NumericEditField
        EpochsEditField      matlab.ui.control.NumericEditField
        WarmupEditField      matlab.ui.control.NumericEditField
        ParamHeaderLabel     matlab.ui.control.Label
        STARTButton          matlab.ui.control.Button
        STOPButton           matlab.ui.control.Button
        
        % Dynamic Parameter Area
        ParamGrid            matlab.ui.container.GridLayout
        ParamLabels          matlab.ui.control.Label = matlab.ui.control.Label.empty;
        ParamFields          = {}; 
        
        % Center Panel (Visualizations)
        GridLayout2          matlab.ui.container.GridLayout
        TopAxes              matlab.ui.control.UIAxes
        BottomAxes           matlab.ui.control.UIAxes
        
        % Right Panel (Information & Logs)
        GridLayout3          matlab.ui.container.GridLayout
        EquationAxes         matlab.ui.control.UIAxes
        EquationText         matlab.graphics.primitive.Text
        LogTextArea          matlab.ui.control.TextArea
        UITable              matlab.ui.control.Table
    end
    
    properties (Access = public)
        StopFlag logical = false; 
    end
    
    methods (Access = public)
        % --- CONSTRUCTOR ---
        function app = PINNLab_Dashboard
            try
                createComponents(app);
                registerApp(app, app.UIFigure);
                updateEquationDisplay(app); 
                updateParameterFields(app); 
                
                if nargout == 0
                    clear app;
                end
            catch ME
                fprintf(2, 'CRITICAL ERROR: %s\n', ME.message);
                delete(app); 
            end
        end
        
        % Destructor
        function delete(app)
            delete(app.UIFigure);
        end
    end
    
    methods (Access = private)
        
        % Callback: DropDown Changed
        function ModelDropDownValueChanged(app, ~)
            updateEquationDisplay(app);
            updateParameterFields(app);
        end
        
        % Helper: Log Message
        function logMsg(app, msg)
            timestamp = datestr(now, 'HH:MM:SS');
            txt = sprintf("[%s] %s", timestamp, msg);
            app.LogTextArea.Value = [txt; app.LogTextArea.Value];
            fprintf('%s\n', txt); 
            drawnow;
        end
        
        % Helper: Aggressively Clear Axes for Redraws
        function clearAxes(~, ax)
            legend(ax, 'off');
            legend(ax, 'reset'); 
            delete(findall(ax, 'Type', 'ConstantLine')); 
            delete(findall(ax, 'Type', 'animatedline')); 
            delete(findall(ax, 'Type', 'line'));         
            cla(ax);             
            delete(ax.Children); 
            title(ax, '');       
            xlabel(ax, ''); 
            ylabel(ax, '');
            grid(ax, 'off'); 
            box(ax, 'on');
            hold(ax, 'on');      
        end
        
        % Helper: Update Equation Display based on 5E Module
        function updateEquationDisplay(app)
            model = strtrim(app.ModelDropDown.Value);
            fSize = 16; 
            switch model
                case 'Demo: Exponential Growth'
                    latexStr = '$$ \frac{dy}{dt} = ky $$';
                case 'Mod 0: Engage (PhET Simulation)'
                    latexStr = '$$ \text{Qualitative Ecological Sandbox} $$';
                    fSize = 14;
                case 'Mod 1: Explore (Forced ODE)'
                    latexStr = '$$ \frac{dy}{dt} - ky = Q(t) $$';
                case 'Mod 2: Explain (Lotka-Volterra)'
                    latexStr = ['$$ \frac{dx}{dt} = \alpha x - \beta xy $$' newline ...
                                '$$ \frac{dy}{dt} = -\gamma y + \delta xy $$'];
                case 'Mod 3: Elaborate (Holling''s Type II)'
                    latexStr = ['$$ \frac{dx}{dt} = \alpha x(1-\frac{x}{K}) - \frac{\beta xy}{c+x} $$' newline ...
                                '$$ \frac{dy}{dt} = -\gamma y + \frac{\delta \beta xy}{c+x} $$'];
                    fSize = 14;
                case 'Mod 4: Evaluate (Hare/Lynx Data)'
                    latexStr = ['$$ \frac{dx}{dt} = \alpha x(1-\frac{x}{K}) - \frac{\beta xy}{c+x} $$' newline ...
                                '$$ \frac{dy}{dt} = -\gamma y + \frac{\delta \beta xy}{c+x} $$'];
                    fSize = 14;
            end
            app.EquationText.String = latexStr;
            app.EquationText.FontSize = fSize;
        end
        
        % Helper: Update Parameter Input Fields
        function updateParameterFields(app)
            % Clear existing fields
            delete(app.ParamLabels); 
            if ~isempty(app.ParamFields)
                for k=1:numel(app.ParamFields)
                    delete(app.ParamFields{k});
                end
            end
            app.ParamLabels = matlab.ui.control.Label.empty;
            app.ParamFields = {}; 
            
            model = strtrim(app.ModelDropDown.Value);
            lblFont = 'Arial'; lblSize = 14; 
            
            % UI Adaptations based on Module
            if strcmp(model, 'Mod 0: Engage (PhET Simulation)')
                app.ParamHeaderLabel.Text = 'Simulation Settings:';
                app.STARTButton.Text = 'OPEN PHET SIMULATION';
                app.STARTButton.BackgroundColor = [0.8 0.4 0.1]; % Orange
                app.NoiseEditField.Enable = 'off';
                app.EpochsEditField.Enable = 'off';
                app.WarmupEditField.Enable = 'off';
                return; % No mathematical parameters needed
            elseif strcmp(model, 'Mod 4: Evaluate (Hare/Lynx Data)')
                app.ParamHeaderLabel.Text = 'Initial Parameter Guesses:';
                app.STARTButton.Text = 'START TRAINING';
                app.STARTButton.BackgroundColor = [0.1 0.6 0.3];
                app.NoiseEditField.Enable = 'off'; % Real data contains inherent noise
                app.EpochsEditField.Enable = 'on';
                app.WarmupEditField.Enable = 'on';
            else
                app.ParamHeaderLabel.Text = 'True Parameters (Synthetic Data):';
                app.STARTButton.Text = 'START TRAINING';
                app.STARTButton.BackgroundColor = [0.1 0.6 0.3];
                app.NoiseEditField.Enable = 'on';
                app.EpochsEditField.Enable = 'on';
                app.WarmupEditField.Enable = 'on';
            end
            
            % Assign Parameters
            pNames = {}; pDefaults = [];
            switch model
                case 'Demo: Exponential Growth'
                    pNames = {'k (Growth)'}; pDefaults = [0.7];
                case 'Mod 1: Explore (Forced ODE)'
                    pNames = {'k (Growth)', 'Q(t) Forcing'}; pDefaults = [0.5, 0]; % Handled uniquely below
                case 'Mod 2: Explain (Lotka-Volterra)'
                    pNames = {'Alpha (Prey Growth)', 'Beta (Predation)', 'Gamma (Pred Decay)', 'Delta (Reproduction)'};
                    pDefaults = [1.5, 1.0, 3.0, 1.0];
                case 'Mod 3: Elaborate (Holling''s Type II)'
                    pNames = {'Alpha', 'K (Capacity)', 'Beta', 'c (Half-Sat)', 'Gamma', 'Delta'};
                    pDefaults = [2.0, 50.0, 1.2, 10.0, 1.0, 0.8];
                case 'Mod 4: Evaluate (Hare/Lynx Data)'
                    pNames = {'Alpha Guess', 'K Guess', 'Beta Guess', 'c Guess', 'Gamma Guess', 'Delta Guess'};
                    pDefaults = [0.5, 100.0, 0.5, 20.0, 0.5, 0.5];
            end
            
            nParams = length(pNames);
            app.ParamGrid.RowHeight = repmat({'fit'}, 1, max(1, nParams));
            
            for i = 1:nParams
                lbl = uilabel(app.ParamGrid);
                lbl.Text = [pNames{i} ':'];
                lbl.HorizontalAlignment = 'right';
                lbl.Layout.Row = i; lbl.Layout.Column = 1;
                lbl.FontName = lblFont; lbl.FontSize = lblSize; lbl.FontColor = [0.2 0.2 0.2];
                app.ParamLabels(i) = lbl;
                
                % Text field specifically for Q(t) in Mod 1
                if strcmp(model, 'Mod 1: Explore (Forced ODE)') && i == 2
                    fld = uieditfield(app.ParamGrid, 'text');
                    fld.Value = "sin(2*t)";
                else
                    fld = uieditfield(app.ParamGrid, 'numeric');
                    fld.Value = pDefaults(i);
                end
                fld.Layout.Row = i; fld.Layout.Column = 2;
                fld.FontName = lblFont; fld.FontSize = lblSize;
                app.ParamFields{i} = fld; 
            end
        end
        
        % Callback: START Button
        function STARTButtonPushed(app, ~)
            model = strtrim(app.ModelDropDown.Value);
            
            % Special Case: Engage Phase launches Web Browser
            if strcmp(model, 'Mod 0: Engage (PhET Simulation)')
                logMsg(app, "Launching PhET Natural Selection Sandbox...");
                web('https://phet.colorado.edu/sims/html/natural-selection/latest/natural-selection_en.html', '-browser');
                return;
            end
            
            % UI Locking for Training
            app.STARTButton.Enable = 'off';
            app.STOPButton.Enable = 'on';
            app.ModelDropDown.Enable = 'off'; 
            app.NoiseEditField.Enable = 'off';
            app.EpochsEditField.Enable = 'off';
            app.WarmupEditField.Enable = 'off';
            for k=1:numel(app.ParamFields), app.ParamFields{k}.Enable = 'off'; end
            
            app.StopFlag = false;
            logMsg(app, "Initializing Environment...");
            
            clearAxes(app, app.TopAxes); 
            clearAxes(app, app.BottomAxes);
            
            trainParams.Noise = app.NoiseEditField.Value;
            trainParams.MaxEpochs = app.EpochsEditField.Value;
            trainParams.WarmupEpochs = app.WarmupEditField.Value;
            drawnow; 
            
            try
                % Collect UI Parameters
                rawValues = cell(1, numel(app.ParamFields));
                for k=1:numel(app.ParamFields)
                    rawValues{k} = app.ParamFields{k}.Value;
                end
                
                logMsg(app, ["Executing: " + model]);
                
                % Route to appropriate Engine Script
                switch model
                    case 'Demo: Exponential Growth'
                        run_PINN_Population(app, trainParams, rawValues{1});
                    case 'Mod 1: Explore (Forced ODE)'
                        run_PINN_ForcedODE(app, trainParams, rawValues);
                    case 'Mod 2: Explain (Lotka-Volterra)'
                        run_PINN_LotkaVolterra(app, trainParams, cell2mat(rawValues));
                    case 'Mod 3: Elaborate (Holling''s Type II)'
                        % Pass false for synthetic data
                        run_PINN_HollingsTypeII(app, trainParams, cell2mat(rawValues), false); 
                    case 'Mod 4: Evaluate (Hare/Lynx Data)'
                        % Pass true to trigger CSV ingestion of real data
                        run_PINN_HollingsTypeII(app, trainParams, cell2mat(rawValues), true);
                end
            catch ME
                logMsg(app, "CRITICAL ERROR: " + string(ME.message));
                fprintf('Error Stack:\n'); disp(ME.stack);
            end
            
            % Unlock UI
            if isvalid(app.UIFigure)
                app.STARTButton.Enable = 'on';
                app.STOPButton.Enable = 'off';
                app.ModelDropDown.Enable = 'on';
                app.EpochsEditField.Enable = 'on';
                app.WarmupEditField.Enable = 'on';
                updateParameterFields(app); % Restores correct noise/param toggles
                logMsg(app, "Modeling Cycle Complete.");
            end
        end
        
        % Callback: STOP Button
        function STOPButtonPushed(app, ~)
            app.StopFlag = true;
            logMsg(app, "Halt requested by user. Terminating loop...");
        end
    end
    
    % Component Initialization
    methods (Access = private)
        function createComponents(app)
            % Main Figure
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 1100 750]; 
            app.UIFigure.Name = 'PINNLab: Ecological Dynamics Dashboard';
            app.UIFigure.Color = [0.96 0.96 0.98]; 
            
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {'1x', '3x', '1.5x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 15; 
            app.GridLayout.Padding = [15 15 15 15];
            
            % --- LEFT PANEL ---
            app.ConfigurationPanel = uipanel(app.GridLayout);
            app.ConfigurationPanel.Title = '5E Curriculum Configuration';
            app.ConfigurationPanel.Layout.Column = 1;
            app.ConfigurationPanel.BackgroundColor = [0.99 0.99 1.0]; 
            app.ConfigurationPanel.FontName = 'Arial'; 
            app.ConfigurationPanel.FontSize = 16; 
            app.ConfigurationPanel.FontWeight = 'bold';
            app.ConfigurationPanel.ForegroundColor = [0 0.45 0.74]; 
            
            innerGrid = uigridlayout(app.ConfigurationPanel);
            innerGrid.ColumnWidth = {'1x'};
            innerGrid.RowHeight = {'fit','fit', 'fit', 'fit','1x','2x','fit','fit'}; 
            innerGrid.RowSpacing = 12; 
            innerGrid.Padding = [10 10 10 10];
            
            stdFont = 'Arial'; stdSize = 14;
            
            lbl1 = uilabel(innerGrid, 'Text', 'Select Phase:');
            lbl1.Layout.Row = 1; lbl1.FontName = stdFont; lbl1.FontSize = stdSize;
            
            app.ModelDropDown = uidropdown(innerGrid);
            app.ModelDropDown.Items = {
                'Demo: Exponential Growth', ...
                'Mod 0: Engage (PhET Simulation)', ...
                'Mod 1: Explore (Forced ODE)', ...
                'Mod 2: Explain (Lotka-Volterra)', ...
                'Mod 3: Elaborate (Holling''s Type II)', ...
                'Mod 4: Evaluate (Hare/Lynx Data)'};
            app.ModelDropDown.Value = 'Demo: Exponential Growth';
            app.ModelDropDown.Layout.Row = 2;
            app.ModelDropDown.FontName = stdFont; app.ModelDropDown.FontSize = stdSize;
            app.ModelDropDown.ValueChangedFcn = @(src, event) app.ModelDropDownValueChanged(event);
            
            % Settings Sub-grid
            settingsGrid = uigridlayout(innerGrid);
            settingsGrid.Layout.Row = 3; 
            settingsGrid.ColumnWidth = {'2x', '1x'};
            settingsGrid.RowHeight = {'fit', 'fit', 'fit'};
            
            lbl2 = uilabel(settingsGrid, 'Text', 'Data Noise (%):');
            lbl2.Layout.Row = 1; lbl2.Layout.Column = 1; lbl2.FontName = stdFont;
            app.NoiseEditField = uieditfield(settingsGrid, 'numeric');
            app.NoiseEditField.Limits = [0 100]; app.NoiseEditField.Value = 5;
            app.NoiseEditField.Layout.Row = 1; app.NoiseEditField.Layout.Column = 2;
            
            lblE = uilabel(settingsGrid, 'Text', 'Max Epochs:');
            lblE.Layout.Row = 2; lblE.Layout.Column = 1; lblE.FontName = stdFont;
            app.EpochsEditField = uieditfield(settingsGrid, 'numeric');
            app.EpochsEditField.Value = 6000;
            app.EpochsEditField.Layout.Row = 2; app.EpochsEditField.Layout.Column = 2;
            
            lblW = uilabel(settingsGrid, 'Text', 'Warmup Epochs:');
            lblW.Layout.Row = 3; lblW.Layout.Column = 1; lblW.FontName = stdFont;
            app.WarmupEditField = uieditfield(settingsGrid, 'numeric');
            app.WarmupEditField.Value = 1000;
            app.WarmupEditField.Layout.Row = 3; app.WarmupEditField.Layout.Column = 2;
            
            app.ParamHeaderLabel = uilabel(innerGrid, 'Text', 'True Parameters:');
            app.ParamHeaderLabel.FontName = stdFont; app.ParamHeaderLabel.FontSize = 15; 
            app.ParamHeaderLabel.FontWeight = 'bold'; app.ParamHeaderLabel.FontColor = [0 0.45 0.74]; 
            app.ParamHeaderLabel.Layout.Row = 4;
            
            app.ParamGrid = uigridlayout(innerGrid);
            app.ParamGrid.Layout.Row = 5;
            app.ParamGrid.ColumnWidth = {'1x', '1x'}; 
            app.ParamGrid.Scrollable = 'on'; 
            app.ParamGrid.RowSpacing = 8;
            
            app.STARTButton = uibutton(innerGrid, 'push');
            app.STARTButton.ButtonPushedFcn = @(src, event) app.STARTButtonPushed(event);
            app.STARTButton.BackgroundColor = [0.1 0.6 0.3]; 
            app.STARTButton.FontColor = [1 1 1];
            app.STARTButton.FontName = stdFont; app.STARTButton.FontSize = 16; 
            app.STARTButton.FontWeight = 'bold';
            app.STARTButton.Text = 'START TRAINING';
            app.STARTButton.Layout.Row = 7;
            
            app.STOPButton = uibutton(innerGrid, 'push');
            app.STOPButton.ButtonPushedFcn = @(src, event) app.STOPButtonPushed(event);
            app.STOPButton.BackgroundColor = [0.7 0.1 0.1]; 
            app.STOPButton.FontColor = [1 1 1];
            app.STOPButton.FontName = stdFont; app.STOPButton.FontSize = 16;
            app.STOPButton.FontWeight = 'bold';
            app.STOPButton.Enable = 'off';
            app.STOPButton.Text = 'STOP LOOP';
            app.STOPButton.Layout.Row = 8;
            
            % --- CENTER PANEL ---
            app.GridLayout2 = uigridlayout(app.GridLayout);
            app.GridLayout2.ColumnWidth = {'1x'};
            app.GridLayout2.RowHeight = {'1x', '1x'};
            app.GridLayout2.RowSpacing = 20; 
            app.GridLayout2.Layout.Column = 2;
            
            app.TopAxes = uiaxes(app.GridLayout2);
            title(app.TopAxes, 'State Solution (Populations)'); 
            app.TopAxes.Layout.Row = 1;
            app.TopAxes.BackgroundColor = 'none'; app.TopAxes.Box = 'off';
            app.TopAxes.XGrid = 'off'; app.TopAxes.YGrid = 'off'; 
            app.TopAxes.FontName = stdFont; app.TopAxes.FontSize = 13;
            app.TopAxes.Title.Color = [0 0.45 0.74]; app.TopAxes.Title.FontWeight = 'bold';
            
            app.BottomAxes = uiaxes(app.GridLayout2);
            title(app.BottomAxes, 'Real-Time Parameter Estimation'); 
            app.BottomAxes.Layout.Row = 2;
            app.BottomAxes.BackgroundColor = 'none'; app.BottomAxes.Box = 'off';
            app.BottomAxes.XGrid = 'off'; app.BottomAxes.YGrid = 'off'; 
            app.BottomAxes.FontName = stdFont; app.BottomAxes.FontSize = 13;
            app.BottomAxes.Title.Color = [0 0.45 0.74]; app.BottomAxes.Title.FontWeight = 'bold';
            
            % --- RIGHT PANEL ---
            app.GridLayout3 = uigridlayout(app.GridLayout);
            app.GridLayout3.ColumnWidth = {'1x'};
            app.GridLayout3.RowHeight = {'1x', 'fit', '2x', '2x'}; 
            app.GridLayout3.Layout.Column = 3;
            app.GridLayout3.RowSpacing = 10;
            
            app.EquationAxes = uiaxes(app.GridLayout3);
            app.EquationAxes.Layout.Row = 1;
            app.EquationAxes.Color = 'none'; 
            app.EquationAxes.XAxis.Visible = 'off'; app.EquationAxes.YAxis.Visible = 'off';
            disableDefaultInteractivity(app.EquationAxes);
            app.EquationText = text(app.EquationAxes, 0.5, 0.5, '$$ Loading... $$', ...
                'Interpreter', 'latex', 'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', 'FontSize', 16); 
                
            lbl4 = uilabel(app.GridLayout3);
            lbl4.Text = 'Training Log & Diagnostics:'; 
            lbl4.Layout.Row = 2;
            lbl4.FontName = stdFont; lbl4.FontSize = 14;
            lbl4.FontWeight = 'bold'; lbl4.FontColor = [0 0.45 0.74];
            
            app.LogTextArea = uitextarea(app.GridLayout3);
            app.LogTextArea.Layout.Row = 3; app.LogTextArea.Editable = 'off';
            app.LogTextArea.FontName = 'Consolas'; 
            app.LogTextArea.FontSize = 12;
            app.LogTextArea.BackgroundColor = [0.99 0.99 1.0];
            
            app.UITable = uitable(app.GridLayout3);
            app.UITable.ColumnName = {'Param', 'Target', 'Est', 'Err %'};
            app.UITable.RowName = {}; app.UITable.Layout.Row = 4;
            app.UITable.FontName = stdFont; app.UITable.FontSize = 13;
            app.UITable.BackgroundColor = [1 1 1; 0.96 0.96 0.98]; 
            
            app.UIFigure.Visible = 'on';
        end
    end
end
