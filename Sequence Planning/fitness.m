function [total_cost, sol] = fitness(sequence, directions, width, Tool, BasicTime, Distance, DirectionChangeTime, ToolChangeTime, speed, timescale, ToolInstallTime)
% FITNESS - 计算给定解（序列和方向）的总成本
% 输入:
%   sequence: 1xN 拆解顺序
%   directions: 1xN 对应的拆解方向
%   width: 零件数量 (N)
%   Tool: Nx1 每个零件所需的工具
%   BasicTime: Nx1 每个零件的基础拆解时间（旧表）
%             或 Nx6 每个零件在六个方位的拆解时间（新表，列顺序: X+/X-/Y+/Y-/Z+/Z-）
%   Distance: NxN 零件间的距离矩阵
%   DirectionChangeTime: 6x6 方向切换成本矩阵
%   ToolChangeTime: MxM 工具切换成本矩阵 (M为工具数)
%   speed, timescale: 成本计算参数
%   ToolInstallTime: (可选) Mx1 每个工具的安装/放回时间
% 输出:
%   total_cost: 该解的总成本
%   sol: 详细的成本分析矩阵 (width x 7)

    if nargin < 11
        ToolInstallTime = zeros(max(Tool), 1);
    end

    total_cost = 0;
    sol = zeros(width, 7);

    % 初始安装第一个工具的时间
    first_tool = Tool(sequence(1));
    if first_tool <= length(ToolInstallTime)
        initial_install_time = ToolInstallTime(first_tool);
    else
        initial_install_time = 0;
    end
    total_cost = total_cost + initial_install_time;

    for i = 1:width
        part_id = sequence(i);
        dir_id = directions(i);
        tool_id = Tool(part_id);

        % 初始化当前步骤的成本
        tool_change_cost = 0;
        dir_change_cost = 0;
        distance_cost = 0;

        if i > 1
            % 计算换刀成本
            prev_part_id = sequence(i-1);
            prev_tool_id = Tool(prev_part_id);
            if tool_id ~= prev_tool_id
                % 假设 ToolChangeTime 是一个标量或可以索引的矩阵
                if isscalar(ToolChangeTime)
                    tool_change_cost = ToolChangeTime;
                else
                    tool_change_cost = ToolChangeTime(prev_tool_id, tool_id);
                end
            end

            % 计算换向成本
            prev_dir_id = directions(i-1);
            if dir_id ~= prev_dir_id
                if isscalar(DirectionChangeTime)
                    dir_change_cost = DirectionChangeTime;
                elseif isequal(size(DirectionChangeTime), [6, 6])
                    dir_change_cost = DirectionChangeTime(prev_dir_id, dir_id);
                else
                    dir_change_cost = 0;
                end
            end

            % 计算距离成本
            distance_cost = (Distance(prev_part_id, part_id) / speed) * timescale;
        end
        
        % 基础拆解时间成本
        if isvector(BasicTime)
            basic_time_cost = BasicTime(part_id);
        else
            if dir_id <= size(BasicTime, 2)
                basic_time_cost = BasicTime(part_id, dir_id);
            else
                basic_time_cost = BasicTime(part_id, end);
            end
        end
        
        % 计算总步成本
        step_cost = basic_time_cost + tool_change_cost + dir_change_cost + distance_cost;
        total_cost = total_cost + step_cost;

        % 存储详细信息
        sol(i, 1) = part_id;
        sol(i, 2) = dir_id;
        sol(i, 3) = tool_id;
        sol(i, 4) = dir_change_cost;
        sol(i, 5) = tool_change_cost;
        sol(i, 6) = distance_cost;
        sol(i, 7) = step_cost;
    end
    
    % 最后放回最后一个工具的时间
    last_tool = Tool(sequence(width));
    if last_tool <= length(ToolInstallTime)
        final_remove_time = ToolInstallTime(last_tool);
    else
        final_remove_time = 0;
    end
    total_cost = total_cost + final_remove_time;
end
