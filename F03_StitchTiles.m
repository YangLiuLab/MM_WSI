function I_array = F03_StitchTiles(img_name_grid,stitchPath,rstPath)

%---------------------------------------------------------------------------------------------
% Calclulate translation matrix
%---------------------------------------------------------------------------------------------
% Advanced Tab
repeatability = NaN;
estimated_overlap_x = 13;
estimated_overlap_y = 22;
percent_overlap_error = 5;

log_file_path = [];

% Calculate translation matrix
X1_ary = [];X2_ary = [];Y1_ary = [];Y2_ary = [];CC1_ary = [];CC2_ary = [];
for i = 1:size(img_name_grid,3)
	temp_img_name_grid = img_name_grid(:,:,i);
	
	% Translation Computation
	[Y1, X1, Y2, X2, CC1, CC2] = compute_pciam(rstPath, temp_img_name_grid, log_file_path);
	
	% Translation Correction
	[Y1, X1, Y2, X2, CC1, CC2] = translation_optimization(rstPath, temp_img_name_grid, Y1, X1, Y2, X2, CC1, CC2, repeatability, percent_overlap_error, estimated_overlap_x, estimated_overlap_y, log_file_path);
	
	X1_ary = cat(3,X1_ary,X1);X2_ary = cat(3,X2_ary,X2);
	Y1_ary = cat(3,Y1_ary,Y1);Y2_ary = cat(3,Y2_ary,Y2);
	CC1_ary = cat(3,CC1_ary,CC1);CC2_ary = cat(3,CC2_ary,CC2);
end

CC1_mx = CC1_ary; CC2_mx = CC2_ary;
CC1_mx(isnan(CC1_mx)) = 0; CC2_mx(isnan(CC2_mx)) = 0;
ave_CC1 = squeeze(mean(CC1_mx,[1 2])); ave_CC2 = squeeze(mean(CC2_mx,[1 2]));
ave_all = ave_CC1 + ave_CC2;
[max_val,max_idx] = max(ave_all);

% Create global image positions
X1 = X1_ary(:,:,max_idx);X2 = X2_ary(:,:,max_idx);
Y1 = Y1_ary(:,:,max_idx);Y2 = Y2_ary(:,:,max_idx);
CC1 = CC1_ary(:,:,max_idx);CC2 = CC2_ary(:,:,max_idx);
[tiling_indicator, tile_weights, global_y_img_pos, global_x_img_pos] = minimum_spanning_tree(Y1, X1, Y2, X2, CC1, CC2);

	
%---------------------------------------------------------------------------------------------
% Stitch images
%---------------------------------------------------------------------------------------------
blend_method_options = {'Overlay','Average','Linear','Max','Min'};
blend_method = blend_method_options{3};
% controls the linear blending, higher alpha will blend the edges more, alpha of 0 turns the linear blending into average blending
alpha = 1.5;

I_array = [];
for i = 1:size(img_name_grid,3)
	temp_img_name_grid = img_name_grid(:,:,i);
	I = assemble_stitched_image(rstPath, temp_img_name_grid, global_y_img_pos, global_x_img_pos, tile_weights, blend_method, alpha);
	I_array = cat(3,I_array,I);
end


end