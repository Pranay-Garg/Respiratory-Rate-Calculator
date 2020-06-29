filename = 'Test/br20.mp4';

raw_color = extract_color_channels(filename);
ppg = ippg_compute(raw_color);

[Sound , soundSR] =  AudioProcessing(filename);
videoSR = 30.0;
xVideo = (1:length(ppg))/videoSR;
xSound = (1:length(Sound))/soundSR;

figure(3)
hold on
plot(xVideo,ppg,'r');
plot(xSound,Sound,'b');
  title('Final PPG vs Sound signals')
  xlabel('time') 
  ylabel('Amplitude')
  legend({'y =PPG','y = Sound Signals'})

[Soundpks, Sloc] = findpeaks ( Sound , 'MINPEAKDISTANCE' ,soundSR/2) ;

BPM = 0;

for i=1: size(Soundpks,1)
    tsound = (Sloc(i))/soundSR;
    Xvideo = ceil(tsound*videoSR);
    if (Soundpks(i) <= ppg(Xvideo))
        BPM = BPM +1;
    end
end

disp('Final RR');
disp(BPM*60*videoSR/length(ppg));
