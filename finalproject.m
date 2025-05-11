% Main Script - finalproject.m
clear; clc;

% Step 1: User Input for File, Filter Type, Gain, etc.
[fileName, filePath] = uigetfile({'*.wav'}, 'Select an Audio File');
if fileName == 0
    error('No file selected');
end

% Load the audio file
[audioIn, fs] = audioread(fullfile(filePath, fileName));

% Step 2: Frequency Bands - Standard Mode or Custom Mode
mode = menu('Select Mode', 'Standard Mode', 'Custom Mode');
if mode == 1
    % Standard Mode (Predefined Bands)
    predefinedBands = [0, 200, 500, 800, 1200, 3000, 6000, 12000, 16000, 20000];
else
    % Custom Mode (User-defined Bands)
    numBands = input('Enter the number of bands (between 5 and 10): ');
    if numBands < 5 || numBands > 10
        error('Number of bands must be between 5 and 10.');
    end
    
    % Define the custom bands (first band starts at 0Hz and last band ends at 20kHz)
    customBands = zeros(1, numBands + 1);
    customBands(1) = 0;
    customBands(end) = 20000;
    
    for i = 2:numBands
        customBands(i) = input(['Enter frequency for band ' num2str(i) ' (Hz): ']);
        if customBands(i) <= customBands(i-1)
            error('Bands must be entered in increasing frequency order.');
        end
    end
    predefinedBands = customBands;
end

% Step 3: Gain for each band (input in dB)
gains = input('Enter the gains (in dB) for each frequency band (enter a vector of appropriate length): ');
if length(gains) ~= length(predefinedBands) - 1
    error('The number of gains must match the number of bands.');
end
% Convert dB gains to linear scale
bandGains = db2mag(gains);

% Step 4: Filter Type and Order Selection
filterType = menu('Select Filter Type', 'FIR', 'IIR');
filterOrder = input('Enter the filter order (default is 4): ');
if isempty(filterOrder)
    filterOrder = 4; % Default value
end

% Step 5: Filter Subtype (for IIR Filters)
if filterType == 2 % IIR Filter
    filterSubtype = menu('Select IIR Filter Type', 'Butterworth', 'Chebyshev I', 'Chebyshev II');
end

% Step 6: Apply Filter to each frequency band
filteredSignals = cell(1, length(predefinedBands) - 1);  % To store filtered signals per band

for i = 1:length(predefinedBands) - 1
    % Define the frequency range for the current band
    Wn = [predefinedBands(i) predefinedBands(i+1)] / (fs / 2);  % Normalize by fs/2
    
    % Design the filter based on selected type and subtype
    if filterType == 1
        % FIR filter design (no filter subtype for FIR)
        [b, a] = designBandFilter('FIR', '', Wn, filterOrder); % Empty string for FIR
    else
        % IIR filter design (using filterSubtype)
        if filterSubtype == 1
            [b, a] = designBandFilter('IIR', 'Butterworth', Wn, filterOrder);
        elseif filterSubtype == 2
            [b, a] = designBandFilter('IIR', 'Chebyshev I', Wn, filterOrder);
        elseif filterSubtype == 3
            [b, a] = designBandFilter('IIR', 'Chebyshev II', Wn, filterOrder);
        end
    end

    % Filter the audio signal for the current band
    filteredSignals{i} = bandGains(i) * filter(b, a, audioIn);
    
    % Step 7: Analyze the Filter and Plot (Magnitude, Phase, Impulse, Step, Poles/Zeros)
    figure;
    % Magnitude and Phase Response
    subplot(2, 2, 1);
    [h, f] = freqz(b, a, 1024, fs);
    plot(f, abs(h));
    title('Magnitude Response');
    
    subplot(2, 2, 2);
    plot(f, angle(h));
    title('Phase Response');
    
    % Impulse and Step Response
    subplot(2, 2, 3);
    impulse = [1; zeros(99, 1)];
    response = filter(b, a, impulse);
    stem(response);
    title('Impulse Response');
    
    subplot(2, 2, 4);
    step = ones(100, 1);
    response = filter(b, a, step);
    plot(response);
    title('Step Response');
    
    % Poles and Zeros Plot
    figure;
    zplane(b, a);
    title('Poles and Zeros');
    
    % Step 8: Export the Filtered Signals for Time and Frequency Domain Comparison
    figure;
    % Time Domain Plot
    subplot(3, 1, 1);
    plot((1:length(filteredSignals{i})) / fs, filteredSignals{i});
    title(['Filtered Signal (Time Domain) - Band ' num2str(i)]);
    xlabel('Time (s)');
    ylabel('Amplitude');
    
    % Frequency Domain Plot
    subplot(3, 1, 2);
    fmag = abs(fftshift(fft(filteredSignals{i})) / fs);
    f_xaxis = linspace(-fs / 2, fs / 2, length(fmag));
    plot(f_xaxis, fmag);
    title('Magnitude Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    
    % Phase Plot
    subplot(3, 1, 3);
    phase = angle(fftshift(fft(filteredSignals{i})));
    plot(f_xaxis, phase);
    title('Phase Spectrum');
    xlabel('Frequency (Hz)');
    ylabel('Phase (radians)');
end

% Step 9: Create Composite Signal (Sum of all band-filtered signals)
compositeSignal = sum(cat(2, filteredSignals{:}), 2);

% Step 10: Plot the Composite Signal in Time and Frequency Domain
figure;
subplot(2, 1, 1);
plot((1:length(compositeSignal)) / fs, compositeSignal);
title('Composite Signal (Time Domain)');
xlabel('Time (s)');
ylabel('Amplitude');

subplot(2, 1, 2);
compositeFreq = abs(fftshift(fft(compositeSignal)) / fs);
f_xaxis = linspace(-fs / 2, fs / 2, length(compositeFreq));
plot(f_xaxis, compositeFreq);
title('Composite Signal (Frequency Domain)');
xlabel('Frequency (Hz)');
ylabel('Magnitude');

% Step 11: Save and Export Final Audio File
outputFileName = input('Enter the output file name (e.g., "output.wav"): ', 's');
audiowrite(outputFileName, compositeSignal, fs);

disp('Audio processing complete!');
