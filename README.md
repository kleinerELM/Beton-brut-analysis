# Béton-brut-analysis
Tool to evaluate the optical surface quality of béton brut objectively. It will analyze pore area, inhomogeneities and structures.

## Requirements
[Fiji](https://fiji.sc/) (tested with ImageJ 1.52i)
[Python](https://www.python.org/) (tested with Python 3.7.2)


The tool is developed for the windows world. Therefore, it won't work correctly using linux.
Add the binary folders of Fiji and Python to the Windows path variable!

## Usage
cut the image, so only the concrete is visible.
The script is written to work with specimens with a size of 50 x 25 cm. 
If you are using 50 x 50 cm specimens, as proposed in the regularities, you have to change the number of rows and columns to 8x8.
You may experiment with other row/column values. However, the best results were achieved using 8 "tiles" for 50 cm.

run the script using the following parameters:

.\start_process.py [-h] [-i] [-r] [-c] [-p <poreBrightnessLimit>] [-d]
-h,                  : show this help
-i, --noImageJ       : skip ImageJ processing
-r                   : number of rows [8]
-c                   : number of columns [4]
-p                   : set pore brightness limit (0-255)
-d                   : show debug output

## Results
the overall results will be written to a csv file located in the working directory with the images. It is titled "results8x4.csv", depending on the set rows and columns.
It contains the filename and the corresponding results in a line.
