function [x_result] = data_dis_process(data_dis, uping_idx, max_idx)
arguments
    data_dis 
    uping_idx
    max_idx
end
%% data_dis clean
  
data = data_dis(:,2);

% 1. 数据清洗
valid_max = 3;       % ---------最大位移值

data_dis_cleaned = data;
idx_abnormal = find(data > valid_max); % 找出所有明显超出范围的点

for k = 1:length(idx_abnormal)
    idx = idx_abnormal(k);
    val = data(idx);
    
    % A: 尝试修复小数点
    
    candidates = [val/1000, val/10000];
    valid_candidates = candidates(candidates >= 0 & candidates <= valid_max);
    
    if ~isempty(valid_candidates)
        % 计算局部中值作为参考
        window_indices = max(1, idx-5) : min(length(data), idx+5);
        
        % 确保只计算非异常邻居的中值
        valid_neighbors = data(window_indices);
        local_median = median(valid_neighbors(valid_neighbors <= valid_max));
        
        if isnan(local_median) || isempty(local_median)
            ref_val = data(max(1, idx-1)); % 回退到上一时刻的值
        else
            ref_val = local_median;
        end
        
        % 找最接近 ref_val 的候选值
        [~, best_idx] = min(abs(valid_candidates - ref_val));
        data_dis_cleaned(idx) = valid_candidates(best_idx);
        
    else
        % B: 无法修复，标记为缺失
        data_dis_cleaned(idx) = NaN;
    end
end

% C: 填补 NaN
data_dis_cleaned = fillmissing(data_dis_cleaned, 'linear');

%% fitting
% 2.拟合
data_raw = data_dis_cleaned;

% uping_idx = 4711;
% max_idx   = 9571;
% tolerance = 0.5;

x_1 = data_raw(1:uping_idx-1);
x_2 = data_raw(uping_idx:max_idx);
x_3 = data_raw(max_idx+1:end);

% x_1 procrssing
valid_mask = x_1 <0.1;
x_1_clean = x_1;
x_1_clean(~valid_mask) = NaN;

% x_2 processing
uping_num = (1:length(x_2))';
fitted_model = fit(uping_num, x_2, 'poly1');
x2_curve = fitted_model(uping_num);

x2_residuals = abs(x_2 - x2_curve);
valid_mask = x2_residuals < 0.05; % 上升段浮动范围限制（0.05-0.1）

num_invalid = sum(~valid_mask);
if num_invalid > 200
    error('无效点数量过多:%d,程序终止,请重新划定“位移值ROI”', num_invalid);
end
fprintf('位移值无效点数量：%d\n', num_invalid);

x_2_clean = x_2;
x_2_clean(~valid_mask) = NaN;

% y_3 without process
x_result = [x_1_clean; x_2_clean; x_3];
x_result = fillmissing(x_result, 'linear');

fprintf('congratulation: data_dis processing is complete!\n');
%% plot
% figure
% plot(x_result);




