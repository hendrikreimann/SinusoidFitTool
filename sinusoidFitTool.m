classdef sinusoidFitTool < handle

% TODO: 

    properties
        % figure elements
        main_figure;
        amplitude_panel;
        component_panel;
        result_panel;
        control_panel;
        load_data_button;
        reset_button;
        set_example_one_button;
        set_example_two_button;
        set_example_three_button;
        amplitude_edit;
        phase_shift_edit;
        dc_edit;
        control_button_panel;
        increase_amplitude_normal_button;
        increase_amplitude_large_button;
        decrease_amplitude_normal_button;
        decrease_amplitude_large_button;
        increase_phase_normal_button;
        increase_phase_large_button;
        decrease_phase_normal_button;
        decrease_phase_large_button;
        increase_dc_button;
        decrease_dc_button;
        new_component_frequency_box;
        add_component_button;
        total_error_label;

        amplitude_axes;
        amplitude_plot;
        current_component_axes;
        current_component_plot;
        error_without_current_component_plot;
        reconstruction_axes;
        reconstruction_plot;
        data_plot;
        error_axes;
        error_plot;
        component_axes = [];
        component_plots = [];
        component_labels = [];
        component_labels_phase_shift = [];
        total_error_history_axes;
        total_error_history_plot;
        total_error_history;

        % layout
        component_axes_max_height = 0.25;
        amplitude_panel_width = 0.15;
        component_panel_width = 0.25;
        result_panel_width = 0.4
        control_panel_width;
        control_button_width = 0.2;
        control_button_height = 0.2;
        linewidth = 6;
        color_component;
        color_data;
        color_reconstruction;
        color_error;

        % data
        time = [];
        data = [];
        components;
        dc = 0;
        dt;

        % control
        selected_component = [];
        amplitude_change_normal = 0.1;
        amplitude_change_large = 1;
        phase_shift_change_normal = 5;
        phase_shift_change_large = 30;
        dc_change = 1;
        history_window_size = 10;
    end
    methods
        function this = sinusoidFitTool()

            this.main_figure = figure('Position', [100 100 2000 1200]);
            this.control_panel_width = 1 - this.amplitude_panel_width - this.component_panel_width - this.result_panel_width;

            colors = lines(5);
            this.color_component = colors(5, :);
            this.color_data = colors(1, :);
            this.color_reconstruction = colors(4, :);
            this.color_error = colors(2, :);


            % create amplitude panel
            this.amplitude_panel = uipanel ...
              ( ...
                this.main_figure, ...
                'Title', 'Amplitudes', ...
                'FontSize', 12, ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0, ...
                    0, ...
                    this.amplitude_panel_width, ...
                    1 ...
                  ] ...
              );
            this.amplitude_axes = axes ...
              ( ...
                this.amplitude_panel, ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.0, ...
                    0.0, ...
                    1, ...
                    0 ...
                  ] ...
              );
            hold(this.amplitude_axes, 'on')
            set(this.amplitude_axes, 'xtick', [], 'ytick', [])
            this.amplitude_plot = stem(this.amplitude_axes, 0, 0, 'linewidth', this.linewidth*2, 'color', this.color_component);
            set(this.amplitude_plot, 'MarkerEdgeColor', 'none', 'MarkerFaceColor', this.color_component, 'MarkerSize', 20);
            view(this.amplitude_axes, -90,90)

            % create component panel
            this.component_panel = uipanel ...
              ( ...
                this.main_figure, ...
                'Title', 'Components', ...
                'FontSize', 12, ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    this.amplitude_panel_width, ...
                    0, ...
                    this.component_panel_width, ...
                    1 ...
                  ] ...
              );

            % create control panel
            this.control_panel = uipanel ...
              ( ...
                this.main_figure, ...
                'Title', 'Control', ...
                'FontSize', 12, ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    this.amplitude_panel_width + this.component_panel_width, ...
                    0, ...
                    this.control_panel_width, ...
                    1 ...
                  ] ...
              );
            this.set_example_one_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.075 0.91 0.25 0.08], ...
                'Fontsize', 12, ...
                'String', 'Example 1', ...
                'callback', @this.setExampleOne ...
              );
            this.set_example_two_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.375 0.91 0.25 0.08], ...
                'Fontsize', 12, ...
                'String', 'Example 2', ...
                'callback', @this.setExampleTwo ...
              );
            this.set_example_three_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.675 0.91 0.25 0.08], ...
                'Fontsize', 12, ...
                'String', 'Example 3', ...
                'callback', @this.setExampleThree ...
              );
            this.load_data_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.075 0.83 0.85 0.08], ...
                'Fontsize', 12, ...
                'String', 'Load Data', ...
                'callback', @this.loadData ...
              );
            this.reset_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.7 0.74 0.22 0.08], ...
                'Fontsize', 12, ...
                'String', 'Reset', ...
                'callback', @this.reset ...
              );
            uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'text', ...
                'string', 'Amplitude:', ...
                'Units', 'normalized', ...
                'Position', [0.1 0.8 0.25 0.02], ...
                'Fontsize', 12, ...
                'HorizontalAlignment', 'left', ...
                'KeyPressFcn', @this.processKeyPress, ...
                'BackgroundColor', 'white' ...
              );
            this.amplitude_edit = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'edit', ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', [0.35 0.8 0.3 0.02], ...
                'Callback', @this.changeAmplitude, ...
                'String', '0' ...
              );
            uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'text', ...
                'string', 'Phase Shift:', ...
                'Units', 'normalized', ...
                'Position', [0.1 0.77 0.25 0.02], ...
                'Fontsize', 12, ...
                'HorizontalAlignment', 'left', ...
                'KeyPressFcn', @this.processKeyPress, ...
                'BackgroundColor', 'white' ...
              );
            this.phase_shift_edit = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'edit', ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', [0.35 0.77 0.3 0.02], ...
                'Callback', @this.changePhase, ...
                'String', '0' ...
              );
            uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'text', ...
                'string', 'DC:', ...
                'Units', 'normalized', ...
                'Position', [0.1 0.74 0.25 0.02], ...
                'Fontsize', 12, ...
                'HorizontalAlignment', 'left', ...
                'KeyPressFcn', @this.processKeyPress, ...
                'BackgroundColor', 'white' ...
              );
            this.dc_edit = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'edit', ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', [0.35 0.74 0.3 0.02], ...
                'Callback', @this.changeDc, ...
                'String', '0' ...
              );
            this.control_button_panel = uipanel ...
              ( ...
                this.control_panel, ...
                'FontSize', 12, ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.1, ...
                    0.4, ...
                    0.8, ...
                    0.3 ...
                  ] ...
              );
            this.increase_dc_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width*2 0.5+this.control_button_height*1 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '+', ...
                'callback', @this.changeDc ...
              );
            this.decrease_dc_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width*2 0.5-this.control_button_height*2 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '-', ...
                'callback', @this.changeDc ...
              );
            this.increase_amplitude_normal_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width/2 0.5+this.control_button_height*0.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&uarr</html>', ...
                'callback', @this.changeAmplitude ...
              );
            this.increase_amplitude_large_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width/2 0.5+this.control_button_height*1.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&uarr<br />&uarr</html>', ...
                'callback', @this.changeAmplitude ...
              );
            this.decrease_amplitude_normal_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width/2 0.5-this.control_button_height*1.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&darr</html>', ...
                'callback', @this.changeAmplitude ...
              );
            this.decrease_amplitude_large_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width/2 0.5-this.control_button_height*2.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&darr<br />&darr</html>', ...
                'callback', @this.changeAmplitude ...
              );

            this.decrease_phase_normal_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width*2.5 0.5-this.control_button_height*0.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&larr &larr</html>', ...
                'callback', @this.changePhase ...
              );
            this.decrease_phase_large_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5-this.control_button_width*1.5 0.5-this.control_button_height*0.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&larr</html>', ...
                'callback', @this.changePhase ...
              );
            this.increase_phase_normal_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5+this.control_button_width*0.5 0.5-this.control_button_height*0.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&rarr</html>', ...
                'callback', @this.changePhase ...
              );
            this.increase_phase_large_button = uicontrol ...
              ( ...
                this.control_button_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.5+this.control_button_width*1.5 0.5-this.control_button_height*0.5 this.control_button_width this.control_button_height], ...
                'Fontsize', 16, ...
                'String', '<html>&rarr &rarr</html>', ...
                'callback', @this.changePhase ...
              );

            uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'text', ...
                'string', 'Harmonic:', ...
                'Units', 'normalized', ...
                'Position', [0.1 0.05 0.25 0.02], ...
                'Fontsize', 12, ...
                'HorizontalAlignment', 'left', ...
                'KeyPressFcn', @this.processKeyPress, ...
                'BackgroundColor', 'white' ...
              );
            this.new_component_frequency_box = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'edit', ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', [0.3 0.05 0.2 0.02], ...
                'KeyPressFcn', @this.processKeyPress, ...
                'String', '1' ...
              );
            this.add_component_button = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'pushbutton', ...
                'Units', 'normalized', ...
                'Position', [0.55 0.03 0.4 0.06], ...
                'Fontsize', 12, ...
                'String', 'Add Component', ...
                'callback', @this.addComponent ...
              );


            this.total_error_history_axes = axes ...
              ( ...
                this.control_panel, ...
                'Units', 'normalized', ...
                'Position', [0.1 0.18 0.8 0.2] ...
              );
            this.total_error_history_plot = plot(this.total_error_history_axes, 0, 1, 'linewidth', this.linewidth, 'color', this.color_error);
            hold(this.total_error_history_axes, 'on')
            set(this.total_error_history_axes, 'xtick', [])
            
            this.total_error_label = uicontrol ...
              ( ...
                this.control_panel, ...
                'Style', 'text', ...
                'string', 'Total RMS Error: ', ...
                'Units', 'normalized', ...
                'Position', [0.1 0.1 0.9 0.05], ...
                'Fontsize', 24, ...
                'HorizontalAlignment', 'left', ...
                'KeyPressFcn', @this.processKeyPress, ...
                'BackgroundColor', 'white' ...
              );



            % create results panel
            this.result_panel = uipanel ...
              ( ...
                this.main_figure, ...
                'Title', 'Results', ...
                'FontSize', 12, ...
                'BackgroundColor', 'white', ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    this.amplitude_panel_width + this.control_panel_width + this.component_panel_width, ...
                    0, ...
                    this.result_panel_width, ...
                    1 ...
                  ] ...
              );
            this.current_component_axes = axes ...
              ( ...
                this.result_panel, ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.05, ...
                    0.675, ...
                    0.925, ...
                    0.3 ...
                  ] ...
              );
            hold(this.current_component_axes, 'on');
            title(this.current_component_axes, 'Current Component')
            this.current_component_plot = plot(0, 0, 'linewidth', this.linewidth, 'DisplayName', 'Selected Component', 'color', this.color_component);
            this.error_without_current_component_plot = plot(0, 0, 'linewidth', this.linewidth, 'DisplayName', 'Error Without Selected Component', 'color', this.color_error);
            legend(this.current_component_axes, 'show', 'Fontsize', 16)
            set(this.current_component_axes, 'xtick', [], 'fontsize', 16);


            this.reconstruction_axes = axes ...
              ( ...
                this.result_panel, ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.05, ...
                    0.35, ...
                    0.925, ...
                    0.3 ...
                  ] ...
              );
            hold(this.reconstruction_axes, 'on');
            title(this.reconstruction_axes, 'Reconstruction')
            this.data_plot = plot(0, 0, 'linewidth', this.linewidth, 'DisplayName', 'Data', 'color', this.color_data);
            this.reconstruction_plot = plot(0, 0, 'linewidth', this.linewidth, 'DisplayName', 'Reconstruction', 'color', this.color_reconstruction);
            legend(this.reconstruction_axes, 'show', 'Fontsize', 16)
            set(this.reconstruction_axes, 'xtick', [], 'fontsize', 16);
            
            this.error_axes = axes ...
              ( ...
                this.result_panel, ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.05, ...
                    0.025, ...
                    0.925, ...
                    0.3 ...
                  ] ...
              );
            title(this.error_axes, 'Error')
            this.error_plot = plot(0, 0, 'linewidth', this.linewidth, 'DisplayName', 'Total Error', 'color', this.color_error);
            legend(this.error_axes, 'show', 'Fontsize', 16)
            set(this.error_axes, 'fontsize', 16)
            

            % set default data
            this.setExampleOne;

            % initialize components
            column_names = ...
              { ...
                'frequency', ...
                'amplitude', ...
                'phase shift', ...
              };
            column_types = ...
              { ...
                'uint64', ...
                'double', ...
                'double'
              };
            this.components = table('size', [0 3], 'VariableTypes', column_types, 'VariableNames',column_names);

        end
        function newData(this, time, data)
            this.time = time;
            this.data = data;
            this.dt = time(2) - time(1);

            % remove existing components (?)

            this.update();

            

        end
        function loadData(this, sender, eventdata)
            % get location
            file_to_load = 'exampleData.mat';
            load(file_to_load, 'time', 'data');

            % apply
            this.newData(time, data)
        end
        function reset(this, sender, eventdata)
            % remove component axes, plots and labels
            number_of_components = size(this.components, 1);
            for i_component = 1 : number_of_components
                delete(this.component_axes(i_component));
                delete(this.component_labels(i_component));
            end
            this.component_axes = [];
            this.component_plots = [];
            this.component_labels = [];

            % clear out amplitude plot
            set(this.amplitude_plot, 'xdata', 0, 'ydata', 0);

            % reset component table
            column_names = ...
              { ...
                'frequency', ...
                'amplitude', ...
                'phase shift', ...
              };
            column_types = ...
              { ...
                'uint64', ...
                'double', ...
                'double'
              };
            this.components = table('size', [0 3], 'VariableTypes', column_types, 'VariableNames',column_names);

            % remove selected component
            this.selected_component = [];
            set(this.current_component_plot, 'xdata', 0, 'ydata', 0);
            set(this.error_without_current_component_plot, 'xdata', 0, 'ydata', 0);

            % reset harmonic for new components to 1
            this.new_component_frequency_box.String = num2str(1);

            % update
            this.update();
        end
        function setDefaultData(this)
            dt = 0.001;
            T = 20;
            time_here = dt : dt : T; %#ok<PROP> 
            N = length(time_here);
            
            % create signal
            omega = 1/T * 2 * pi;
            number_of_frequency_components = 22;
            f = (1 : number_of_frequency_components) * 0.05;
            amplitudes = zeros(size(f));
            phase_shift = zeros(size(f));

            A_0 = 0;
            
            amplitudes(1) = 0.5;
            amplitudes(4) = 1.0;
            amplitudes(7) = 0.5;
            amplitudes(12) = 0.6;
            amplitudes(20) = 0.6;
            
            phase_shift(1) = 2;
            phase_shift(4) = 1.1;
            phase_shift(7) = 1.7;
            phase_shift(12) = 2.3;
            phase_shift(20) = 2.3;
            
            x = zeros(size(time_here)) + A_0;
            for i_frequency = 1 : number_of_frequency_components
                this_frequency = f(i_frequency);
                this_phase_shift = phase_shift(i_frequency);
                this_amplitude = amplitudes(i_frequency);
            
                this_component = this_amplitude * cos(time_here * 2 * pi * this_frequency + this_phase_shift);
                x = x + this_component;
            end
            

            this.newData(time_here, x)
        end
        function setExampleOne(this, sender, eventdata)
            T = pi/2;
            time_here = linspace(-T, T, 1000);
            u = -7.5;
            v = 12.2;
            data_here = time_here.^5 + u*time_here.^3 + v*time_here;            
            time_resampled = (1 : numel(time_here)) * 1/numel(time_here);
            this.newData(time_resampled, data_here)
        end
        function setExampleTwo(this, sender, eventdata)
            T = pi/2;
            time_here = linspace(-T, T, 1000);
            p = -5;
            q = 6.25;
            data_here = time_here.^6 + p*time_here.^4 + q*time_here.^2 + 1;
            time_resampled = (1 : numel(time_here)) * 1/numel(time_here);
            this.newData(time_resampled, data_here)
        end
        function setExampleThree(this, sender, eventdata)
            T = pi/2;
            time_here = linspace(-T, T, 1000);
            u = -7.5;
            v = 12.2;
            p = -5;
            q = 6.25;
            data_here = time_here.^6 + p*time_here.^4 + q*time_here.^2 + 1 + time_here.^5 + u*time_here.^3 + v*time_here;
            time_resampled = (1 : numel(time_here)) * 1/numel(time_here);
            this.newData(time_resampled, data_here)
        end

        function addComponent(this, sender, eventdata)
            if strcmp(sender.String, 'Add Component')
                % get info
                harmonic = round(str2num(this.new_component_frequency_box.String));
            end
            
            % check whether component already exists
            if any(table2array(this.components(:, 'frequency')) == harmonic)
                return
            end
            
            % add axes and plot
            new_component_axes = axes ...
              ( ...
                this.component_panel, ...
                'Units', 'normalized', ...
                'Position', ...
                  [ ...
                    0.025, ...
                    0, ...
                    0.95, ...
                    0.3 ...
                  ] ...
              );

            new_component_plot = plot(0, 0, 'linewidth', this.linewidth, 'color', this.color_component);
            set(new_component_axes, 'ButtonDownFcn', @this.componentAxesClicked, 'UserData', harmonic);
            set(new_component_plot, 'HitTest','off');
            this.component_axes = [this.component_axes; new_component_axes];
            this.component_plots = [this.component_plots; new_component_plot];

            % add a line to the component table
            default_amplitude = 0;
            default_phase_shift = 0;
            new_line = {harmonic, default_amplitude, default_phase_shift};
            this.components = [this.components; new_line];


            % add labels for amplitude and phase shift
            new_component_label = ...
                text ...
                  ( ...
                    0, ...
                    0, ...
                    {'F: '; 'A: 0'; 'P: 0'}, ...
                    'Fontsize', 24, ...
                    'horizontalalignment', 'left', ...
                    'parent', new_component_axes ...
                  );
            this.component_labels = [this.component_labels; new_component_label];

            % sort the table and the axes and plot arrays
            % ...

            % update the selected component
            this.selected_component = harmonic;

            % update the axes sizes
            this.updateComponentAxesLayout();

%             disp(this.components)
%             disp(this.component_axes)
%             disp(this.component_plots)

            % increment
            this.new_component_frequency_box.String = num2str(harmonic+1);

            % update
            this.update();
        end
        function componentAxesClicked(this, sender, eventdata)
            % figure out which axes have been clicked
            this.selected_component = sender.UserData;
            this.update();
        end
        function update(this)
            data_xlimits = [this.time(1) this.time(end)];

            % update component plots
            omega = 1 / (this.time(end) - this.time(1) + this.dt);
            number_of_components = size(this.components, 1);
            superposition_data = zeros(size(this.time)) + this.dc;
            superposition_without_selected_component_data = zeros(size(this.time)) + this.dc;
            for i_component = 1 : number_of_components
                % get data
                this_harmonic = double(table2array(this.components(i_component, 'frequency')));
                this_frequency = this_harmonic * omega;
                this_amplitude = double(table2array(this.components(i_component, 'amplitude')));
                this_phase_shift = deg2rad(double(table2array(this.components(i_component, 'phase shift'))));

                % construct component
                this_component_data = this_amplitude * cos(this.time * 2 * pi * this_frequency - this_phase_shift);
                superposition_data = superposition_data + this_component_data;

                if this_harmonic == this.selected_component
                    selected_component_data = this_component_data;
                else
                    superposition_without_selected_component_data = superposition_without_selected_component_data + this_component_data;
                end

                % export to plot object
                set(this.component_plots(i_component), 'XData', this.time, 'YData', this_component_data);

                % highlight selected component
                if this_harmonic == this.selected_component
                    set(this.component_axes(i_component), 'XColor', [1 0.5 0], 'YColor', [1 0.5 0], 'linewidth', 6)
                else
                    set(this.component_axes(i_component), 'XColor', 'black', 'YColor', 'black', 'linewidth', 0.5)
                end

                % update limits
                set(this.component_axes(i_component), 'xlim', data_xlimits)

                % update label
                this_label = this.component_labels(i_component);
                xlimits = this.component_axes(i_component).XLim;
                new_x_pos = xlimits(1) + (xlimits(2)-xlimits(1))*0.02;
                this_label.Position(1) = new_x_pos;
                new_string = {['F: ' num2str(this_frequency) ' Hz']; ['A: ' num2str(this_amplitude)]; ['P: ' num2str(rad2deg(this_phase_shift))]};
                this_label.String = new_string;
                
            end

            % update reconstruction plot
            error = this.data - superposition_data;
            if ~isempty(this.selected_component)
                this.current_component_plot.XData = this.time;
                this.current_component_plot.YData = selected_component_data;

                this.error_without_current_component_plot.XData = this.time;
                this.error_without_current_component_plot.YData = this.data - superposition_without_selected_component_data;
            end
            this.reconstruction_plot.XData = this.time;
            this.reconstruction_plot.YData = superposition_data;
            this.data_plot.XData = this.time;
            this.data_plot.YData = this.data;
            this.error_plot.XData = this.time;
            this.error_plot.YData = error;
            ylimits = this.reconstruction_axes.YLim;
            ylimits_range = ylimits(2) - ylimits(1);
            this.error_axes.YLim = ylimits_range/2 * [-1 1];
            set(this.current_component_axes, 'xlim', data_xlimits)
            set(this.reconstruction_axes, 'xlim', data_xlimits)
            set(this.error_axes, 'xlim', data_xlimits)

            % calculate total error
            total_error = rms(error);
            this.total_error_label.String = ['Total RMS Error: ' num2str(total_error)];

            % store total error
            this.total_error_history = [this.total_error_history total_error];
            set(this.total_error_history_plot, 'xdata', 1:numel(this.total_error_history), 'ydata', this.total_error_history)
            if numel(this.total_error_history) > this.history_window_size
                this.total_error_history_axes.XLim = [numel(this.total_error_history) - this.history_window_size + 1, numel(this.total_error_history)];
            end

            % update control elements
            if ~isempty(this.selected_component)
                % update amplitude edit
                current_amplitude = table2array(this.components(this.selected_component, 'amplitude'));
                set(this.amplitude_edit, 'String', num2str(current_amplitude))

                % update phase shift edit
                current_phase_shift = table2array(this.components(this.selected_component, 'phase shift'));
                set(this.phase_shift_edit, 'String', num2str(current_phase_shift))
            end

            % update dc
            set(this.dc_edit, 'String', num2str(this.dc))

            % update amplitude plot
            if size(this.components, 1) > 0
                harmonics = table2array(this.components(:, 'frequency'));
                amplitudes = table2array(this.components(:, 'amplitude'));
                set(this.amplitude_plot, 'xdata', harmonics, 'ydata', amplitudes);

                xlimits = [double(min(harmonics))-0.5 double(max(harmonics))+0.5];
                set(this.amplitude_axes, 'xlim', xlimits)

            end
        end
        function updateComponentAxesLayout(this)
            number_of_components = size(this.components, 1);
            height = 1 / number_of_components;
            if height > this.component_axes_max_height
                height = this.component_axes_max_height;
            end
            for i_component = 1 : number_of_components
                % adjust size and position
                these_axes = this.component_axes(i_component);
                pos = these_axes.Position;
                pos(4) = height;
                pos(2) = (i_component-1) * height;
                these_axes.Position = pos;

                % adjust ticks
                these_axes.XTick = [];
                these_axes.XTickLabel = [];
                these_axes.YTick = [];
                these_axes.YTickLabel = [];


            end
            new_amplitude_height = height * number_of_components;
            this.amplitude_axes.Position(4) = new_amplitude_height;

        end
        function changeAmplitude(this, sender, eventdata)
            
            if ~isempty(this.selected_component)
                % get current amplitude
                current_amplitude = table2array(this.components(this.selected_component, 'amplitude'));

                % determine new amplitude
                if strcmp(sender.String, '<html>&uarr<br />&uarr</html>')
                    % normal increase button
                    new_amplitude = current_amplitude + this.amplitude_change_large;
                elseif strcmp(sender.String, '<html>&uarr</html>')
                    % normal increase button
                    new_amplitude = current_amplitude + this.amplitude_change_normal;
                elseif strcmp(sender.String, '<html>&darr</html>')
                    % normal decrease button
                    new_amplitude = current_amplitude - this.amplitude_change_normal;
                elseif strcmp(sender.String, '<html>&darr<br />&darr</html>')
                    % large decrease button
                    new_amplitude = current_amplitude - this.amplitude_change_large;
                else
                    % no button, so this must come from the edit box
                    new_amplitude = str2double(sender.String);
                end

                % apply new amplitude
                this.components(this.selected_component, 'amplitude') = array2table(new_amplitude);
                this.update();
            end
        end
        function changeDc(this, sender, eventdata)
            % determine new dc
            if strcmp(sender.String, '+')
                % increase button
                new_dc = this.dc + this.dc_change;
            elseif strcmp(sender.String, '-')
                % decrease button
                new_dc = this.dc - this.dc_change;
            else
                % no button, so this must come from edit box
                new_dc = str2double(sender.String);
            end

            % apply new dc
            this.dc = new_dc;
            this.update();
        end
        function changePhase(this, sender, eventdata)
            
            if ~isempty(this.selected_component)
                % get current amplitude
                current_phase = table2array(this.components(this.selected_component, 'phase shift'));

                % determine new amplitude
                if strcmp(sender.String, '<html>&rarr &rarr</html>')
                    % normal increase button
                    new_phase = current_phase + this.phase_shift_change_large;
                elseif strcmp(sender.String, '<html>&rarr</html>')
                    % normal increase button
                    new_phase = current_phase + this.phase_shift_change_normal;
                elseif strcmp(sender.String, '<html>&larr</html>')
                    % normal decrease button
                    new_phase = current_phase - this.phase_shift_change_normal;
                elseif strcmp(sender.String, '<html>&larr &larr</html>')
                    % large decrease button
                    new_phase = current_phase - this.phase_shift_change_large;
                else
                    % no button, so this must come from the edit box
                    new_phase = str2double(sender.String);
                end
                while new_phase > 180
                    new_phase = new_phase - 360;
                end
                while new_phase <= -180
                    new_phase = new_phase + 360;
                end
                

                % apply new amplitude
                this.components(this.selected_component, 'phase shift') = array2table(new_phase);
                this.update();
            end
        end
        function processKeyPress(this, sender, eventdata)

        end
    end
end