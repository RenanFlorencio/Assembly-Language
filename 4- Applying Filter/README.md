# Applying Filters #

This is an extension of the Drawing on Canvas code, but now an edge filter is being applyed to it.

The filter is given by the following matrix:

-1 | -1 | -1
--- | --- | --- 
-1 | 8 | -1 
-1 | -1 | -1

This matrix sweeps over the image calculating the value for the new pixel on the position of the center of the matrix. This results on a new image that has a high contrast on its edges.

To avoid invalid pixels, the border of the image is set to black pixels and the result of the matrix product is capped to a value between 0 and 255.

