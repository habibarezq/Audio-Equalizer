classdef Audio_Equalizer < matlab.apps.AppBase

    % Public components (UI controls)
    properties (Access = public)
        UIFigure                   matlab.ui.Figure
        AxisPanel                  matlab.ui.container.Panel
        OutputFreqAxes             matlab.ui.control.UIAxes
        InputFreqAxes              matlab.ui.control.UIAxes
        OutputTimeAxes             matlab.ui.control.UIAxes
        InputTimeAxes              matlab.ui.control.UIAxes
        SamplingRateEditField_2    matlab.ui.control.NumericEditField
        SamplingRateEditField_2Label matlab.ui.control.Label
        BandtoPlotDropDown         matlab.ui.control.DropDown
        BandtoPlotDropDownLabel    matlab.ui.control.Label
        LocationEditField          matlab.ui.control.EditField
        LocationEditFieldLabel     matlab.ui.control.Label
        PlayButton                 matlab.ui.control.Button
        doubleFsButton             matlab.ui.control.Button
        halfFsButton               matlab.ui.control.Button
        ModeButtonGroup            matlab.ui.container.ButtonGroup
        CustomButton               matlab.ui.control.RadioButton
        StandardButton             matlab.ui.control.RadioButton
        EnterButton                matlab.ui.control.Button
        FrequencyBandGainsPanel    matlab.ui.container.Panel
        gain_20k                   matlab.ui.control.Slider
        KHzLabel_4                 matlab.ui.control.Label
        gain_14k                   matlab.ui.control.Slider
        KHzLabel                   matlab.ui.control.Label
        gain_12k                   matlab.ui.control.Slider
        KHzLabel_2                 matlab.ui.control.Label
        gain_6k                    matlab.ui.control.Slider
        KHzLabel_3                 matlab.ui.control.Label
        gain_610                   matlab.ui.control.Slider
        HzLabel_2                  matlab.ui.control.Label
        gain_300                   matlab.ui.control.Slider
        Label                      matlab.ui.control.Label
        gain_170                   matlab.ui.control.Slider
        HzLabel                    matlab.ui.control.Label
        PlotButton                 matlab.ui.control.Button
        SaveButton                 matlab.ui.control.Button
        StartButton                matlab.ui.control.Button
        FilterTypeButtonGroup      matlab.ui.container.ButtonGroup
        IIRButton                  matlab.ui.control.RadioButton
        FIRButton                  matlab.ui.control.RadioButton
        BrowseButton               matlab.ui.control.Button
        ResetButton                matlab.ui.control.Button
        UIAxes3                    matlab.ui.control.UIAxes
        UIAxes4                    matlab.ui.control.UIAxes
        UIAxes5                    matlab.ui.control.UIAxes
        UIAxes6                    matlab.ui.control.UIAxes
        MagnitudeLabel             matlab.ui.control.Label
        PhaseLabel                 matlab.ui.control.Label
        BeforeLabel_2              matlab.ui.control.Label
        AfterLabel                 matlab.ui.control.Label
        FreuquencyDomainPanel      matlab.ui.container.Panel
        Panel                      matlab.ui.container.Panel
    end

    % Internal data
    properties (Access = private)
        y                   % input signal
        fs                  % original sampling rate
        newfs               % output sampling rate
        t                   % time vector
        Ns                  % number of samples
        BandGains = ones(1,9)
        BandEdges
        CustomBands
        CustomGains
        FilterType
        FilterTypeFIR
        FilterTypeIIR
        FilterOrder
        FilterSubType
        OutputSignal
    end

    %–– Component initialization ––
    methods (Access = private)
        function createComponents(app)
            % Create UIFigure
            app.UIFigure = uifigure('Visible','off');
            app.UIFigure.Position = [80 -10 1170 840];
            app.UIFigure.Name     = 'Audio Equalizer';
            app.UIFigure.Scrollable = 'on';
            app.UIFigure.Color      = [0.8 0.8 0.8];

            % Browse Button
            app.BrowseButton = uibutton(app.UIFigure, 'push');
            app.BrowseButton.Position = [274 798 56 22];
            app.BrowseButton.Text     = 'Browse';
            app.BrowseButton.ButtonPushedFcn = createCallbackFcn(app, @BrowseButtonPushed, true);

            % Filter Type Button Group
            app.FilterTypeButtonGroup = uibuttongroup(app.UIFigure);
            app.FilterTypeButtonGroup.Title = 'Filter Type';
            app.FilterTypeButtonGroup.Position = [675 758 100 66];
            app.FilterTypeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @FilterTypeButtonGroupSelectionChanged, true);

            % FIR Radio Button
            app.FIRButton = uiradiobutton(app.FilterTypeButtonGroup);
            app.FIRButton.Text = 'FIR';
            app.FIRButton.Position = [11 22 58 20];
            app.FIRButton.Value    = true;

            % IIR Radio Button
            app.IIRButton = uiradiobutton(app.FilterTypeButtonGroup);
            app.IIRButton.Text     = 'IIR';
            app.IIRButton.Position = [11 1 65 22];

            % Start Button
            app.StartButton = uibutton(app.UIFigure, 'push');
            app.StartButton.Position = [22 767 61 22];
            app.StartButton.Text     = 'Start';
            app.StartButton.ButtonPushedFcn = createCallbackFcn(app, @StartButtonPushed, true);

            % Save Button
            app.SaveButton = uibutton(app.UIFigure, 'push');
            app.SaveButton.Position = [87 767 60 22];
            app.SaveButton.Text     = 'Save';
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);

            % Frequency Band Gains Panel
            app.FrequencyBandGainsPanel = uipanel(app.UIFigure);
            app.FrequencyBandGainsPanel.Title = 'Frequency Band Gains';
            app.FrequencyBandGainsPanel.Position = [1 360 791 306];

            % Sliders and Labels for Gains
            % (Repeat for all bands)
            app.gain_170 = uislider(app.FrequencyBandGainsPanel);
            app.gain_170.Limits = [-12 12];
            app.gain_170.Orientation = 'vertical';
            app.gain_170.Position = [29 461 3 150];
            app.HzLabel = uilabel(app.FrequencyBandGainsPanel, 'Text', '0-200Hz', 'Position', [22 423 50 22]);

            app.gain_300 = uislider(app.FrequencyBandGainsPanel);
            app.gain_300.Limits = [-12 12];
            app.gain_300.Orientation = 'vertical';
            app.gain_300.Position = [108 460 3 150];
            app.Label = uilabel(app.FrequencyBandGainsPanel, 'Text', '200-500Hz', 'Position', [82 423 69 22]);

            app.gain_610 = uislider(app.FrequencyBandGainsPanel);
            app.gain_610.Limits = [-12 12];
            app.gain_610.Orientation = 'vertical';
            app.gain_610.Position = [190 460 3 150];
            app.HzLabel_2 = uilabel(app.FrequencyBandGainsPanel, 'Text', '500-800Hz', 'Position', [164 424 69 22]);

            app.gain_1005 = uislider(app.FrequencyBandGainsPanel);
            app.gain_1005.Limits = [-12 12];
            app.gain_1005.Orientation = 'vertical';
            app.gain_1005.Position = [268 101 3 150];
            app.HzLabel_3 = uilabel(app.FrequencyBandGainsPanel, 'Text', '800-1200Hz', 'Position', [252 65 70 22]);

            app.gain_3k = uislider(app.FrequencyBandGainsPanel);
            app.gain_3k.Limits = [-12 12];
            app.gain_3k.Orientation = 'vertical';
            app.gain_3k.Position = [345 101 3 150];
            app.KHzLabel = uilabel(app.FrequencyBandGainsPanel, 'Text', '1.2-3 KHz', 'Position', [340 65 58 22]);

            app.gain_6k = uislider(app.FrequencyBandGainsPanel);
            app.gain_6k.Limits = [-12 12];
            app.gain_6k.Orientation = 'vertical';
            app.gain_6k.Position = [429 460 3 150];
            app.KHzLabel_3 = uilabel(app.FrequencyBandGainsPanel, 'Text', '3-6 KHz', 'Position', [418 424 48 22]);

            app.gain_12k = uislider(app.FrequencyBandGainsPanel);
            app.gain_12k.Limits = [-12 12];
            app.gain_12k.Orientation = 'vertical';
            app.gain_12k.Position = [504 461 3 150];
            app.KHzLabel_2 = uilabel(app.FrequencyBandGainsPanel, 'Text', '6-12 KHz', 'Position', [490 423 57 22]);

            app.gain_14k = uislider(app.FrequencyBandGainsPanel);
            app.gain_14k.Limits = [-12 12];
            app.gain_14k.Orientation = 'vertical';
            app.gain_14k.Position = [577 460 3 150];
            app.KhzLabel = uilabel(app.FrequencyBandGainsPanel, 'Text', '12-16 KHz', 'Position', [564 424 56 22]);

            app.gain_20k = uislider(app.FrequencyBandGainsPanel);
            app.gain_20k.Limits = [-12 12];
            app.gain_20k.Orientation = 'vertical';
            app.gain_20k.Position = [645 460 3 150];
            app.KHzLabel_4 = uilabel(app.FrequencyBandGainsPanel, 'Text', '16-20 KHz', 'Position', [632 424 62 22]);

            % Plot Button
            app.PlotButton = uibutton(app.FrequencyBandGainsPanel, 'push');
            app.PlotButton.Position = [319 12 100 29];
            app.PlotButton.Text = 'Plot';
            app.PlotButton.ButtonPushedFcn = createCallbackFcn(app, @PlotButtonPushed, true);

            % Reset Button
            app.ResetButton = uibutton(app.FrequencyBandGainsPanel, 'push');
            app.ResetButton.Position = [702 12 64 22];
            app.ResetButton.Text = 'Reset';
            app.ResetButton.ButtonPushedFcn = createCallbackFcn(app, @ResetButtonPushed, true);

            % Frequency Domain Panel
            app.FreuquencyDomainPanel = uipanel(app.UIFigure);
            app.FreuquencyDomainPanel.Title = 'Frequency Domain';
            app.FreuquencyDomainPanel.Position = [792 87 370 735];

            % UIAxes for time & frequency
            app.InputTimeAxes  = uiaxes(app.Figure);   % adjust parent & position as desired
            app.OutputTimeAxes = uiaxes(app.Figure);
            app.InputFreqAxes  = uiaxes(app.Figure);
            app.OutputFreqAxes = uiaxes(app.Figure);

            % ... place & configure each UIAxes similarly ...

            % Sampling Rate Edit Field
            app.SamplingRateEditField_2Label = uilabel(app.UIFigure, 'Text', 'Sampling Rate', 'Position', [335 798 84 22]);
            app.SamplingRateEditField_2 = uieditfield(app.UIFigure, 'numeric', ...
                'Position', [434 798 57 22], ...
                'ValueChangedFcn', createCallbackFcn(app, @EnterButtonPushed, true));

            % Band-to-Plot DropDown
            app.BandtoPlotDropDownLabel = uilabel(app.UIFigure, 'Text', 'Band to Plot', 'Position', [227 766 69 22]);
            app.BandtoPlotDropDown = uidropdown(app.UIFigure, ...
                'Items', {'0-200 Hz','200-500 Hz','500-800 Hz','800-1200 Hz','1.2-3 KHz','3-6 KHz','6-12 KHz','12-16 KHz','16-20 KHz'}, ...
                'Position', [307 767 88 22], ...
                'ValueChangedFcn', createCallbackFcn(app, @BandtoPlotDropDownValueChanged, true));

            % Mode Button Group
            app.ModeButtonGroup = uibuttongroup(app.UIFigure, ...
                'Title','Mode','Position',[561 757 100 65], ...
                'SelectionChangedFcn', createCallbackFcn(app, @ModeButtonGroupSelectionChanged, true));
            app.StandardButton = uiradiobutton(app.ModeButtonGroup, 'Text','Standard','Position',[11 19 70 23],'Value',true);
            app.CustomButton   = uiradiobutton(app.ModeButtonGroup, 'Text','Custom','Position',[11 1 65 22]);

            % Play, halfFs, doubleFs Buttons
            app.PlayButton      = uibutton(app.UIFigure,'Text','Play','Position',[150 767 60 22],'ButtonPushedFcn',createCallbackFcn(app,@PlayButtonPushed,true));
            app.halfFsButton    = uibutton(app.UIFigure,'Text','half Fs','Position',[478 764 55 26],'ButtonPushedFcn',createCallbackFcn(app,@halfFsButtonPushed,true));
            app.doubleFsButton  = uibutton(app.UIFigure,'Text','double Fs','Position',[411 764 62 26],'ButtonPushedFcn',createCallbackFcn(app,@doubleFsButtonPushed,true));

            % Show UIFigure
            app.UIFigure.Visible = 'on';
        end
    end

    %–– Callbacks ––
    methods (Access = private)
        function BrowseButtonPushed(app, ~)
            [file,path] = uigetfile('*.wav','Select Audio File');
            if isequal(file,0), return; end
            fullName = fullfile(path,file);
            app.LocationEditField.Value = fullName;
            [app.y,app.fs] = audioread(fullName);
            app.y = app.y(:,1)';  
            app.Ns = numel(app.y);
            app.t  = (0:app.Ns-1)/app.fs;
            app.newfs = app.fs;
        end

        function StartButtonPushed(app, ~)
            gains = [app.gain_170.Value, app.gain_300.Value, app.gain_610.Value, ...
                     app.gain_1005.Value, app.gain_3k.Value, app.gain_6k.Value, ...
                     app.gain_12k.Value, app.gain_14k.Value, app.gain_20k.Value];
            app.BandGains = db2mag(gains);
            app.BandEdges = [0,200,500,800,1200,3000,6000,12000,16000,20000];
            app.applyFilter();
        end

        function PlotButtonPushed(app, ~)
            app.plotOnUIAxes();
        end

        function doubleFsButtonPushed(app, ~)
            app.newfs = 2*app.fs;
            sound(app.y, app.newfs);
            app.plotOnUIAxes();
        end

        function halfFsButtonPushed(app, ~)
            app.newfs = app.fs/2;
            sound(app.y, app.newfs);
            app.plotOnUIAxes();
        end

        function SaveButtonPushed(app, ~)
            audiowrite("output_file_half.wav",  app.OutputSignal, app.newfs/2);
            audiowrite("output_file_double.wav",app.OutputSignal, app.newfs*2);
        end

        function PlayButtonPushed(app, ~)
            if isempty(app.y)||isempty(app.fs)
                uialert(app.UIFigure,'No signal loaded','Error');
                return;
            end
            sound(app.y,app.fs);
        end

        function ResetButtonPushed(app, ~)
            cla(app.InputTimeAxes);  cla(app.OutputTimeAxes);
            cla(app.InputFreqAxes);   cla(app.OutputFreqAxes);
            app.BandGains = ones(1,9);
            for s = [app.gain_170,app.gain_300,app.gain_610,app.gain_1005,...
                     app.gain_3k,app.gain_6k,app.gain_12k,app.gain_14k,app.gain_20k]
                s.Value = 0;
            end
            app.OutputSignal = [];
        end

        function EnterButtonPushed(app, ~)
            v = app.SamplingRateEditField_2.Value;
            if ~isnumeric(v)||isnan(v)||v<=0
                uialert(app.UIFigure,'Sampling rate must be >0','Invalid');
                app.SamplingRateEditField_2.Value = 44100;
            else
                app.fs = v;
            end
        end

        function ModeButtonGroupSelectionChanged(app, ~)
            if app.ModeButtonGroup.SelectedObject == app.StandardButton
                app.CustomBands = [];
            else
                d = app.showCustomBandDialog(); waitfor(d);
                app.showCustomGainDialogBox();
                app.BandEdges = app.CustomBands;
                app.BandGains = db2mag(app.CustomGains);
            end
        end

        function FilterTypeButtonGroupSelectionChanged(app, ~)
            if app.FilterTypeButtonGroup.SelectedObject == app.FIRButton
                app.FilterType    = 'FIR';
                app.FilterTypeFIR = app.getFIRFilterType();
            else
                app.FilterType    = 'IIR';
                app.FilterTypeIIR = app.getIIRFilterType();
            end
            app.FilterOrder = app.getFilterOrder();
        end

        function BandtoPlotDropDownValueChanged(app, ~)
            % Not used currently
        end
    end

    %–– Helpers / Processing ––
    methods (Access = private)
        function d = showCustomBandDialog(app)
            d = uifigure('Position',[500 500 300 200],'Name','Custom Bands');
            uilabel(d,'Text','Enter edges (comma) 0…20000:','Position',[20 130 260 30]);
            fld = uieditfield(d,'text','Position',[20 100 260 25]);
            uibutton(d,'Text','OK','Position',[100 50 100 30], ...
                'ButtonPushedFcn',@(~,~)app.confirmBands(d,fld));
        end

        function confirmBands(app,d,fld)
            edges = str2num(fld.Value); %#ok<ST2NM>
            valid = ~isempty(edges) && edges(1)==0 && edges(end)==20000 ...
                    && numel(edges)>=6 && numel(edges)<=11 && all(diff(edges)>0);
            if ~valid
                uialert(d,'Must ascend from 0 to 20000, 5–10 bands','Invalid');
                return;
            end
            app.CustomBands = edges;
            close(d);
        end

        function showCustomGainDialogBox(app)
            nb = numel(app.CustomBands)-1;
            prompts = arrayfun(@(i)sprintf('Gain band %d (dB):',i),1:nb,'uni',0);
            answ = inputdlg(prompts,'Gains',1,repmat({'0'},nb,1));
            if isempty(answ), return; end
            g = cellfun(@str2double,answ);
            if any(isnan(g)), errordlg('Bad gain entry'); return; end
            app.CustomGains = g;
        end

        function fIIR = getIIRFilterType(~)
            fIIR = char(menu('IIR type?','Butterworth','Chebyshev I','Chebyshev II'));
        end

        function fFIR = getFIRFilterType(~)
            fFIR = char(menu('FIR window?','Hamming','Hanning','Blackman'));
        end

        function ord = getFilterOrder(~)
            ord = str2double(inputdlg('Enter filter order:','Order',1,{'5'}));
            if isnan(ord)||ord<=0, ord = 5; end
        end

        function [b,a] = designBandFilter(app,~,sub,Wn,ord)
            if strcmp(app.FilterType,'FIR')
                b = fir1(ord,Wn,lower(sub)); a = 1;
            else
                switch sub
                  case 'Butterworth', [b,a] = butter(ord,Wn);
                  case 'Chebyshev I', [b,a] = cheby1(ord,1,Wn);
                  case 'Chebyshev II',[b,a] = cheby2(ord,20,Wn);
                end
            end
        end

        function applyFilter(app)
            N  = numel(app.y);
            out = zeros(size(app.y));
            for i=1:numel(app.BandGains)
                fl=app.BandEdges(i); fh=app.BandEdges(i+1);
                if fl==0
                    Wn = fh/(app.fs/2);
                else
                    Wn = [fl fh]/(app.fs/2);
                end
                sub = iff(strcmp(app.FilterType,'FIR'),app.FilterTypeFIR,app.FilterTypeIIR);
                [b,a] = app.designBandFilter([],[],sub,Wn,app.FilterOrder);
                out = out + filter(b,a,app.y)*app.BandGains(i);
            end
            app.OutputSignal = out;
            app.plotOnUIAxes();
        end

        function plotOnUIAxes(app)
            N = numel(app.y);
            t_in = (0:N-1)/app.fs;
            t_out= (0:N-1)/app.newfs;
            Xin  = fftshift(fft(app.y)/N);
            Xout = fftshift(fft(app.OutputSignal)/N);
            fin  = linspace(-app.fs/2, app.fs/2, N);
            fout = linspace(-app.newfs/2, app.newfs/2, N);

            use = @(ax) ~isempty(ax)&&isvalid(ax)&&isa(ax,'matlab.ui.control.UIAxes');

            if use(app.InputTimeAxes)
                plot(app.InputTimeAxes,t_in,app.y);
            else figure; subplot(2,2,1); plot(t_in,app.y); end

            if use(app.OutputTimeAxes)
                plot(app.OutputTimeAxes,t_out,app.OutputSignal);
            else subplot(2,2,2); plot(t_out,app.OutputSignal); end

            if use(app.InputFreqAxes)
                plot(app.InputFreqAxes,fin, abs(Xin));
            else subplot(2,2,3); plot(fin,abs(Xin)); end

            if use(app.OutputFreqAxes)
                plot(app.OutputFreqAxes,fout,abs(Xout));
            else subplot(2,2,4); plot(fout,abs(Xout)); end
        end
    end

    %–– App lifecycle ––
    methods (Access = public)
        function app = Audio_Equalizer
            createComponents(app);
            registerApp(app, app.UIFigure);
        end

        function delete(app)
            delete(app.UIFigure);
        end
    end
end
