%CONTOUR_BLUR_ESTIMATION  Demo: render a circular annulus and display it.
%   contour_blur_estimation
%
%   Draws a thin ring of width ring_width at radius inner_radius from the
%   center of a square image, and displays it. Exploratory script with no
%   callable entry point; nothing else in the repo depends on it.
%
%   Inputs
%     none (image_size, inner_radius and ring_width are hardcoded below).
%
%   Output
%     none (side effect: opens a figure showing the annulus).
%
%   See also MK_WIN.

close all;
image_size = 64; half_image_size = image_size/2;
img = zeros(image_size, image_size);
inner_radius = 64;
ring_width = 10;
outer_radius = inner_radius+ring_width;
for i_row = 1:image_size
    for i_col = 1:image_size
        x = i_col + inner_radius - half_image_size;
        y = i_row - half_image_size;
        radius = sqrt(x^2+y^2);
        if (radius >= inner_radius) && (radius < outer_radius)
            img(i_row, i_col) = 255;
        end
    end
end
figure; colormap(gray(256)); image(img); axis image;
