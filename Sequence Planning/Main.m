%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Fibonacci Bees Algorithm for Robotic Disassembly Sequence Problem    %
%   Natalia Hartono and Duc Truong Pham                                  %
%   This code accompanied the paper: A Novel Fibonacci-inspired          %
%   enhancement of the Bees Algorithm: Application to Robotic            %
%   Disassembly Sequence Planning                                        %
%                                                                        %
%   This BAF code was build upon the code from this paper:               %
%   https://doi.org/10.1080/00207543.2017.1412527                        %
%   Robotic disassembly sequence planning using enhanced discrete bees   %
%   algorithm in remanufacturing, International Journal of Production    %
%   Research, Volume 56, 2018, issue 9.                                  %
%   Jiayi Liu, Zude Zhou, Duc Truong Pham, Wenjun Xu, Chuqian Ji,        %
%   Quan Liu.                                                            %
%                                                                        %  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Do not change this part
clc;
clear;
close all;

%% 【修改点 1】: 加载你生成的自定义模型
load inputdataMyModel.mat      % 加载通过 xulie.xlsx 生成的 6 零件模型
% load inputdataGearA.mat      % (原有的) Gear pump A 模型

width = length(Tool); % 零件数量
fprintf('\n--- 主程序加载报告 ---\n');
fprintf('当前模型零件数: %d\n', width);
fprintf('加载的拆卸时间总和: %.2f\n', sum(BasicTime(:)));
fprintf('----------------------\n');
speed = 12;  % 机器人移动速度
timescale = 2;

%% Runtimes can be change according to user preference
runtimes = 5;

%% Bees Algorithm Parameters 
%% The paramater can be changed, but please refer to the paper for guidance
nSelectedSite=4;    % Number of Selected Sites (can be changed)
nrpersite = [13,8,5,3];  % 招募工蜂数量 (斐波那契数列)
counter = 0;

for nScoutBee = 10        % 侦察蜂数量 (因为你只有6个零件，建议设为10左右)
    for MaxIt = 50            % 迭代次数 (6个零件建议50次就足够了)
        for run = 1:runtimes
            fprintf('正在进行第 %d 次运行... \n', run);
            BAFrun;
            Objective(run) = FinalRunCost; % 正确记录本次运行的最终成本
            NFE(run)=counter;  %this is to calculate number function of evaluation
            fprintf('第 %d 次运行完成，当前最优成本: %f \n', run, Objective(run));
        end
        name = ['Result_',num2str(MaxIt),'pop',num2str(nScoutBee)];
        ave_Objective = sum(Objective(1:runtimes))/runtimes;
        ave_NFE = NFE(run)/runtimes;
        standardev = std(Objective(1:runtimes));
        save(name,'Objective','ave_Objective','BestSol','ave_NFE','standardev');  
        
        % 自动显示最优拆解方案
        fprintf('\n====== 最优拆解方案 (数字) ======\n');
        fprintf('零件号  方向  工具  步成本\n');
        disp(BestSol(:, [1, 2, 3, 7]));
        fprintf('====================================\n');
        
        % --- 结果可视化与验算 ---
        part_labels = {'A', 'B', 'C', 'D', 'E', 'F'};
        dir_labels = {'X+', 'X-', 'Y+', 'Y-', 'Z+', 'Z-'};
        tool_labels = {'T1', 'T2', 'T3'}; % 根据您的工具种类调整
        
        fprintf('\n====== 方案验算 (文本化) ======\n');
        fprintf('步骤 | 拆解零件 | 使用工具 | 拆解方向 | 步成本\n');
        fprintf('--------------------------------------------------\n');
        for i = 1:size(BestSol, 1)
            part_num = BestSol(i, 1);
            dir_num = BestSol(i, 2);
            tool_num = BestSol(i, 3);
            step_cost = BestSol(i, 7);
            
            % 安全地获取标签，防止索引越界
            part_label = part_labels{part_num};
            dir_label = dir_labels{dir_num};
            if tool_num <= length(tool_labels)
                tool_label = tool_labels{tool_num};
            else
                tool_label = ['T', num2str(tool_num)]; % 如果工具号超出预设，则直接显示
            end
            
            fprintf(' %d   |      %s      |     %s     |     %s     |  %.4f\n', i, part_label, tool_label, dir_label, step_cost);
        end
        fprintf('--------------------------------------------------\n');
        
        % 修正总成本计算，加上初始安装和最终放回的工具时间
        first_tool = BestSol(1, 3);
        last_tool = BestSol(end, 3);
        initial_install_time = 0;
        final_remove_time = 0;
        if first_tool <= length(ToolInstallTime)
            initial_install_time = ToolInstallTime(first_tool);
        end
        if last_tool <= length(ToolInstallTime)
            final_remove_time = ToolInstallTime(last_tool);
        end
        
        total_calculated_cost = sum(BestSol(:, 7)) + initial_install_time + final_remove_time;
        fprintf('总成本: %.4f (包含初始安装 T%d: %.3f, 最终放回 T%d: %.3f)\n', ...
            total_calculated_cost, first_tool, initial_install_time, last_tool, final_remove_time);
        
        % --- 【新增】: 自动导出结果至 VSCode (JSON 格式) ---
        result_struct = struct();
        result_struct.total_cost = total_calculated_cost;
        result_struct.sequence = BestSol(:, 1)'; % 零件序列
        result_struct.directions = BestSol(:, 2)'; % 方向序列
        result_struct.tools = BestSol(:, 3)'; % 工具序列
        result_struct.step_costs = BestSol(:, 7)'; % 每步成本
        
        % 定义标签供 JSON 使用
        result_struct.part_labels = part_labels;
        result_struct.dir_labels = dir_labels;

        % 转换为 JSON 并写入文件
        json_str = jsonencode(result_struct);
        fid = fopen('disassembly_result.json', 'w');
        if fid ~= -1
            fprintf(fid, '%s', json_str);
            fclose(fid);
            fprintf('\n--- 结果已成功导出至 disassembly_result.json ---\n');
        else
            fprintf('\n警告: 无法创建 JSON 导出文件。\n');
        end
        % ---------------------------
    end
end
       
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% How to read the output:                                                 %
% BestSol = the output of robotic disassembly sequence, direction, tool,  %
%           direction change, toolchange, distance, totalcost (objective) %
% Objective = the best objective results recorded in each runs            %
% ave_NFE = average Number of Function of Evaluation                      %
% ave_Objective = average of the objective                                %
% standardev = standar deviation                                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
