%% Enhanced Discrete Bees Algorithm Main Loop

% 初始化
BestCost = inf;
GlobalBestSolution = [];
GlobalBestDirections = [];
OptCost = zeros(1, MaxIt);

% 创建初始蜂群
Bees = struct;
for i = 1:nScoutBee
    [sequence, directions] = generate_global_solution(width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);
    [cost, ~] = fitness(sequence, directions, width, Tool, BasicTime, Distance, DirectionChangeTime, ToolChangeTime, speed, timescale, ToolInstallTime);
    Bees(i).sequence = sequence;
    Bees(i).directions = directions;
    Bees(i).cost = cost;
    
    if cost < BestCost
        BestCost = cost;
        GlobalBestSolution = sequence;
        GlobalBestDirections = directions;
    end
end

% 主循环
for it = 1:MaxIt
    
    % 1. 排序蜂群，确定精英蜂和普通蜂
    [~, sorted_indices] = sort([Bees.cost]);
    Bees = Bees(sorted_indices);
    
    % 2. 对精英蜂进行邻域搜索
    for i = 1:nSelectedSite
        best_new_cost = Bees(i).cost;
        best_new_sequence = Bees(i).sequence;
        best_new_directions = Bees(i).directions;
        
        for j = 1:nrpersite(i) % 每个精英点招募的工蜂数量
            [new_sequence, new_directions] = PerformBeeDance_swap(Bees(i).sequence, width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);
            [new_cost, ~] = fitness(new_sequence, new_directions, width, Tool, BasicTime, Distance, DirectionChangeTime, ToolChangeTime, speed, timescale, ToolInstallTime);
            
            if new_cost < best_new_cost
                best_new_cost = new_cost;
                best_new_sequence = new_sequence;
                best_new_directions = new_directions;
            end
        end
        
        % 如果找到了更好的解，则更新该精英蜂
        if best_new_cost < Bees(i).cost
            Bees(i).cost = best_new_cost;
            Bees(i).sequence = best_new_sequence;
            Bees(i).directions = best_new_directions;
        end
    end
    
    % 3. 对非精英蜂（侦察蜂）进行全局随机搜索
    for i = (nSelectedSite + 1):nScoutBee
        [sequence, directions] = generate_global_solution(width, Tool, Direction_X_plus, Direction_X_minus, Direction_Y_plus, Direction_Y_minus, Direction_Z_plus, Direction_Z_minus);
        [cost, ~] = fitness(sequence, directions, width, Tool, BasicTime, Distance, DirectionChangeTime, ToolChangeTime, speed, timescale, ToolInstallTime);
        Bees(i).sequence = sequence;
        Bees(i).directions = directions;
        Bees(i).cost = cost;
    end
    
    % 4. 更新全局最优解
    [current_best_cost, best_idx] = min([Bees.cost]);
    if current_best_cost < BestCost
        BestCost = current_best_cost;
        GlobalBestSolution = Bees(best_idx).sequence;
        GlobalBestDirections = Bees(best_idx).directions;
    end
    
    % 记录本次迭代的最优成本
    OptCost(it) = BestCost;
    
    % (可选) 显示迭代信息
    % fprintf('迭代 %d: 最优成本 = %f\n', it, BestCost);
end

% 最终结果
FinalRunCost = BestCost; % 将本次运行的最优成本赋值给输出变量
if isempty(GlobalBestSolution)
    fprintf('警告：未找到任何可行解，请检查输入数据！\n');
    BestSol = zeros(width, 7);
else
    [~, BestSol] = fitness(GlobalBestSolution, GlobalBestDirections, width, Tool, BasicTime, Distance, DirectionChangeTime, ToolChangeTime, speed, timescale, ToolInstallTime);
end
