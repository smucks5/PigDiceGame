classdef PigDiceGame_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                 matlab.ui.Figure
        TurnNumberLabel          matlab.ui.control.Label
        PassButton               matlab.ui.control.Button
        PlayerSelectButtonGroup  matlab.ui.container.ButtonGroup
        Player4Button            matlab.ui.control.RadioButton
        Player3Button            matlab.ui.control.RadioButton
        Player2Button            matlab.ui.control.RadioButton
        Player1Button            matlab.ui.control.RadioButton
        Player4EditField         matlab.ui.control.NumericEditField
        Player4EditFieldLabel    matlab.ui.control.Label
        Player3EditField         matlab.ui.control.NumericEditField
        Player3EditFieldLabel    matlab.ui.control.Label
        Player2EditField         matlab.ui.control.NumericEditField
        Player2EditFieldLabel    matlab.ui.control.Label
        Player1EditField         matlab.ui.control.NumericEditField
        Player1EditFieldLabel    matlab.ui.control.Label
        RolldiceButton           matlab.ui.control.Button
    end

properties (Access = private)
        roll
        turn
        currentPlayer
        players
        uploadInProgress
        channelID = '2567273'; 
        readAPIKey = '3C8G1CZ2GTRU7JGZ';
        writeAPIKey = 'NCRUDJE4B00WU9QY';
        gameStateTimer
    end

    methods (Access = private)
        function loadGameState(app)
            fprintf("\nloadGameState currentPlayer=%d turn=%d", app.currentPlayer, app.turn);
            if (app.uploadInProgress  | app.currentPlayer == app.turn)
                return;
            end
            url = sprintf('https://api.thingspeak.com/channels/%s/feeds.json?api_key=%s&results=1', app.channelID, app.readAPIKey);
            data = webread(url);
            if ~isempty(data.feeds)
                feed = data.feeds(end);
                app.players{1}.Value = str2double(feed.field1);
                app.players{2}.Value = str2double(feed.field2);
                app.players{3}.Value = str2double(feed.field3);
                app.players{4}.Value = str2double(feed.field4);
                app.turn = str2double(feed.field5);    
                app.TurnNumberLabel.Text = sprintf('Turn Number: %d', app.turn);
            else
                app.turn = 1;
                app.currentPlayer = 1;
                for i = 1:4
                    app.players{i}.Value = 0;
                end
            end
        end

        function updateGameState(app)
            data = [app.players{1}.Value, app.players{2}.Value, app.players{3}.Value, app.players{4}.Value, app.turn];
            url = sprintf('https://api.thingspeak.com/update?api_key=%s&field1=%d&field2=%d&field3=%d&field4=%d&field5=%d', ...
                app.writeAPIKey, data(1), data(2), data(3), data(4), data(5));
            webwrite(url, []);
        end

        function playerNumber = registerPlayer(app)
             if app.Player1Button.Value
                playerNumber = 1;
            elseif app.Player2Button.Value
                playerNumber = 2;
            elseif app.Player3Button.Value
                playerNumber = 3;
            elseif app.Player4Button.Value
                playerNumber = 4;
            else
                playerNumber = 1;  % Default to player 1 if no selection
            end
            app.currentPlayer = playerNumber;
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.players = {app.Player1EditField, app.Player2EditField, app.Player3EditField, app.Player4EditField}; 
            app.currentPlayer = app.registerPlayer();  
            fprintf("\nstartupFcn currentPlayer=%d turn=%d", app.currentPlayer, app.turn);
            app.turn=1;
            for i = 1:4
                app.players{i}.Value = 0;
            end
            app.updateGameState();
            fprintf("startupFcn");
            app.gameStateTimer = timer('ExecutionMode','fixedRate','Period', 2,'TimerFcn', @(~,~)app.loadGameState);
            start(app.gameStateTimer);
        end

        % Button pushed function: RolldiceButton
        function RolldiceButtonPushed(app, event)
           
            % if app.currentPlayer ~= app.turn
            %     app.loadGameState();
            %     return;
            % end
             app.roll = randi(8, 1);
            activePlayer = app.players{app.currentPlayer};
            if app.roll == 1 || app.roll == 5
                fprintf("Roll: %d  Pig! You lose all points for this round...\n", app.roll)
                activePlayer.Value = 0;
            else
                activePlayer.Value = activePlayer.Value + app.roll;
                fprintf("Roll: %d\n", app.roll);

                % Check for special swap rule
                for i = 1:4
                    if i ~= app.currentPlayer && abs(125 - app.players{i}.Value) <= 8 && app.roll == 8
                        temp = app.players{i}.Value;
                        app.players{i}.Value = activePlayer.Value;
                        activePlayer.Value = temp;
                        fprintf('Special rule triggered! Player %d swaps points with Player %d\n', app.currentPlayer, i);
                        break;
                    end
                end
            end
            app.updateGameState();
        
        end

        % Button pushed function: PassButton
        function PassButtonPushed(app, event)
            if app.currentPlayer ~= app.turn
                return;
            end
            app.turn = mod(app.turn,4)+1;
            app.TurnNumberLabel.Text = sprintf('Turn Number: %d', app.turn);
            app.uploadInProgress = true;
            app.updateGameState();
            app.uploadInProgress = false;
        end

        % Selection changed function: PlayerSelectButtonGroup
        function PlayerSelectButtonGroupSelectionChanged(app, event)
            fprintf("PlayerSelectButtonGroupSelectionChanged");
            app.registerPlayer();
            fprintf("PlayerSelectButtonGroupSelectionChanged app.currentPlayer=%d", app.currentPlayer);

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create RolldiceButton
            app.RolldiceButton = uibutton(app.UIFigure, 'push');
            app.RolldiceButton.ButtonPushedFcn = createCallbackFcn(app, @RolldiceButtonPushed, true);
            app.RolldiceButton.Position = [262 93 100 23];
            app.RolldiceButton.Text = 'Roll dice';

            % Create Player1EditFieldLabel
            app.Player1EditFieldLabel = uilabel(app.UIFigure);
            app.Player1EditFieldLabel.HorizontalAlignment = 'right';
            app.Player1EditFieldLabel.Position = [67 332 48 22];
            app.Player1EditFieldLabel.Text = 'Player 1';

            % Create Player1EditField
            app.Player1EditField = uieditfield(app.UIFigure, 'numeric');
            app.Player1EditField.Position = [130 332 100 22];

            % Create Player2EditFieldLabel
            app.Player2EditFieldLabel = uilabel(app.UIFigure);
            app.Player2EditFieldLabel.HorizontalAlignment = 'right';
            app.Player2EditFieldLabel.Position = [74 188 48 22];
            app.Player2EditFieldLabel.Text = 'Player 2';

            % Create Player2EditField
            app.Player2EditField = uieditfield(app.UIFigure, 'numeric');
            app.Player2EditField.Position = [137 188 100 22];

            % Create Player3EditFieldLabel
            app.Player3EditFieldLabel = uilabel(app.UIFigure);
            app.Player3EditFieldLabel.HorizontalAlignment = 'right';
            app.Player3EditFieldLabel.Position = [402 188 48 22];
            app.Player3EditFieldLabel.Text = 'Player 3';

            % Create Player3EditField
            app.Player3EditField = uieditfield(app.UIFigure, 'numeric');
            app.Player3EditField.Position = [465 188 100 22];

            % Create Player4EditFieldLabel
            app.Player4EditFieldLabel = uilabel(app.UIFigure);
            app.Player4EditFieldLabel.HorizontalAlignment = 'right';
            app.Player4EditFieldLabel.Position = [402 332 48 22];
            app.Player4EditFieldLabel.Text = 'Player 4';

            % Create Player4EditField
            app.Player4EditField = uieditfield(app.UIFigure, 'numeric');
            app.Player4EditField.Position = [465 332 100 22];

            % Create PlayerSelectButtonGroup
            app.PlayerSelectButtonGroup = uibuttongroup(app.UIFigure);
            app.PlayerSelectButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @PlayerSelectButtonGroupSelectionChanged, true);
            app.PlayerSelectButtonGroup.Title = 'Player Select';
            app.PlayerSelectButtonGroup.Position = [271 209 123 115];

            % Create Player1Button
            app.Player1Button = uiradiobutton(app.PlayerSelectButtonGroup);
            app.Player1Button.Text = 'Player 1';
            app.Player1Button.Position = [11 69 66 22];
            app.Player1Button.Value = true;

            % Create Player2Button
            app.Player2Button = uiradiobutton(app.PlayerSelectButtonGroup);
            app.Player2Button.Text = 'Player 2';
            app.Player2Button.Position = [11 47 66 22];

            % Create Player3Button
            app.Player3Button = uiradiobutton(app.PlayerSelectButtonGroup);
            app.Player3Button.Text = 'Player 3';
            app.Player3Button.Position = [11 25 66 22];

            % Create Player4Button
            app.Player4Button = uiradiobutton(app.PlayerSelectButtonGroup);
            app.Player4Button.Text = 'Player 4';
            app.Player4Button.Position = [11 4 66 22];

            % Create PassButton
            app.PassButton = uibutton(app.UIFigure, 'push');
            app.PassButton.ButtonPushedFcn = createCallbackFcn(app, @PassButtonPushed, true);
            app.PassButton.Position = [262 63 100 22];
            app.PassButton.Text = 'Pass';

            % Create TurnNumberLabel
            app.TurnNumberLabel = uilabel(app.UIFigure);
            app.TurnNumberLabel.Position = [34 23 213 22];
            app.TurnNumberLabel.Text = 'Turn Number: ';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = PigDiceGame_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end