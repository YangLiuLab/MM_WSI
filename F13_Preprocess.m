function imgPre = F13_Preprocess(img_stack)

% filter image
H = fspecial3('average',[3,3,3]);
img_ave = imfilter(img_stack, H, 'replicate');

% sum the stack
img_sum = sum(img_ave,3);

% normalize
imgNorm = img_sum ./ max(img_sum(:));

% calculate threshold
T = graythresh(imgNorm)

% generate mask
BW = imbinarize(imgNorm, T);
mask = ones(size(imgNorm)) - BW;

% get background
bg = mask.*img_sum;

% background histogram
bg(bg == 0) = [];
h = histogram(bg(:));
histValue = h.Values;
histValue(1) = 0;

% smooth the histogram
histSmooth = smoothdata(histValue,'gaussian',15);
t = h.BinEdges(2:end);

% find the first peak and calculate the background level
[pks,locs] = findpeaks(histSmooth);
dim = size(img_stack);
thr = h.BinEdges(locs(1)+1) / dim(3);

% remove background
imgPre = single(img_stack - thr);
imgPre(imgPre<0) = 0;


end