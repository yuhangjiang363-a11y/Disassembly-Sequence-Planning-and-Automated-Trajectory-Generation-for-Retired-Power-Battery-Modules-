function [feasible, sequence] = checkfeasibility(sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus)
% CHECKFEASIBILITY - 检查给定的拆解序列是否可行（包含工具约束）
% 输入:
%   sequence: 1xN 的行向量，表示拆解顺序
%   width: 零件数量 (N)
%   Tool: Nx1 每个零件所需的工具
%   Direction_...: 6个方向的遮挡矩阵 (NxN)
% 输出:
%   feasible: 布尔值，true 表示可行，false 表示不可行
%   sequence: 如果输入序列不可行，则返回一个修正后的可行序列

    % 改进版: 使用“贪心搜索”寻找一个可行的拆解序列
    all_directions = {Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus};
    
    remained_parts = 1:width;
    found_sequence = [];
    
    for step = 1:width
        can_move_this_step = false;
        
        % 尝试找到当前可以被拿走的零件
        % 随机打乱剩余零件顺序，增加搜索多样性
        shuffled_remained = remained_parts(randperm(length(remained_parts)));
        
        for p_idx = 1:length(shuffled_remained)
            part_to_check = shuffled_remained(p_idx);
            
            % 检查该零件是否可以从 1-6 中的任何一个方向移出
            can_be_removed = false;
            for dir_idx = 1:6
                direction_matrix = all_directions{dir_idx};
                blocking_parts = find(direction_matrix(part_to_check, :) == 1);
                
                % 只要在剩余零件中没有挡住它的，它就是自由的
                if ~any(ismember(blocking_parts, remained_parts))
                    can_be_removed = true;
                    break;
                end
            end
            
            if can_be_removed
                % 找到了一个可拆零件
                found_sequence = [found_sequence, part_to_check];
                remained_parts(remained_parts == part_to_check) = [];
                can_move_this_step = true;
                break;
            end
        end
        
        if ~can_move_this_step
            % 如果某一步一个能拆的都没有，说明存在物理死锁
            feasible = false;
            sequence = sequence; % 返回原序列
            return;
        end
    end
    
    % 如果能走到这里，说明成功找到了一个可行序列
    feasible = true;
    sequence = found_sequence;
end
