function [Sound , soundSR]= AudioProcessing(filename)

%audio recorded using https://play.google.com/store/apps/details?id=com.media.bestrecorder.audiorecorder
%read the input audio file
[input, SampleRate] = audioread(filename);
% disp(length(input));
% disp(SampleRate);
%As if Sampling rate is greater than 10khz more processing is required
%So we downsample the input audio
[~ ,col] = size(input);

if col >1
    input = input(:,2);
end

if SampleRate > 10000
        down_input = downsample(input, 100);    %by a factor of 100
        SampleRate = SampleRate/100;
elseif(( SampleRate>1000) && (SampleRate<10000))
        down_input = downsample(input, 10);     %by a factor of 10
        SampleRate = SampleRate/10;
end

input = down_input;
%Apply a low pass filter to absolute of the input
%3rd order Butterworth used as if provides flat pass and stop band
% a,b transfer func. coefficients
% 2nd aurgument is the cut-off frequency
[ a , b ] = butter(3, 1/(SampleRate/2.15), 'low');

%applying the filter to absolute of input
input_temp = input;
input_abs= abs(input_temp) ;
Outline_Signal = filter(a,b,input_abs);


Total_time = length(input) / (SampleRate);
Time_axis = ( 0 : length(input)-1 )/(SampleRate);
% disp(length(input));
% disp(SampleRate);
figure(2)
subplot(3,1,1);
plot(Time_axis,input_abs);
title('Mod of sound recorded')
xlabel('time') 
ylabel('Amplitude') 

subplot(3,1,2);
plot(Time_axis,Outline_Signal);
 title('Application of low pass filter')
  xlabel('time') 
  ylabel('Amplitude') 
hold on;
%findpeaks ( Outline_Signal , 'MINPEAKDISTANCE' ,SampleRate/2) ;
hold off;
%find peaks in Outline Signal
%MINPEAKDISTANCE = SampleRate/2 as assumed a person would take 2 breaths in a second  
[ pks , loc]=findpeaks ( Outline_Signal , 'MINPEAKDISTANCE' ,SampleRate/2) ;



%Normalize the Ouline function by dividing by highest peak value
highest_peak = pks(1);
for i=1: size(pks,1)
    if highest_peak < pks(i)
        highest_peak = pks(i);
    end
end

Norm_Outline_Signal = Outline_Signal/highest_peak;
subplot(3,1,3);
plot(Time_axis,Norm_Outline_Signal);
 title('Normalized signal')
  xlabel('time') 
  ylabel('Amplitude') 
hold on;
findpeaks ( Norm_Outline_Signal , 'MINPEAKDISTANCE' ,SampleRate/2) ;
hold off;


[Norm_pks, loc] = findpeaks ( Norm_Outline_Signal , 'MINPEAKDISTANCE' ,SampleRate/2) ;

%WE will calculate only exhale peaks
%It has been obsereved from experiment 
%that peak value of exhale is atleast 0.1 in norm_pks
total_breaths = 0;
for i=1: size(Norm_pks,1)
    if Norm_pks(i) >= 0.1
        total_breaths =total_breaths+1;
    end
end


%total_breaths in Total time Hence RR or Breaths per min
BPM = (total_breaths*60)/(Total_time);


%Assumption whole time the person breaths with around same(not exaclty) rate
%BPM does not abruptly picks up
%For higher BPM we calculate the exhale amplitudes
%for lower BPM we calculate both exhale and inhale amplitudes
if BPM <= 25
   BPM = (length(Norm_pks)*30)/Total_time;
end

disp('Audio processed BPM');
disp(BPM);
soundSR = SampleRate;
Sound = Norm_Outline_Signal;
end
