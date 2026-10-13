function output_matrix = force_matrix_size(input_matrix, target_rows, target_cols)
% FORCE_MATRIX_SIZE - 强制将输入矩阵调整为目标尺寸
% 如果输入矩阵比目标尺寸大，则裁剪；如果小，则用0填充。

    [r, c] = size(input_matrix);
    output_matrix = zeros(target_rows, target_cols);
    
    copy_rows = min(r, target_rows);
    copy_cols = min(c, target_cols);
    
    output_matrix(1:copy_rows, 1:copy_cols) = input_matrix(1:copy_rows, 1:copy_cols);
end
