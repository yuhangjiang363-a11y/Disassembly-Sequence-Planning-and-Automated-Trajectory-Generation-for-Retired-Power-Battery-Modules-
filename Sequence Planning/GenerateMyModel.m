%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   智能生成拆解模型数据脚本 - 最终健壮版
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear; 
clc;
%filename = 'xulie.xlsx'; 
filename = 'chaijie(ceshi).xlsx'; 
N = 6; 

if ~exist(filename, 'file')
    fallback = 'chaijie.xlsx';
    if exist(fallback, 'file')
        filename = fallback;
    else
        error('找不到文件 %s', filename);
    end
end

safe_fprintf('正在从 %s 提取 6 零件模型数据...\n', filename);

try
    % 1-6. 读取方向矩阵 (取前 NxN)
    Direction_X_plus  = force_matrix_size(extract_clean_num(filename, 1), N, N);
    Direction_X_minus = force_matrix_size(extract_clean_num(filename, 2), N, N);
    Direction_Y_plus  = force_matrix_size(extract_clean_num(filename, 3), N, N);
    Direction_Y_minus = force_matrix_size(extract_clean_num(filename, 4), N, N);
    Direction_Z_plus  = force_matrix_size(extract_clean_num(filename, 5), N, N);
    Direction_Z_minus = force_matrix_size(extract_clean_num(filename, 6), N, N);
    
    sheets = sheetnames(filename);

    % 7. 方向切换矩阵 (通常为 6x6；若新表不再提供 6x6，则置零)
    dir_change_sheet = find_sheet_name(sheets, ["Direction Change","方向切换","换向"], ["Tool Change","换刀","Basic","拆卸","tool"]);
    if ~isempty(dir_change_sheet)
        raw_dct = extract_clean_num(filename, dir_change_sheet);
    else
        raw_dct = [];
    end
    if isequal(size(raw_dct), [6, 6])
        DirectionChangeTime = raw_dct;
    else
        DirectionChangeTime = zeros(6, 6);
    end
    
    % 8. 换刀时间 (优先按 Sheet 名称匹配；否则兼容旧表按序号读取)
    tool_change_sheet = find_sheet_name(sheets, ["Tool Change","换刀"], ["Direction","方向","Basic","拆卸"]);
    if ~isempty(tool_change_sheet)
        ToolChangeTime = extract_clean_num(filename, tool_change_sheet);
    else
        ToolChangeTime = extract_clean_num(filename, 8);
    end
    
    % 9. 拆卸时间（支持 Nx6 各方向拆卸时间）
    % 兼容两种表结构：
    % - 旧表：Nx1 基本拆卸时间
    % - 新表：Nx6 各零件在六个方位的拆卸时间（X+/X-/Y+/Y-/Z+/Z-）
    basic_time_sheet = find_sheet_name(sheets, ["Basic Time","拆卸时间","Disassembly Time"], ["Tool Change","换刀","tool"]);
    if ~isempty(basic_time_sheet)
        temp_bt = extract_clean_num(filename, basic_time_sheet);
    else
        temp_bt = extract_clean_num(filename, 9);
    end
    if isempty(temp_bt)
        BasicTime = zeros(N, 1);
    else
        if size(temp_bt, 2) >= 7
            cand = temp_bt(:, end-5:end);
        elseif size(temp_bt, 2) >= 6
            cand = temp_bt(:, 1:6);
        else
            BasicTime = temp_bt(:);
            BasicTime = BasicTime(BasicTime > 0);
            BasicTime = force_matrix_size(BasicTime, N, 1);
            cand = [];
        end

        if ~isempty(cand)
            % 兼容两种排布：
            % - 方向在行、零件在列（如 Basic Time: 行=X+/X-/... 列=A/B/...）=> 转置
            % - 零件在行、方向在列 => 直接使用
            if size(cand, 2) == N && size(cand, 1) <= 6 && size(cand, 1) ~= N
                BasicTime = force_matrix_size(cand', N, 6);
            else
                BasicTime = force_matrix_size(cand, N, 6);
            end
        end
    end

    % 若仍是 Nx1，自动扫描工作表寻找“按方向拆卸时间”矩阵 (Nx6)
    if isvector(BasicTime) && numel(BasicTime) == N
        bt6 = find_directional_time_matrix(filename, N, DirectionChangeTime);
        if ~isempty(bt6)
            BasicTime = bt6;
        end
    end

    if ~isvector(BasicTime) && size(BasicTime, 2) == 6
        if all(BasicTime(:, 6) == 0) && any(BasicTime(:, 5) ~= 0)
            BasicTime(:, 6) = BasicTime(:, 5);
        end
    end
    
    % 10. 工具信息
    % 优先从包含 "T1/T2/T3..." 的单元格中提取（避免把 0/1 约束矩阵误识别为工具编号）
    tool_sheet = find_tool_sheet_name(sheets);
    if isempty(tool_sheet)
        tool_sheet = 10;
    end
    Tool = extract_tool_list(filename, tool_sheet, N, sheets);
    
    % 修正换刀矩阵大小
    num_tools = max(Tool);
    if isempty(num_tools) || num_tools < 1; num_tools = 1; end
    ToolChangeTime = force_matrix_size(ToolChangeTime, num_tools, num_tools);
    Distance = zeros(N, N);

    % 11. 读取工具安装/放回时间 (zhuang 表)
    % 默认工具安装时间为0
    ToolInstallTime = zeros(num_tools, 1);
    zhuang_sheet = find_sheet_name(sheets, ["zhuang", "安装", "装"], []);
    if ~isempty(zhuang_sheet)
        try
            zhuang_data = readcell(filename, 'Sheet', zhuang_sheet);
            for i = 1:size(zhuang_data, 1)
                t_val = zhuang_data{i, 1};
                time_val = zhuang_data{i, 2};
                if (ischar(t_val) || isstring(t_val)) && isnumeric(time_val) && ~isnan(time_val)
                    m = regexp(string(t_val), 'T\s*(\d+)', 'tokens', 'once', 'ignorecase');
                    if ~isempty(m)
                        t_idx = str2double(m{1});
                        if t_idx >= 1 && t_idx <= num_tools
                            ToolInstallTime(t_idx) = time_val;
                        end
                    end
                end
            end
        catch
            safe_fprintf('警告: 读取 zhuang 表格失败，使用默认安装时间 0。\n');
        end
    end

    % 数据验证
    safe_fprintf('\n--- 数据验证报告 ---\n');
    safe_fprintf('成功读取零件数: %d\n', N);
    part_names = {'A', 'B', 'C', 'D', 'E', 'F'};
    for idx = 1:min(length(Tool), length(part_names))
        safe_fprintf('零件 %s 使用工具: T%d\n', part_names{idx}, Tool(idx));
    end
    safe_fprintf('识别到的独立工具编号: %s\n', mat2str(unique(Tool)'));
    safe_fprintf('加载的拆卸时间总和: %.2f\n', sum(BasicTime(:)));
    safe_fprintf('加载的方向切换成本总和: %.2f\n', sum(DirectionChangeTime(:)));
    safe_fprintf('加载的工具安装时间总和: %.2f\n', sum(ToolInstallTime));
    safe_fprintf('--------------------\n');

    save('inputdataMyModel.mat', ...
        'Direction_X_plus', 'Direction_X_minus', ...
        'Direction_Y_plus', 'Direction_Y_minus', ...
        'Direction_Z_plus', 'Direction_Z_minus', ...
        'Tool', 'BasicTime', 'Distance', ...
        'DirectionChangeTime', 'ToolChangeTime', 'ToolInstallTime');
    
    safe_fprintf('模型生成成功！\n');
catch ME
    rethrow(ME);
end

function safe_fprintf(varargin)
    try
        fprintf(varargin{:});
    catch
    end
end

function Tool = extract_tool_list(fname, preferred_sheet, N, sheets)
    Tool = [];

    Tool = extract_tool_from_sheet(fname, preferred_sheet, N);
    if numel(Tool) >= N
        Tool = Tool(1:N)';
        return;
    end

    tool_sheet = find_tool_sheet_name(sheets);
    if ~isempty(tool_sheet)
        Tool = extract_tool_from_sheet(fname, tool_sheet, N);
        if numel(Tool) >= N
            Tool = Tool(1:N)';
            return;
        end
    end

    for s = 1:numel(sheets)
        t = extract_tool_from_sheet(fname, sheets{s}, N);
        if numel(t) >= N
            Tool = t(1:N)';
            return;
        end
    end

    Tool = ones(N, 1);
end

function tool_nums = extract_tool_from_sheet(fname, sheet_id, N)
    tool_nums = [];
    try
        raw = readcell(fname, 'Sheet', sheet_id);
    catch
        return;
    end

    if nargin < 3
        N = min(6, size(raw, 2));
    end

    if size(raw, 1) >= 2 && size(raw, 2) >= N
        labels = string(raw(1, 1:N));
        expected = ["A","B","C","D","E","F"];
        if N <= numel(expected) && all(strcmpi(labels, expected(1:N)))
            for j = 1:N
                v = raw{2, j};
                if ischar(v) || isstring(v)
                    d = regexp(string(v), '\d+', 'match', 'once');
                    if ~isempty(d)
                        tool_nums(end+1) = str2double(d); %#ok<AGROW>
                    end
                elseif isnumeric(v) && ~isnan(v)
                    tool_nums(end+1) = v; %#ok<AGROW>
                end
            end
            return;
        end
    end

    for i = 1:size(raw, 1)
        for j = 1:size(raw, 2)
            c = raw{i, j};
            if ischar(c) || isstring(c)
                txt = string(c);
                m = regexp(txt, 'T\s*\d+', 'match', 'once', 'ignorecase');
                if ~isempty(m)
                    d = regexp(m, '\d+', 'match', 'once');
                    if ~isempty(d)
                        tool_nums(end+1) = str2double(d); %#ok<AGROW>
                    end
                end
            end
        end
    end

    if numel(tool_nums) >= 1
        return;
    end

    % 若该 Sheet 工具编号是纯数字（无 "T" 前缀），再尝试数字提取：
    % 过滤 0/1 约束矩阵：要求出现过 >1 的工具号。
    numeric_candidates = [];
    for i = 1:size(raw, 1)
        for j = 1:size(raw, 2)
            c = raw{i, j};
            if isnumeric(c) && ~isnan(c)
                numeric_candidates(end+1) = c; %#ok<AGROW>
            end
        end
    end
    numeric_candidates = numeric_candidates(numeric_candidates >= 1 & numeric_candidates <= 20);
    numeric_candidates = numeric_candidates(abs(numeric_candidates - round(numeric_candidates)) < 1e-9);
    if any(numeric_candidates > 1)
        tool_nums = numeric_candidates;
    end
end

function bt6 = find_directional_time_matrix(fname, N, DirectionChangeTime)
    bt6 = [];
    try
        sheets = sheetnames(fname);
    catch
        return;
    end

    for s = 1:numel(sheets)
        if s <= 6
            continue;
        end
        data = extract_clean_num(fname, sheets{s});
        if isempty(data) || size(data, 1) < N || size(data, 2) < 6
            continue;
        end

        cand = force_matrix_size(data, N, 6);
        vals = cand(:);
        vals = vals(isfinite(vals));
        if isempty(vals)
            continue;
        end

        % 排除 0/1 约束矩阵
        if all(ismember(vals, [0; 1]))
            continue;
        end

        % 排除已识别的方向切换矩阵（若碰巧同型）
        if isequal(size(cand), [6, 6]) && isequal(size(DirectionChangeTime), [6, 6])
            if isequal(cand, DirectionChangeTime)
                continue;
            end
        end

        if any(vals ~= 0)
            bt6 = cand;
            return;
        end
    end
end

function name = find_sheet_name(sheets, include_keywords, exclude_keywords)
    name = '';
    if isempty(sheets)
        return;
    end

    for i = 1:numel(sheets)
        s = string(sheets{i});
        ok = false;
        for k = 1:numel(include_keywords)
            if contains(lower(s), lower(string(include_keywords(k))))
                ok = true;
                break;
            end
        end
        if ~ok
            continue;
        end
        for k = 1:numel(exclude_keywords)
            if contains(lower(s), lower(string(exclude_keywords(k))))
                ok = false;
                break;
            end
        end
        if ok
            name = char(s);
            return;
        end
    end
end

function tool_sheet = find_tool_sheet_name(sheets)
    tool_sheet = '';
    if isempty(sheets)
        return;
    end

    for i = 1:numel(sheets)
        s = string(sheets{i});
        if strcmpi(s, "tool")
            tool_sheet = char(s);
            return;
        end
    end

    tool_sheet = find_sheet_name(sheets, ["tool","工具"], ["tool change","换刀"]);
end

function clean_data = extract_clean_num(fname, sheet_idx)
    % 优化后的数据提取函数：不再盲目删除全零行
    try
        raw_cell = readcell(fname, 'Sheet', sheet_idx);
        
        % 预处理：将所有非数字内容（如文本、NaN）转换为 0
        % 但要保留可能是数字的字符串
        [rows, cols] = size(raw_cell);
        numeric_matrix = zeros(rows, cols);

        for i = 1:rows
            for j = 1:cols
                cell_content = raw_cell{i, j};
                if isnumeric(cell_content)
                    if isnan(cell_content)
                        numeric_matrix(i, j) = 0;
                    else
                        numeric_matrix(i, j) = cell_content;
                    end
                elseif ischar(cell_content) || isstring(cell_content)
                    % 增强型数字提取：从 "T1", "Tool2" 等字符串中提取数字
                    extracted_num = str2double(regexp(cell_content, '\d+', 'match', 'once'));
                    if ~isnan(extracted_num)
                        numeric_matrix(i, j) = extracted_num;
                    else
                        numeric_matrix(i, j) = 0;
                    end
                else
                    numeric_matrix(i, j) = 0;
                end
            end
        end

        % 智能识别表头：仅当第一行或第一列包含明显的非数字文本且不是 0/1 时才删除
        % 考虑到约束矩阵主要是 0 和 1，如果第一行全是 0，它很可能是数据而不是表头
        
        % 检查第一行是否为纯文本表头 (readcell 读到文本会返回 missing 或 NaN，处理后变为 0)
        % 我们重新用 readcell 的原始类型判断
        is_text_row1 = false;
        if rows > 1
            text_count = 0;
            for j = 1:cols
                if ischar(raw_cell{1, j}) || isstring(raw_cell{1, j})
                    if isnan(str2double(raw_cell{1, j}))
                        text_count = text_count + 1;
                    end
                end
            end
            if text_count > cols / 2
                is_text_row1 = true;
            end
        end

        if is_text_row1
            numeric_matrix = numeric_matrix(2:end, :);
        end

        % 检查第一列是否为零件标签 (A, B, C...)
        is_text_col1 = false;
        if size(numeric_matrix, 2) > 1
            text_count = 0;
            for i = 1:size(numeric_matrix, 1)
                if ischar(raw_cell{i, 1}) || isstring(raw_cell{i, 1})
                    if isnan(str2double(raw_cell{i, 1}))
                        text_count = text_count + 1;
                    end
                end
            end
            if text_count > size(numeric_matrix, 1) / 2
                is_text_col1 = true;
            end
        end

        if is_text_col1
            numeric_matrix = numeric_matrix(:, 2:end);
        end

        clean_data = numeric_matrix;

    catch
        clean_data = [];
    end
end
