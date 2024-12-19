%  QQQQQQ     目的：处理从串口拿到的IMU原始数据
% QQ    QQ    数据特点：1以AA FF F2 18为帧头，最后有两位校验码，hex格式
% QQ    QQ             2中间24位分为六组，为IMU六轴数据
% QQ   QQQ             3※(最关键的问题）每一组数据都是小端序
%  QQQQQQQQ   最终效果：生成六轴数据的csv文件以供后续处理
%          QQ 日期： 2024-12      制作人：水森usagi
%% 1、将txt文件去除空格保存

inputFileName = '2024-12-18-imu088.txt'; % 要读取的文件名
outputFileName = 'output.txt'; % 处理后要保存的文件名

% 读取文件
fileID = fopen(inputFileName, 'r'); % 打开文件进行读取
fileContent = fread(fileID, '*char')'; % 读取文件内容
fclose(fileID); % 关闭文件

% 去除空格
fileContent = strrep(fileContent, ' ', ''); % 替换空格为空字符串

% 重新存储文件
fileID = fopen(outputFileName, 'w'); % 打开文件进行写入
fwrite(fileID, fileContent, 'char'); % 写入处理后的内容
fclose(fileID); % 关闭文件

%% 2、分割数据帧，以帧头为标志   
filename = 'output.txt';

% 定义帧头
frameHeader = 'AAFFF218';

% 打开文件以便读取
fileID = fopen(filename, 'r');

% 初始化帧计数器
frameCount = 0;

% 初始化一个结构体数组来存储帧数据
framesStruct = struct();

% 循环读取文件直到结束
while ~feof(fileID)
    % 读取一定数量的字符，这里假设每次读取1024个字符
    % 你可以根据实际情况调整这个值
    chunk = fread(fileID, 107374184, '*char')';
    
    % 查找帧头出现的位置
    startIndex = strfind(chunk, frameHeader);
    
    % 遍历所有帧头出现的位置
    for i = 1:length(startIndex)
        % 计算帧的结束位置，这里假设每个帧后面紧跟着下一个帧头或者文件末尾
        if i < length(startIndex)
            endIndex = startIndex(i+1) - 1;
        else
            endIndex = length(chunk);
        end
        
        % 提取帧，包括帧头和随后的数据
        frame = chunk(startIndex(i):endIndex);
        
        % 更新帧计数器
        frameCount = frameCount + 1;
        
        % 将提取的帧添加到结构体数组中
        framesStruct(frameCount).frameData = frame;
    end
end

% 关闭文件
fclose(fileID);

% 指定要保存的结构体数组的.mat文件名
matFileName = 'frames_struct.mat';

% 保存framesStruct结构体数组到.mat文件
save(matFileName, 'framesStruct');


%% 3、对每个数据帧做处理，将数据帧中的数据分组
% 加载保存的.mat文件
load('frames_struct.mat', 'framesStruct');

% 获取结构体数组中的帧数量
numFrames = length(framesStruct);

% 初始化一个单元格数组来存储处理后的数据
processedFrames = cell(numFrames, 1);

% 遍历每个帧进行处理
for i = 1:numFrames
    % 获取当前帧的16进制字符串
    hexFrame = framesStruct(i).frameData;
    
    % 计算每个8位分组的长度
    numCharsPerGroup = 8;
    
    % 计算总共有多少个8位分组
    numGroups = ceil(length(hexFrame) / numCharsPerGroup);
    
    % 初始化一个字符串数组来存储处理后的分组
    processedFrame = strings(1, numGroups);
    
    % 对每个8位分组进行处理
    for j = 1:numGroups
        % 计算当前分组的起始和结束索引
        startIdx = (j - 1) * numCharsPerGroup + 1;
        endIdx = min(startIdx + numCharsPerGroup - 1, length(hexFrame));
        
        % 提取当前8位分组
        group = hexFrame(startIdx:endIdx);
        
        % 将当前分组添加到处理后的帧中
        processedFrame(j) = group;
    end
    
    % 将处理后的帧添加到单元格数组中
    processedFrames{i} = processedFrame;
end

% 指定要保存处理后数据的.mat文件名
processedMatFileName = 'processed_frames.mat';

% 保存处理后的帧数据到.mat文件
save(processedMatFileName, 'processedFrames');

%% 4、转换数据格式，最终数据数据2-7列为IMU数据，
%     但扩大了10e8，从单片机上读过来就是大的，为的是整数保存
%     这里有个小bug是最后两位校验码也做了大端序调整，但最后一列可以忽略

% 加载保存的.mat文件
load('processed_frames.mat', 'processedFrames');

% 获取处理后帧的数量
numFrames = length(processedFrames);

% 初始化一个数组来存储转换后的数据
numGroupsPerFrame = 8; % 每个帧有8个8位分组
convertedFrames = zeros(numFrames, numGroupsPerFrame);

% 遍历每个帧进行处理
for i = 1:numFrames
    % 获取当前帧的8位分组字符串数组
    frameGroups = processedFrames{i};
    
    % 遍历每个分组进行转换
    for j = 1:length(frameGroups)
        % 将16进制字符串转换为10进制数值
        decimalValue = daduanxu(frameGroups(j));
        
        % 将转换后的数值存储在对应的位置
        convertedFrames(i, j) = decimalValue;
    end
end

% 指定要保存转换后数据的.mat文件名
convertedMatFileName = 'fanily_frames.mat';

% 保存转换后的帧数据到.mat文件
save(convertedMatFileName, 'convertedFrames');
