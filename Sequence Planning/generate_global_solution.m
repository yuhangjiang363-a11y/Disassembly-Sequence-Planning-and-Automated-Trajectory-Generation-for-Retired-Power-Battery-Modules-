function [sequence, directions] = generate_global_solution(width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus, varargin)
% GENERATE_GLOBAL_SOLUTION - 生成一个随机且可行的拆解序列及其方向
% 输入:
%   width: 零件数量 (N)
%   Tool: Nx1 每个零件所需的工具
%   Direction_...: 6个方向的遮挡矩阵 (NxN)
%   varargin{1}: 可选，如果提供，则为初始拆解序列，函数将为其生成方向
% 输出:
%   sequence: 1xN 的行向量，表示可行的拆解顺序
%   directions: 1xN 的行向量，directions(i) 表示拆解 sequence(i) 零件时所用的方向 (1-6)

    if nargin > 8 && ~isempty(varargin{1})
        input_sequence = varargin{1};
        % 确保输入的序列是可行的
        [feasible, sequence] = checkfeasibility(input_sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);
        if ~feasible
            error('提供的初始序列不可行。');
        end
    else
        % 1. 生成一个随机且可行的拆解序列
        initial_sequence = randperm(width); % 随机生成一个初始序列
        
        % 调用 checkfeasibility 确保序列可行
        [feasible, sequence] = checkfeasibility(initial_sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);
        
        if ~feasible
            error('无法生成可行的拆解序列。请检查输入数据或 checkfeasibility 函数。');
        end
    end

    % 2. 为每个零件选择一个可行的拆解方向
    directions = zeros(1, width);
    all_directions_matrices = {Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus};

    remained_parts_for_direction_check = 1:width; % 用于方向选择时的剩余零件列表

    for i = 1:width
        part_to_remove = sequence(i);
        
        % 找到所有可行的方向 (从 1-6 中选择)
        possible_directions = [];
        for dir_idx = 1:6
            direction_matrix = all_directions_matrices{dir_idx};
            blocking_parts = find(direction_matrix(part_to_remove, :) == 1);
            is_blocked = any(ismember(blocking_parts, remained_parts_for_direction_check));
            
            if ~is_blocked
                possible_directions = [possible_directions, dir_idx];
            end
        end
        
        if isempty(possible_directions)
            error('对于零件 %d，在可行的序列中找不到可行的拆解方向。', part_to_remove);
        end
        
        % 从可行方向中随机选择一个
        selected_dir = possible_directions(randi(length(possible_directions)));
        directions(i) = selected_dir;
        
        % 更新剩余零件列表
        remained_parts_for_direction_check(remained_parts_for_direction_check == part_to_remove) = [];
    end
end
