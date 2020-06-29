%funcion to extract PPG signal from the raw using the green signal
function PPGfinal = ippg_compute(Color_channels)
  
  SamplingRate= 30.0; %30fps video    
  dataLength = length(Color_channels);
  xValues = (1:length(Color_channels))/SamplingRate;
  
  PPG_before = Color_channels(2, :);
  
  figure(1)
  subplot(4,1,1);
  plot(xValues,PPG_before);
  title('PPG extraction from green channel before detrending')
  xlabel('time') 
  ylabel('Amplitude') 
  
  % detrend signals using Mean-Centering-And-Scaling technique [1]
  % (unconditionally since it's often a required step and it isn't harmful)
 
  n = conv2(ones(3, dataLength), ones(1, SamplingRate), 'same');
  meanIntensity = conv2(Color_channels, ones(1, SamplingRate), 'same')./n;
  colorSignal = (Color_channels - meanIntensity)./meanIntensity;
  
  %ppg extraction using green channel
  PPG = colorSignal(2, :);
  subplot(4,1,2);
  plot(xValues,PPG);
  title('PPG extraction from green channel after detrending')
  xlabel('time') 
  ylabel('Amplitude') 
  %applying 3rd order Butterworth filter
  % 0.05 to 2 hz bandpass filter
  RespiratoryBand = [0.15 1]*2/SamplingRate;
  filterOrder = 127;
   if (filterOrder > 11) %use FIR filter    
    b = fir1(filterOrder, RespiratoryBand);  
    a = 1;
   else
    [b , a] = butter(3 , RespiratoryBand);
   end
   
  %Zero-phase digital filtering
  PPGfinal = filter(b,a,PPG);
  subplot(4,1,3);
  plot(xValues,PPGfinal);
  title('Application of bandpass filter')
  xlabel('time') 
  ylabel('Amplitude') 
  %p^(t) = (p(t) - mean(t))/sigma(t) 
  % make ppg signal zero-mean
  averagingWindow = 2*SamplingRate;
  refinedPPG = PPGfinal - movmean(PPGfinal, averagingWindow);
  
  %dividing by sigma(t) i.e. standard deviation = 1
  stdValues = std_sliding_win(refinedPPG, averagingWindow);
  indices = find(stdValues < abs(refinedPPG)/3); 
  stdValues(indices) = abs(refinedPPG(indices))/3;
  refinedPPG = refinedPPG./stdValues;
  subplot(4,1,4);
  plot(xValues,refinedPPG);
  title('Normalized signal')
  xlabel('time') 
  ylabel('Amplitude') 
  
  %correcting sign based on fact
  refinedPPG = refinedPPG*correct_sign(refinedPPG);
  refinedPPG = -refinedPPG;
  [pks] = findpeaks(refinedPPG,'MinPeakDistance',50);
  PPGfinal = refinedPPG;
  disp('Video processed BPM ');
  disp(length(pks)*60*30/dataLength);
  
end


%Computing moving standard deviation
function std_X = std_sliding_win(x, w)
    % element count in each window
    n = conv(ones(1, length(x)), ones(1, w), 'same');
    
    s = conv(x, ones(1, w), 'same');
    q = x.^ 2;    
    q = conv(q, ones(1, w), 'same');
    std_X = sqrt(abs((q - s.^2 ./ n) ./ (n - 1)));
end

% recovers the correct sign of iPPG signal
% using the fact that in PPG throughs have higher amplitudes than peaks
function ppgSign = correct_sign(ppg)
  
  % make the signal zero-mean and normalize its amplitude
  minValue = min(ppg);
  maxValue = max(ppg); 
  meanValue = mean(ppg);   
  ppg = (ppg - meanValue)/(maxValue - minValue);

  ppg(ppg == 0) = 0.00001; % get rid of exact zeros
  
  %change in sign of signal i.e.where signal crosses 0
  signChange = diff(sign(ppg));
  %negetive to  positive
  indexUp = find(signChange > 0);
  %positive to negative
  indexDown = find(signChange < 0);
  
  if (indexUp(1) > indexDown(1))  % for consistency we start with positive segment
    indexUp = [1, indexUp]; % thus we add first segment if necessary
  end  
  if (indexUp(end) < indexDown(end))  % we also end with positive segment
    indexDown = indexDown(1:end-1); % thus we skip last segment if necessary
  end    
  nSegment = min(length(indexUp), length(indexDown));
  sumMax = 0;
  sumMin = 0;
  for iSegment = 1:nSegment
    %calculating peak
    sumMax = sumMax + max(ppg(indexUp(iSegment):indexDown(iSegment)) );
    %calculating trough
    sumMin = sumMin - min(ppg(indexDown(iSegment):indexUp(iSegment+1))) ;    
  end
  if (sumMax > sumMin) % if peaks have higher amplitudes than throughs
    ppgSign = -1;      % signal shold be inverted  
  else
    ppgSign = 1;
  end  
end
