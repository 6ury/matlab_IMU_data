 function reversedHexNum = daduanxu(hexNum)
% 原始的16进制数
    % hexNum = 'AAFFF218';这里为测试
    % 将十六进制字符串转换为数值
    numValue = hex2dec(hexNum);
    % 将数值转换回十六进制字符串
    hexNum = dec2hex(numValue, 8);
    % 确保输入的16进制数长度是偶数
    if mod(length(hexNum), 2) ~= 0
      error('16进制数的长度必须是偶数');
    end

% 将16进制字符串分割成每两个字符的字符串数组
    hexParts = regexp(hexNum, '..', 'match');

% 将字符串数组倒序排列
    reversedHexParts = hexParts(end:-1:1);

% 将倒序后的字符串数组合并成一个字符串
    reversedHexNum = strjoin(reversedHexParts, '');
    reversedHexNum = hex2dec(reversedHexNum);
end