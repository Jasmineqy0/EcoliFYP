% read image
img = rgb2gray(imread('image/E.Coli-1.jpg')); % for tophat
% img = rgb2gray(imread('image/E.Coli-2.jpg'));
% img = rgb2gray(imread('image/E.Coli+PtCo-1.jpg'));
% img = rgb2gray(imread('image/E.Coli+PtCo-2.jpg'));
% img = rgb2gray(imread('image/LB-1.jpg'));
% img = rgb2gray(imread('image/LB-2.jpg'));
% img = rgb2gray(imread('image/LB+PtCo-1.jpg'));
% img = rgb2gray(imread('image/LB+PtCo-2.jpg'));


% img = imread('image/E.coli-1.jpg'); % for gamma
figure, imshow(img);

% % gamma filtering to correct illumination
% [h,s,v]=rgb2hsv(img); 
% HSIZE= min(size(img,1),size(img,2));
% q=sqrt(2);
% SIGMA1=15;
% SIGMA2=80;
% SIGMA3=250;
% F1 = fspecial('gaussian',HSIZE,SIGMA1/q);
% F2 = fspecial('gaussian',HSIZE,SIGMA2/q);
% F3 = fspecial('gaussian',HSIZE,SIGMA3/q);
% gaus1= imfilter(v, F1, 'replicate');
% gaus2= imfilter(v, F2, 'replicate');
% gaus3= imfilter(v, F3, 'replicate');
% gaus=(gaus1+gaus2+gaus3)/3;
% m=mean(gaus(:));
% [w,height]=size(v);
% out = zeros(size(v));
% gama=power(0.5,((m-gaus)/m));
% out=(power(v,gama));
% img=rgb2gray(hsv2rgb(h,s,out)); 
% imshow(img);

% top hat filtering
se = strel('disk',90);
img = imtophat(img, se);

% get the region within disk
[center, radius] = diskSeg(img);
roi = drawcircle('Center', center, 'Radius', radius);
mask = createMask(roi);
img(~mask) = 0;
rect = [center(1)-radius, center(2)-radius, radius*2, radius*2];
img = imcrop(img, rect);
imshow(img);


% % denoising
% img_ = wiener2(img, [8 8]);
% % gaussian filter
% img_ = imgaussfilt(img_,0.75);
% % open operation
% SE = strel('disk',7);
% img_ = imopen(img_,SE);
% % increase contrast
% img_ = adapthisteq(img_);
% % imshow(img_);


img_ = preprocess(img);


% % level = graythresh(img_);
% % level = adaptthresh(img_);

% % thresh of gamma
% [f, xi] = ksdensity(img_(:), 0:0.01:1);
% [~, loc] = findpeaks(f, 0:0.01:1);
% level = (loc(2)+loc(3)) * 0.42;

% tophat filtering thresh
[f,xi] = ksdensity(img_(:), 0:1:256);
[~, loc] = findpeaks(f, 0:1:256);
level = (loc(2)+loc(3)) / 255 * 0.35; 
bw = imbinarize(img_,level);
imshow(bw);

% [rows,cols] = size(img_);
% blockSizeR = 100;
% blockSizeC = 100;
% wholeRows = floor(rows / blockSizeR);
% blockVecR = [blockSizeR * ones(1, wholeRows), rem(rows, blockSizeR)];
% wholeCols = floor(cols / blockSizeC);
% blockVecC = [blockSizeC * ones(1, wholeCols), rem(cols, blockSizeC)];
% ca = mat2cell(img_, blockVecR, blockVecC);
% [numCellR, numCellC] = size(ca);
% for r = 1 : numCellR
%     for c = 1 : numCellC
%         block = ca{r,c};
%         level = graythresh(block);
%         if level > 0.15
%             ca{r,c} = imbinarize(block, level);
%         else
%             ca{r,c} = false(size(block));
%         end
%     end
% end
% img_ = cell2mat(ca);
% figure, imshow(img_);

D = bwdist(~bw);
mask_em = imextendedmax(D, 0.9);
% figure, imshowpair(bw, mask_em, 'blend')

D = -D;
img_mod = imimposemin(D, mask_em);
L = watershed(img_mod);
bw2 = bw;
bw2(L==0) = 0;
figure,imshow(bw2);

% D = -bwdist(~bw);
% figure, imshow(D,[]);
% % Ld = watershed(D);
% % figure, imshow(label2rgb(Ld));
% % 
% % bw2 = bw;
% % bw2(Ld == 0) = 0;
% % figure, imshow(bw2);
% 
% mask = imextendedmin(D,1);
% figure, imshowpair(bw,mask,'blend')
% D2 = imimposemin(D,mask);
% Ld2 = watershed(D2);
% bw3 = bw;
% bw3(Ld2 == 0) = 0;
% figure, imshow(bw3);









