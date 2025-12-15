function [roi_frames,rect] = extract_roi_from_video(videoPath)
    
    v = VideoReader(videoPath);
    
    % 2. 读取第一帧用于交互式选择 ROI
    firstFrame = readFrame(v);
    
    figure;
    imshow(firstFrame);
    title('ROI');
    
    % 使用 drawrectangle (较新版本) 或 getrect (旧版本兼容性好)
    % 这里使用 imrect/getrect 风格，兼容性更强
    rect = getrect; 
    rect = round(rect);
    % rect 的格式为 [xmin, ymin, width, height]
    
    close(gcf); % 关闭选择窗口
    
    disp(['选定的区域坐标: ', num2str(rect)]);
    
    % 3. 初始化 Cell 数组
    % 尝试获取总帧数以进行预分配（提高速度）
    % 注意：某些视频格式可能无法直接读取 NumFrames
    if isprop(v, 'NumFrames') && v.NumFrames > 0
        numFrames = v.NumFrames;
        roi_frames = cell(numFrames, 1);
    else
        roi_frames = {}; % 如果无法获取帧数，初始化为空
    end
    
    % 4. 重置视频时间并开始循环提取
    v.CurrentTime = 0; % 回到视频开头
    k = 1;
    
    h = waitbar(0, 'extracting ROI...');
    
    while hasFrame(v)
        % 读取当前帧
        frame = readFrame(v);
        
        % 根据 ROI 裁剪图片
        % imcrop 自动处理 rect 边界超出图片的情况
        croppedImg = imcrop(frame, rect);
        
        % 存入 cell
        roi_frames{k, 1} = croppedImg;
        
        % 更新进度条 (如果知道总帧数)
        if exist('numFrames', 'var')
             waitbar(k/numFrames, h);
        end
        
        k = k + 1;
    end
    
    close(h);
    disp(['共提取: ', num2str(k-1), ' 帧。']);
 
end