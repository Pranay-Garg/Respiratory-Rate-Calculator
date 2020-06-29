%function to extract raw colour channels from every frame of the video
function Color_channels = extract_color_channels( filename )

%read the input
video_input = VideoReader(filename);
Total_frames = ceil(video_input.FrameRate*video_input.Duration);

%intialize color_channel array

Color_channels = zeros(3,Total_frames);


%intialize detected face Rectangle
face_width = video_input.Width;
face_height = video_input.Height;
faceRect = [1, 1, face_width, face_height];

%For every frame in the video
for iframe = 1:Total_frames
    
    %read every frame
    if(~hasFrame(video_input))
        break
    end
    cur_Frame = readFrame(video_input);
    
    %detect Face of the user 
    if iframe == 1 
        faceDetector = vision.CascadeObjectDetector;
        faceRect = faceDetector(cur_Frame);
    end
    
    %crop the detected face
    crop_Image = imcrop(cur_Frame, [faceRect(1:2), faceRect(3:4)-1]);
   
    currentROI = ROI_refinement(crop_Image); % filter out bad pixels
    
    %show image
    % show the video frames
    maskedImage = crop_Image;
    for iChannel = 1:3
        colorChannel = maskedImage(:,:,iChannel);
        colorChannel(~currentROI) = 1;
        maskedImage(:,:,iChannel) = colorChannel;
    end     
    imshow(maskedImage);
    title(['Time: ' num2str(iframe/video_input.FrameRate) ' / ' num2str(video_input.Duration)]);
    drawnow update
    
    % compute the average color values over the ROI 
    for iChannel = 1:3
        colorChannel = crop_Image(:,:,iChannel);
        Color_channels(iChannel,iframe) =  mean(mean(colorChannel(currentROI)));
    end
    
    
end    

end

% function for filtering bad pixels (non-skin or corrupted with artefacts)
function currentROI = ROI_refinement(croppedImage)
    [heightROI,widthROI,~] = size(croppedImage);
    currentROI = ones(heightROI,widthROI);
    
    % HSV filtering: pixels with hue, saturation or value 
    % outside of the specified range are discarded
    hsvFrame = rgb2hsv(croppedImage);        
    hsvMin = [0.00, 0.09, 0.34];
    hsvMax = [0.13, 0.52, 1.00];
    for iChannel = 1:3
        hsvMask = roicolor(hsvFrame(:,:,iChannel), hsvMin(iChannel), hsvMax(iChannel));    
        currentROI = currentROI & hsvMask;
    end            

    
    % std thresholding: pixels with color channels too far from the mean
    % are discarded
    stdCoef =  1.5;
    stdMask = currentROI;
    for iChannel = 1:3
        colorChannel = croppedImage(:,:,iChannel);
        channelMean = mean(mean(colorChannel(currentROI)));
        channelStd  = std2(colorChannel(currentROI));
        minChannelValue = channelMean - stdCoef*channelStd; 
        maxChannelValue = channelMean + stdCoef*channelStd;
        % we do not modify here currentROI since we need it to compute std corretly
        stdMask = stdMask & roicolor(colorChannel, minChannelValue, maxChannelValue);                
    end 
    currentROI = currentROI & stdMask;
   
end


