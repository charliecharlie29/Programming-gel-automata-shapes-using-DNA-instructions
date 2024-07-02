function new_intensities = histogram_stretch(intensities,min_intense,range)

if nargin < 3
    min_intense = min(min(intensities));
    max_intense = max(max(intensities));
    range = max_intense - min_intense;
end
if range==0 && max_intense==0 && min_intense==0
    new_intensities=intensities;% Pass through if the matrix is just zeros...
else
    min_intense = double(min_intense);
    range = double(range);
    y_max = 1.0;
    new_intensities = 1/range*double(intensities - min_intense);
end
