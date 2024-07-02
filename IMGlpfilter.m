function IMGfilt=IMGlpfilter(IMG,size,sigma)
% Uses a low pass filter to specificially select for the noise/background
% in the images. This noise/background must then be removed from the
% original image to produce the clean/filtered image.
% Currently using a gaussian filter with size and standard deviation
if nargin<2
    sigma=0.5;
    size=3;
elseif nargin<3
    sigma=0.5;
end

if size==0 || sigma==0
    IMGfilt=IMG; % just pass it through to make it easier on the front end
else
    h=fspecial('gaussian',size,sigma);
    IMGnoise=imfilter(IMG,h,'replicate');
    IMGfilt=IMG-IMGnoise;
    IMGfilt=abs(IMGfilt);
end