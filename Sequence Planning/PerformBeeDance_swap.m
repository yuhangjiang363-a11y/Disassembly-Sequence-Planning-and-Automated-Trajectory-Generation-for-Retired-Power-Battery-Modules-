function [new_sequence, new_directions] = PerformBeeDance_swap(current_sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus)
% PERFORMBEEDANCE_SWAP - 执行邻域搜索（交换操作）
% 输入:
%   current_sequence: 当前的拆解序列
%   width: 零件数量 (N)
%   Tool: Nx1 每个零件所需的工具
%   Direction_...: 6个方向的遮挡矩阵 (NxN)
% 输出:
%   new_sequence: 经过交换后得到的一个新的可行序列
%   new_directions: 与新序列对应的拆解方向

    % 尝试最多 50 次来找到一个与当前不同的可行序列
    for i = 1:50 
        % 1. 随机选择两个不同的位置进行交换
        swap_indices = randperm(width, 2);
        temp_sequence = current_sequence;
        temp_sequence(swap_indices(1)) = current_sequence(swap_indices(2));
        temp_sequence(swap_indices(2)) = current_sequence(swap_indices(1));

        % 2. 检查交换后的序列是否可行（现在会考虑工具约束）
        [feasible, feasible_sequence] = checkfeasibility(temp_sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);

        % 3. 如果可行，并且与原序列不同，则生成新方向并返回
        if feasible && ~isequal(feasible_sequence, current_sequence)
            [new_sequence, new_directions] = generate_global_solution(width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus, feasible_sequence);
            return;
        end
    end

    % 如果 50 次尝试后仍未找到新的可行序列，则返回原始解
    new_sequence = current_sequence;
    [~, new_directions] = generate_global_solution(width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus, new_sequence);
end
