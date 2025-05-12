%% audio_equalizer.m
% Audio Equalizer supporting Standard/Custom bands, FIR/IIR filters,
% user-defined orders, window/type selection, full analysis export,
% time/freq plots, composite reconstruction, resampling, saving & playback.

close all; clc; clear variables;
fprintf('\n*** WELCOME TO AUDIO EQUALIZER (CMD)***\n\n');

%% 1) INPUTS

% 1) Wave file name
[filename, pathname] = uigetfile({'*.wav','Wave Files (*.wav)'}, 'Select a WAV file');
if isequal(filename,0)
    error('No file selected. Exiting.');
end
filePath = fullfile(pathname, filename);
[y, Fs]   = audioread(filePath);

% 2) Band gains
% 3) Filter type & order (FIR/IIR)
% 4) Output sample rate
mode  = menu('1) Band-definition mode:', 'Standard (9 bands)', 'Custom (5–10 bands)');

if mode == 1
    % 1a) Standard 9 bands
    bandEdges = [0 200 500 800 1200 3000 6000 12000 16000 20000];
else
    % 1b) Custom 5–10 bands
    N = input('   Enter number of bands (5–10): ');
    while isempty(N) || N<5 || N>10
        N = input('   Invalid. Enter number of bands (5–10): ');
    end
    bandEdges = zeros(1, N+1);
    bandEdges(1) = 0;
    for k = 2:N
        bandEdges(k) = input(sprintf('   Edge freq for band %d (Hz): ', k));
        while bandEdges(k) <= bandEdges(k-1) || bandEdges(k) >= 20000
            bandEdges(k) = input('   Invalid. Enter > previous and <20000: ');
        end
    end
    bandEdges(end) = 20000;
end
B = length(bandEdges)-1;

% Gains for each band
G = zeros(1,B);
for k = 1:B
    dB   = input(sprintf('   Gain for band %d in dB: ', k));
    G(k) = 10^(dB/20);
end

% Filter class & parameters
type    = menu('2) Filter class:', 'IIR', 'FIR');
if type==1
    iirType  = menu('   IIR type:', 'Butterworth','Chebyshev I','Chebyshev II');
    defaultN = 4;
    n        = input(sprintf('   Enter IIR order (default %d): ', defaultN));
    if isempty(n), n=defaultN; end
else
    winType  = menu('   FIR window:', 'Hamming','Hanning','Blackman');
    defaultN = 25;
    n        = input(sprintf('   Enter FIR order (default %d): ', defaultN));
    if isempty(n), n=defaultN; end
end

% Output sample rate
fouts = input('3) Enter output sample rate (Hz): ');

%% 2–3) DESIGN, ANALYZE & EXPORT

% Preallocate struct array
emptyF = struct('b',[],'a',[],'band',[],'order',[],'w',[],'mag',[],...
                'phase',[],'impResp',[],'t_imp',[],'stepResp',[],'t_step',[],...
                'zeros',[],'poles',[]);
filters = repmat(emptyF,1,B);

% Loop over bands
for k = 1:B
    f1 = bandEdges(k);
    f2 = bandEdges(k+1);
    % normalize to Nyquist
    if f1==0
        Wn = f2/(Fs/2);
    else
        Wn = [f1 f2]/(Fs/2);
    end
    if any(Wn<=0)||any(Wn>=1)
        error('Band %d edges [%g %g] Hz → invalid Wn [%g %g]',k,f1,f2,min(Wn),max(Wn));
    end

    % design filter
    if type==1  % IIR
        switch iirType
            case 1, [b,a]=butter(n,Wn);
            case 2, [b,a]=cheby1(n,1,Wn);
            case 3, [b,a]=cheby2(n,20,Wn);
        end
    else        % FIR
        switch winType
            case 1, w=hamming(n+1);
            case 2, w=hann(n+1);
            case 3, w=blackman(n+1);
        end
        if f1==0
            b=fir1(n,Wn,w);
        elseif f2==(Fs/2)
            b=fir1(n,Wn,'high',w);
        else
            b=fir1(n,Wn,w);
        end
        a=1;
    end

    % freq response
    [H, wv]      = freqz(b,a,1024,Fs);
    mag          = abs(H);
    phase        = angle(H);
    % impulse & step
    L            = 512;
    [impResp,t_imp] = impz(b,a,L,Fs);
    [stepResp,t_step] = stepz(b,a,L,Fs);
    % zeros & poles
    [z,p,~]      = tf2zpk(b,a);

    % store
    filters(k) = struct('b',b,'a',a,'band',[f1 f2],'order',n, ...
                        'w',wv,'mag',mag,'phase',phase, ...
                        'impResp',impResp,'t_imp',t_imp, ...
                        'stepResp',stepResp,'t_step',t_step, ...
                        'zeros',z,'poles',p);
end

% export analysis data
save('filter_analysis.mat','filters');
fprintf('\n4) Analysis data saved to filter_analysis.mat\n');

%% 4–7) PLOT, FILTER, GAIN, COMPOSITE & COMPARE

% Plot each filter’s responses
figure('Name','Magnitude Responses');
for k=1:B
    subplot(B,1,k), plot(filters(k).w,filters(k).mag), grid on
    title(sprintf('Band %d: %d-%d Hz (Mag)',k,filters(k).band));
end
figure('Name','Phase Responses');
for k=1:B
    subplot(B,1,k), plot(filters(k).w,filters(k).phase), grid on
    title(sprintf('Band %d: %d-%d Hz (Phase)',k,filters(k).band));
end
figure('Name','Impulse & Step Responses');
for k=1:B
    subplot(B,2,2*k-1), plot(filters(k).t_imp,filters(k).impResp), grid on
      title(sprintf('Band %d Impulse',k));
    subplot(B,2,2*k),   plot(filters(k).t_step,filters(k).stepResp), grid on
      title(sprintf('Band %d Step',k));
end
figure('Name','Poles & Zeros');
for k=1:B
    subplot(ceil(B/3),3,k), zplane(filters(k).zeros,filters(k).poles), grid on
    title(sprintf('Band %d P/Z',k));
end

% filter + gain + composite
xt = zeros(size(y));
for k=1:B
    xk = filter(filters(k).b,filters(k).a,y);
    xt = xt + G(k)*xk;
end

% time & freq comparisons
figure('Name','Time Domain Comparison');
subplot(2,1,1), plot(xt),   title('Composite'), grid on
subplot(2,1,2), plot(y),    title('Original'),  grid on
figure('Name','Frequency Domain Comparison');
FX = fftshift(abs(fft(xt))); FY = fftshift(abs(fft(y)));
subplot(2,1,1), plot(FX),   title('Composite Freq'), grid on
subplot(2,1,2), plot(FY),   title('Original Freq'),  grid on

%% 8) PLAYBACK, SAVE & EXPORT FIGURES/CSV

% resample & normalize
xt_res = resample(xt,fouts,Fs);
xt_res = xt_res/max(abs(xt_res));

% save and play
audiowrite('equalized_output.wav',xt_res,fouts);
fprintf('5) Equalized audio saved to equalized_output.wav (Fs=%d Hz)\n',fouts);
sound(xt_res,fouts);

% create exports folder
exportDir = fullfile(pwd,'exports');
if ~exist(exportDir,'dir'), mkdir(exportDir); end

% export each filter’s data to CSV
for k=1:B
    fe   = filters(k).band;
    base = fullfile(exportDir,sprintf('band%02d_%d-%dHz',k,fe(1),fe(2)));
    csvwrite([base '_freqresp.csv'], [filters(k).w,filters(k).mag,filters(k).phase]);
    csvwrite([base '_impulse.csv'],  [filters(k).t_imp,filters(k).impResp]);
    csvwrite([base '_step.csv'],     [filters(k).t_step,filters(k).stepResp]);
    csvwrite([base '_poles.csv'],    filters(k).poles(:));
    csvwrite([base '_zeros.csv'],    filters(k).zeros(:));
end

% save all open figures
figs = findall(groot,'Type','figure');
for i=1:numel(figs)
    fname = regexprep(figs(i).Name,'[^a-zA-Z0-9]','_');
    saveas(figs(i), fullfile(exportDir,[fname '.png']));
end

fprintf('6) All CSVs & figures saved under:\n   %s\n\n',exportDir);
fprintf('*** THANK YOU ***\n');
