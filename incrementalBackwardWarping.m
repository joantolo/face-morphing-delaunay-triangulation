function incrementalBackwardWarping()
    clc; clear;
    
    % Points to click.
    
     points = 22;
    
    % Steps in morphing.
    
     n = 20;
    
    width = 200;
    height = 300;
    
    % Output gifs for warping animation.
    
    gif_path_s_to_t = './output/source_to_target_backward_warp.gif';
    gif_path_t_to_s = './output/target_to_source_backward_warp.gif'; 
    gif_path_morphed = './output/morphed_backward_warp.gif'; 
    
    % Load image 1.
    
    disp("Select first image");
    [file, path] = uigetfile('*.jpg');
    im1_original = imread(fullfile(path, file));
    
    % Rescale image to width and height.
    
    im1(:, :, 1) = imresize(im1_original(:, :, 1), [height width]); 
    im1(:, :, 2) = imresize(im1_original(:, :, 2), [height width]); 
    im1(:, :, 3) = imresize(im1_original(:, :, 3), [height width]); 
    
    % Load image 2.
    
    disp("Select second image");
    [file, path] = uigetfile('*.jpg');
    im2_original = imread(fullfile(path, file));
    
    % Rescale image to widht and height.
    
    im2(:, :, 1) = imresize(im2_original(:, :, 1), [height width]); 
    im2(:, :, 2) = imresize(im2_original(:, :, 2), [height width]); 
    im2(:, :, 3) = imresize(im2_original(:, :, 3), [height width]);
    
    % Obtain control points of first image.
    
    figure;
    imagesc(im1);
    axis equal;
    hold on;
    
    
    x1 = zeros(points, 1);
    x2 = zeros(points, 1);
    y1 = zeros(points, 1);
    y2 = zeros(points, 1);
    
    disp("Set control points on first image");
    for i = 1:points
        disp("  Control point: " + i + " of " + points);
        [x, y] = ginput(1);
        scatter(x, y, 30, [0 0.4470 0.7410], 'filled');
        x1(i) = x;
        y1(i) = y;
    end
    
    % Append points (1,1), (1,256), (256,1), and (256,256) to the control
    % points. This is needed for a Delauny triangulation that affects the
    % entire image.
    
    x1 = vertcat(x1, 1, 1, width, width);
    y1 = vertcat(y1, 1, height, 1, height);
    hold off;
    
    % Obtain control points of second image.
    
    figure;
    imagesc(im2);
    axis equal;
    hold on;

    disp("Set control points on second image in the same order");
    for i = 1:points
        disp("  Control point: " + i + " of " + points);
        [x, y] = ginput(1);
        scatter(x, y, 30, [0 0.4470 0.7410], 'filled');
        x2(i) = x;
        y2(i) = y;
    end
    
    x2 = vertcat(x2, 1, 1, width, width);
    y2 = vertcat(y2, 1, height, 1, height);
    hold off;
    close all

    % Compute triangulation using Delauny at the mid point.
    
    x_mean = (x1 + x2) / 2;
    y_mean = (y1 + y2) / 2;
    triangles = delaunay(x_mean, y_mean);
    
    % Show triangulation.
    
    figure;
    imagesc(im1);
    axis equal;
    hold on;
    triplot(triangles, x1, y1, 'Color', '#0072BD');
    title('Source');
    hold off;

    figure;
    imagesc(im2);
    axis equal;
    hold on;
    triplot(triangles, x2, y2, 'Color', '#0072BD');
    title('Target');
    hold off;
    drawnow();
    
    % Allocate matrix to store warped images.
    
    num_triangles = size(triangles, 1);

    % Allocate memory to store the affine transformations per triangle.
    
    affine_transf_src = zeros(3, 3, num_triangles);
    affine_transf_target = zeros(3, 3, num_triangles);
    
    warp_src_to_target = zeros(height, width, 3, n + 1, 'uint8');
    warp_target_to_src = zeros(height, width, 3, n + 1, 'uint8');
    
    % Interpolate between im1 and im2 with 0.1 steps.
    
    disp("Interpolating origin with objetive");
    for index = 1:n+1
        disp("  Step " + (index - 1) + " of " + n);
        t = (index - 1) / n;
        
        x_int = x1 * (1 - t) + x2 * t;
        y_int = y1 * (1 - t) + y2 * t;
        
        disp("    Getting transformation matrixes");
        
        % Find affine transformation of each triangle.
        
        for tri = 1:num_triangles

            % Affine transformations per triangle, two needed:
           
            X = [ x_int(triangles(tri,:)).'; y_int(triangles(tri,:)).'; ones(1, 3) ];

            % - One to go from im1 to current intermediate point (affine_transf_src)
            
            A = [ x1(triangles(tri,:)).'; y1(triangles(tri,:)).'; ones(1, 3) ];
            affine_transf_src(:, :, tri) = A / X;
           
           
            % - And other one to go from im2 to current intermediate point (affine_transf_target).
            
            A = [ x2(triangles(tri,:)).'; y2(triangles(tri,:)).'; ones(1, 3) ];
            affine_transf_target(:, :, tri) = A / X;
        end

        disp("    Obtaining colors");
        
        % For all image pixels of the source image.
        
        for i = 1:size(im1, 1)
            for j = 1:size(im1, 2)
                
                % Compute triangles ID that contains pixel (i, j).
                
                tn = tsearchn([x_int, y_int], triangles, [j, i]);
                
                % Warp source image pixels to the intermediate point and
                % save its result in warp_src_to_target.

                ij_ = round(affine_transf_src(:, :, tn) * [j; i; 1]);
                ij_ = min(max(ij_, 1), [width; height; 1]);

                warp_src_to_target(i, j, :, index) = im1(ij_(2), ij_(1), :);

            end
        end
        
        % For all image pixels of the target image.
        
        for i = 1:size(im2, 1)
            for j = 1:size(im2, 2)
                
                % Compute triangles ID that contains pixel (i, j).
                
                tn = tsearchn([x_int, y_int], triangles, [j, i]);
                
                % Warp target image pixels to the intermediate point and
                % save its result in warp_target_to_src.
                
                ij_ = round(affine_transf_target(:, :, tn) * [j; i; 1]);
                ij_ = min(max(ij_, 1), [width; height; 1]);

                warp_target_to_src(i, j, :, index) = im2(ij_(2), ij_(1), :);
            end
        end 
    end
    disp("End interpolation");
    
    disp("Generating gifs");
    index = 1;
    t = 0;
    for i = 0:(n*2)
        disp("  Image " + i + " with t = " + index); 
        
        % Create gif of source to target animation.
        
        morphed = warp_src_to_target(:, :, :, index);
        [A, map] = rgb2ind(morphed, 256);
        if t == 0
            imwrite(A, map, gif_path_s_to_t, 'gif', 'LoopCount',...
                Inf,'DelayTime',0.1);
        else
            imwrite(A, map, gif_path_s_to_t, 'gif', 'WriteMode',...
                'append', 'DelayTime', 0.1);
        end

        % Create gif of target to source animation.
        
        morphed = warp_target_to_src(:, :, :, index);
        [A, map] = rgb2ind(morphed, 256);
        if t == 0
            imwrite(A, map, gif_path_t_to_s, 'gif', 'LoopCount',...
                Inf, 'DelayTime', 0.1);
        else
            imwrite(A, map, gif_path_t_to_s, 'gif', 'WriteMode',...
                'append', 'DelayTime', 0.1);
        end

        % Blend the morphed images and create a gif.
        
        morphed = warp_src_to_target(:, :, :, index) * (1 - t) + warp_target_to_src(:, :, :, index) * t;
        [A, map] = rgb2ind(morphed, 256);
        if t == 0
            imwrite(A, map, gif_path_morphed, 'gif', 'LoopCount',...
                Inf, 'DelayTime', 0.1);
        else
            imwrite(A, map, gif_path_morphed, 'gif', 'WriteMode',...
                'append', 'DelayTime', 0.1);
        end
        
        if (i < n)
            t = t + (1 / n);
            index = index + 1;
        else
            t = t - (1 / n);
            index = index - 1;
        end
        
    end
    disp("Finished generation of gifs");
end