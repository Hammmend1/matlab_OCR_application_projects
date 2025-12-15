function [y_result] = data_load_process(data_load, max_idx)
arguments
    data_load
    max_idx       % 破坏发生的帧数
end
%% data_load clean

data = data_load(:, 2);

% 2. 数据清洗
valid_max = 15;          %--------------最大载荷值（用于初筛）

data_load_cleaned = data;
idx_abnormal = find(data > valid_max);

for k = 1:length(idx_abnormal)
    idx = idx_abnormal(k);
    val = data(idx);
    
    % A: 尝试修复小数点
    
    candidates = [val/10, val/100, val/1000];
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
        data_load_cleaned(idx) = valid_candidates(best_idx);
        
    else
        % B: 无法修复，标记为缺失
        data_load_cleaned(idx) = NaN;
    end
end

% C:  线性插值填补 NaN
data_load_cleaned = fillmissing(data_load_cleaned, 'linear');

%% fitting
% 2.拟合
data_raw = data_load_cleaned;

%max_idx = 9571;   % 破坏发生的帧数

y_loading = data_raw(1:max_idx);
y_temp    = y_loading; % 临时变量，用于迭代

for k = 1:5
    % 迭代5次
    y_smooth = smoothdata(y_temp, 'rloess', 500);   %window值：500，代表我们要的是“宏观趋势”
    mask = y_temp < y_smooth;
    y_temp(mask) = y_smooth(mask);
end
% 最后再做一次平滑，得到光顺的曲线
trend_curve = smoothdata(y_temp, 'rloess', 500);

% 残差：原始值 - 趋势值
residuals = abs(y_loading - trend_curve);
valid_mask = residuals < 0.5;               % 0.5 容忍度：允许原始点偏离拟合曲线的最大距离 (如 0.5 kN)

num_invalid = sum(~valid_mask);
if num_invalid > 1000
    error('无效点数量过多:%d,程序终止,请重新划定“载荷值ROI”', num_invalid);
end
fprintf('载荷值无效点数量：%d\n', num_invalid);


y_loading_clean = y_loading;
%y_loading_clean(~valid_mask) = NaN;
y_loading_clean(~valid_mask) = trend_curve(~valid_mask);

y_failure_part = data_raw(max_idx+1 : end);
y_result = [y_loading_clean; y_failure_part];

fprintf('congratulation: data_load processing is complete!\n');





