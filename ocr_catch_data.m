%clc; clear; close all;
addpath('./functions')

videoPath = 'D:\load_data_redio\ballshape1125.mp4';
% [Slice, roi] = extract_roi_from_video(videoPath);
% roi = [1,1,roi(3)-1,roi(4)-1];

%% 位移值识别 ROI_dis  选择位移ROI时，尽可能扩大范围，但不要包含右边的绿色指示灯
[Slice, ~] = extract_roi_from_video(videoPath);

num = size(Slice,1);
data_dis = zeros(num, 3);

h = waitbar(0, 'doing...', 'Name', 'data_dis OCR process');
for i = 1:num
    I = Slice{i};

    gray = rgb2gray(I);
    
    dis_T_min = 220;
    dis_T_max = 255;

    bw = (gray >= dis_T_min) & (gray <= dis_T_max);

    results_dis = ocr(~bw,Model="seven-segment",LayoutAnalysis="word");

    if ~isempty(results_dis.Words) && numel(results_dis.Words) == 1
        data_dis(i,:) = [i, str2double(results_dis.Words{1}), results_dis.WordConfidences(1)];
    else
        data_dis(i,:) = [i, NaN, NaN];
    end

    progress = i / num;
    waitbar(progress, h, sprintf('%d/%d...', i, num));
end

close(h); 

%% 荷载值识别 ROI_load
[Slice, ~] = extract_roi_from_video(videoPath);

num = size(Slice,1);
data_load = zeros(num, 3);

h = waitbar(0, 'doing...', 'Name', 'data_load OCR process');
for i = 1:num
    I = Slice{i};

    gray = rgb2gray(I);

    load_T_min = 140;
    load_T_max = 255;

    bw = (gray >= load_T_min) & (gray <= load_T_max);

    results_load = ocr(~bw, 'CharacterSet', '0123456789.', 'TextLayout', 'Block');

    if ~isempty(results_load.Words) && numel(results_load.Words) == 1
        data_load(i,:) = [i, str2double(results_load.Words{1}), results_load.WordConfidences(1)];
    else
        data_load(i,:) = [i, NaN, NaN];
    end

    progress = i / num;
    waitbar(progress, h, sprintf('%d/%d...', i, num));
end

close(h); 

%% 合并数据，作图
addpath('./functions')

%设置范围
uping_idx = 4710; % 载荷快速上升的帧数
max_idx   = 9571; % 破坏发生的帧数

x_result = data_dis_process(data_dis, uping_idx, max_idx);
y_result = data_load_process(data_load, max_idx);  

figure
scatter(x_result,y_result);
hold on;
plot(x_result,y_result);





























