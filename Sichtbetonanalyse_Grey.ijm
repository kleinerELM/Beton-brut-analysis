// Macro for ImageJ 1.52i for Windows
// written by Florian Kleiner 2018 - 2019
// run from commandline as follows
// ImageJ-win64.exe -macro "C:\path\to\Sichtbetonanalyse.ijm" "D:\path\to\data\|rows|columns|poreBrightnessLimit"

function rotateAndResize( debugOutput ) {
	//////////////////////
	// handle image size and orientation (in case image is not square)
	//////////////////////
	width = getWidth();
	height = getHeight();
	if ( debugOutput ) { print( "  w x h : " + width + " x " + height ); }
	if (height<width) {
		if ( debugOutput ) { print( "  rotate!" ); }
		run("Rotate 90 Degrees Right");
		width = getWidth();
		height = getHeight();
		if ( debugOutput ) { print( "  w x h : " + width + " x " + height ); }
	}
	resultingWidth = round(maxSize / height * width);
	run("Size...", "height=" + maxSize + " width=" + resultingWidth + " constrain average interpolation=Bilinear");
	height = maxSize;
	width = resultingWidth;
}

function getFFTBinary( filename ) {
	// convert to 8bit grayscale
	if ( bitDepth() == 16 ) { // für 16 Bit-RGB-Stacks
		run("8-bit");
		run("RGB Color");
		run("8-bit");
		print( "  converted from 16 bit RGB to grayscale" );
	} else {
		run("8-bit");
		print( "  converted RGB to grayscale" );
	}
	print( "  creating FFT binary ..." );
	run("FFT");
	//saveAs("PNG", outputDir_FFT + baseName + "2.png");
	selectWindow( "FFT of " + filename);
	run("Smooth");
	run("Gaussian Blur...", "sigma=4");
	run("Gaussian Blur...", "sigma=4");
	run("Subtract Background...", "rolling=50 sliding");// oder 500 für ein gutes Binärbild
	run("Enhance Contrast...", "saturated=0.1");
	saveAs("PNG", outputDir_FFT + baseName + ".png");
	//setAutoThreshold("Intermodes dark");
	//setThreshold(128, 255);
	//run("Convert to Mask");
	//run("Erode");
	//run("Erode");
	//run("Dilate");
	//run("Dilate");
	//run("Dilate");
	//print( "  saving FFT binary ..." );
	//saveAs("PNG", outputDir_FFT + baseName + ".png");
	selectWindow( baseName + ".png" );
	close();
}

function processTiles( basename, channel, directory, cWidth, cHeight ) {
	run("Set Measurements...", "mean standard redirect=None decimal=3");
	for(k=0; k<columns; k++) {
		for(l=0; l<rows; l++) {
			startX = k*cWidth;
			startY = l*cHeight;

			makeRectangle(startX, startY, cWidth, cHeight);
			run("Measure");
		}
	}
	print( "    saving CSV (" + channel + ") ..." );
	selectWindow("Results");
	saveAs("Text", directory + basename + "_" + channel + ".csv");
	Table.deleteRows(0, (rows*columns));
}

function processLAB( filename ) {
	print( "  process LAB color space" );
	if ( bitDepth() == 16 ) { // für 16 Bit-RGB-Stacks
		// convert to 8bit color space RGB image
		run("8-bit");
		run("RGB Color");
		print( "    converted from 16-Bit RGB-Stack to 24-Bit RGB" );
	}
	run("Lab Stack");
	width = getWidth();
	height = getHeight();
	cWidth = round(width/columns);
	cHeight = round(height/rows);

	print( "    Calculate color uniformity ..." );
	// extract color channels
	run("Split Channels");

	// discard brightness channel
	selectWindow("C1-" + filename);
	close();
	
	basename = substring(filename, 0, lengthOf(filename)-4);
	channel = newArray( "C2", "C3" ); //C2:red-green-channel, C3: blue-yellow-channel
	for (i=0; i<channel.length; i++) {
		print( "    " + channel[i] );
		selectWindow(channel[i] + "-" + filename);
		processTiles( filename, channel[i], outputDir_Uniformity, cWidth, cHeight );
		selectWindow(channel[i] + "-" + filename);
		tiffName = basename + "-" + channel[i] + ".tif";
		rename( tiffName );
		saveAs("Tiff", outputDir_RGBW + tiffName);
		close();
	}
}

function processRGB( filename, channel ) {
	print( "  process RGB color space" );
	open(path);
	rotateAndResize( true );
	if ( bitDepth() == 16 ) { // für 16-Bit-RGB-Stacks
		// convert to 8-bit color space RGB image
		run("8-bit");
		run("RGB Color");
		print( "    converted from 16-Bit RGB-Stack to 24-Bit RGB" );
	}
	width = getWidth();
	height = getHeight();
	cWidth = round(width/columns);
	cHeight = round(height/rows);
				
	run("Split Channels");
	basename = substring(filename, 0, lengthOf(filename)-4);
	for (i=0; i<channel.length; i++) {
		//print( "    " + channel[i] );
		selectWindow(filename + " (" + channel[i] + ")");
		processTiles( filename, channel[i], outputDir_Uniformity, cWidth, cHeight );
		selectWindow(filename + " (" + channel[i] + ")");
		tiffName = basename + "-" + channel[i] + ".tif";
		rename( tiffName );
		saveAs("Tiff", outputDir_RGBW + tiffName);
		//close();
	}
}

macro "Sichtbetonanalyse" {
	// check if an external argument is given or define the options
	arg = getArgument(); 
	if ( arg == "" ) {
		dir = getDirectory("Choose a Directory");	
		//define number of slices for uniformity analysis
		rows = 8;
		columns = 4;
		poreBrightnessLimit = 51; // max threshold value to detect Pores
		doBackGroundCorrection = 1;
		disableBrightnessDifferenceCorrection = false;
	} else {
		arg_split = split(getArgument(),"|");
		dir = arg_split[0];
		rows = parseInt(arg_split[1]);
		columns = parseInt(arg_split[2]);
		poreBrightnessLimit = parseInt(arg_split[3]);
		doBackGroundCorrection = parseInt(arg_split[4]);
		disableBrightnessDifferenceCorrection = true;
	}
	doFFT = false;
	doLAB = false;
	percentileLimit = 0.05;
	desiredImageMean = 170; // target value for the average image brightness
	ignoreDifferenceRange = 0.0; // allowed brightness deviation which will be ignored during the brightness distribution analysis
	countMaxDifferenceLimit = 0.8;
	maxSize = 500; //resize oversized (or undersized) images to a defined resolution
	print("Starting Process using the following arguments...");
	print("Directory: " + dir);
	print("Rows: " + rows);
	print("Columns: " + columns);
	print("Pore Brightness Limit: " + poreBrightnessLimit);
	print("Histogram Difference Limit [%]: " + percentileLimit * 100);
	print("Desired mean image brightness: " + desiredImageMean);
	print("------------");
	outputDir_Corrected = dir + "/light_corrected/";
	outputDir_Uniformity = dir + "/CSV_Uniformity/";
	outputDir_RGBW = dir + "/RGBW/";
	outputDir_Threshold_Uniformity = dir + "/CSV_Threshold_Uniformity/";
	outputDir_PoresCSV = dir + "/CSV_Pores/";
	outputDir_PoresPNG = dir + "/PNG_Pores/";
	outputDir_FFT = dir + "/FFT_binary/";
	File.makeDirectory(outputDir_Corrected);
	File.makeDirectory(outputDir_Uniformity);
	File.makeDirectory(outputDir_RGBW);
	File.makeDirectory(outputDir_Threshold_Uniformity);
	File.makeDirectory(outputDir_PoresPNG);
	File.makeDirectory(outputDir_PoresCSV);
	File.makeDirectory(outputDir_FFT);
	list = getFileList(dir);
	setBatchMode(true);
	for (i=0; i<list.length; i++) {
		path = dir+list[i];
		showProgress(i, list.length);
		if (!endsWith(path,"/") && ( endsWith(path,".tif") || endsWith(path,".jpg") || endsWith(path,".JPG") ) ) {
			open(path);
			imageId = getImageID();
			if (nImages>=1) {
				//////////////////////
				// name definitions
				//////////////////////
				filename = getTitle();
				print( filename );
				baseName = substring(filename, 0, lengthOf(filename)-4);
				
				grayName = baseName + "-gray.tif";
				lightName = baseName + "-lightpattern.tif";
				normalizedName = baseName + "-normalized.tif";
				correctedName = baseName + "-corrected.tif";
				
				//////////////////////
				// extract FFT-Information
				//////////////////////
				if ( doFFT ) {
					getFFTBinary( filename );
					
					selectWindow(filename);
					close();
					open(path);
				}
				
				//////////////////////
				// extract LAB color channels
				//////////////////////
				if ( doLAB ) {
					processLAB( filename );
				}

				//////////////////////
				// extract RGB color channels
				//////////////////////
				channelRGB = newArray( "red", "green", "blue" );
				processRGB( filename, channelRGB );
				
				//reopen original image
				open(path);
				if ( bitDepth() == 16 ) { // für 16 Bit-RGB-Stacks
					// convert to 8bit color space RGB image
					run("8-bit");
					run("RGB Color");
					print( "  converted to RGB" );
				}
				imageId = getImageID();
				
				
				rotateAndResize( false );
				width = getWidth();
				height = getHeight();
				
				//////////////////////
				// extract grey-scale and correct lightning error
				//////////////////////
				path_corrected = outputDir_Corrected + substring(filename, 0, lengthOf(filename)-4)+".tif";
				if ( File.exists(path_corrected) ) {
					print( "  corrected grey-scale TIF already exits..." );
					close();
					open(outputDir_RGBW + grayName);
					imageId = getImageID();
					getStatistics(a, imageMean, min, max, std);//get statistics
					selectImage(imageId);
					close();
					open( path_corrected );
					imageId = getImageID();
					selectImage(imageId);
				} else {
					print( "  smoothing image, correcting brightness, normalize local contrast ..." );
					run("Smooth");
					run("8-bit");
					saveAs("Tiff", outputDir_RGBW + grayName);
					getStatistics(a, imageMean, min, max, std);//get statistics
					imageMeanDifference = desiredImageMean - imageMean;
					if ( imageMeanDifference < -0.5 * poreBrightnessLimit ) {
						print( "  big brightness difference detected! Pore analysis may be affected!" );
					}
					if ( imageMeanDifference > 0.5 * poreBrightnessLimit && !disableBrightnessDifferenceCorrection) {
						print( "  big brightness difference detected! Pore analysis may be affected! Trying to correct contrast ..." );
						hmin = 0;
						hmax = 255-(imageMeanDifference * 2);
						setMinAndMax(hmin, hmax); 
						print("  setMinAndMax(" + hmin + ", " + hmax + ")"); 
						//run("Apply LUT"); 
					}
					
					if ( imageMeanDifference < 0 ) {
						run("Subtract...", "value=" + round( imageMeanDifference * -1 ) );
					} else {
						if ( imageMeanDifference >0 ) {
							run("Add...", "value=" + round( imageMeanDifference ) );
						}
					}
					// saveAs("Tiff", outputDir_Corrected + substring(filename, 0, lengthOf(filename)-4)+"_brightness.tif" );
					if ( doBackGroundCorrection > 0 ) {
						//radius=round(width/10);
						radius=round(width/(columns/2));
						run("Normalize Local Contrast", "block_radius_x=" + radius + " block_radius_y=" + radius + " standard_deviations=10 center");
					}
					
					print( "  saving corrected grey-scale TIF..." );
					saveAs("Tiff", path_corrected );
				}
				
				//////////////////////
				// correct RGB-image
				//////////////////////
				getStatistics(a, norm_mean, min, max, norm_std);
				print("  Normalized mean: " + norm_mean + " +- " + norm_std );

				diff_mean = imageMean-norm_mean;
				print("  diff_mean: " + diff_mean);
				substr_mean = imageMean - 2*norm_std;

				run("Add...", "value=" + diff_mean); //set normalized image to grey mean
				print("  Add...: " + diff_mean );
				saveAs("Tiff", outputDir_RGBW + baseName + "A.tif");
				getStatistics(a, normA_mean, min, max, normA_std);//get statistics
				print("  normA_mean: " + normA_mean + " +- " + normA_std );

				run("Subtract...", "value=" + (normA_mean - 2 * norm_std));


				// structural image
				print("  Subtract...: " + (normA_mean - 2 * norm_std) );
				saveAs("Tiff", outputDir_RGBW + baseName + "B.tif");
				rename(normalizedName);

				open(outputDir_RGBW + grayName); //reopen gray
				rename(grayName);
				imageCalculator("Subtract create 32-bit", grayName, normalizedName);
				run("8-bit"); //reduce image bit depth
				getStatistics(a, light_mean, min, max, light_std);//get statistics
				print("  light_mean: " + light_mean + " +- " + light_std );
				
				//if ( !disableBrightnessDifferenceCorrection ) {
					// remove brightness differences in R G B
					run("Subtract...", "value=" + ( light_mean - 2*light_std ));
					print("  remove brightness differences in RGB. Subtracting " + ( light_mean - 2*light_std ) );
					run("Gaussian Blur...", "sigma=" + round(height*0.02) ); // smooth shades (radius: 2% of largest dimension)
					saveAs("Tiff", outputDir_RGBW + lightName);
					channelRGB = newArray( "red", "green", "blue" );
					for (i=0; i<channelRGB.length; i++) {
						print( "    calculate " + channelRGB[i] + " - light" );
						imageCalculator("Subtract", baseName + "-" + channelRGB[i] + ".tif", lightName);
						run("Add...", "value=" + 2*light_std); 
					}

					// remerge RGB Channels to color image
					run("Merge Channels...", "c1=[" + baseName + "-" + channelRGB[0] + ".tif] c2=[" + baseName + "-" + channelRGB[1] + ".tif] c3=[" + baseName + "-" + channelRGB[2] + ".tif]");
					saveAs("Tiff", outputDir_RGBW + correctedName);
					rename(filename);
				//}
				
				//////////////////////
				// calculate brightness-distribution (horizontal/vertical)
				//////////////////////
				
				open( path_corrected ); //reopen gray
				print( "  brightness distribution:" );
				greyMeanDiffX = 0;
				greyMeanDiffY = 0;
				highGreyMeanDiffXCount = 0;
				highGreyMeanDiffYCount = 0;
				borderDistance = round(width * 0.06); // Zwangsabstand
				brightnessValuesX = newArray(width-2*borderDistance);
				brightnessValuesY = newArray(height-2*borderDistance);
				brightnesSum = 0;
				Array.fill(brightnessValuesX, 0);
				Array.fill(brightnessValuesY, 0);
				
				print( "  - vertical..." );
				run("Clear Results");
				for (y=0; y<height-2*borderDistance; y++) {
					for (x=0; x<width-2*borderDistance; x++) {
						brightness = getPixel(x+borderDistance, y+borderDistance);
						brightnessValuesX[x] = brightnessValuesX[x] + brightness;
						brightnessValuesY[y] = brightnessValuesY[y] + brightness;
						brightnesSum = brightnesSum + brightness;
					}
				}
				greyMean = brightnesSum / ( ( height-2*borderDistance ) * ( width-2*borderDistance ) );
				for (y=0; y<width-2*borderDistance; y++) {
					setResult(0, y, brightnessValuesX[y]/(height-2*borderDistance));
					difference = abs( greyMean - brightnessValuesX[y]/(height-2*borderDistance));
					if ( ignoreDifferenceRange < difference ) {
						greyMeanDiffX = greyMeanDiffX + difference*difference;
					}
					if ( countMaxDifferenceLimit < difference ) {
						highGreyMeanDiffXCount++;
					}
				}
				
				print( "  saving vertical brightness distribution..." + greyMeanDiffX / (width-2*borderDistance) );
				updateResults();
				selectWindow("Results");
				saveAs("Text", outputDir_Threshold_Uniformity + substring(filename, 0, lengthOf(filename)-4) + "_meanBD_Vertical.csv");
				
				print( "  - horizontal..." );
				run("Clear Results");
				for (x=0; x<(height-2*borderDistance); x++) {
					setResult(0, x, brightnessValuesY[x]/(width-2*borderDistance));
					difference = abs( greyMean - brightnessValuesY[x]/(width-2*borderDistance));
					if ( ignoreDifferenceRange < difference ) {
						greyMeanDiffY = greyMeanDiffY + difference*difference;
					}
					if ( countMaxDifferenceLimit < difference ) {
						highGreyMeanDiffYCount++;
					}
				}
				
				print( "  saving horizontal brightness distribution..." + greyMeanDiffY / (height-2*borderDistance) );
				updateResults();
				selectWindow("Results");
				saveAs("Text", outputDir_Threshold_Uniformity + substring(filename, 0, lengthOf(filename)-4) + "_meanBD_Horizontal.csv");
				run("Clear Results");
				setResult(1, 0, "greyMeanDiffX");
				setResult(2, 0, "greyMeanDiffY");
				setResult(3, 0, "highGreyMeanDiffXCount");
				setResult(4, 0, "highGreyMeanDiffYCount");
				setResult(1, 0, greyMeanDiffX / (width-2*borderDistance));
				setResult(2, 0, greyMeanDiffY / (height-2*borderDistance));
				setResult(3, 0, highGreyMeanDiffXCount / (width-2*borderDistance)*100);
				setResult(4, 0, highGreyMeanDiffYCount / (height-2*borderDistance)*100);
				selectWindow("Results");
				saveAs("Text", outputDir_Threshold_Uniformity + substring(filename, 0, lengthOf(filename)-4) + "_meanBD.csv");
				
				
				// waitForUser("Stop", "Stop");
				
				//////////////////////
				// histogram analysis
				//////////////////////
				print( "  histogram analysis..." );
				run("Clear Results");
				cWidth = round(width/columns);
				cHeight = round(height/rows);
				rowCounter = 0;
				for(k=0; k<columns; k++) {
					for(l=0; l<rows; l++) {
						startX = k*cWidth;
						startY = l*cHeight;
						makeRectangle(startX, startY, cWidth, cHeight);
						getStatistics(area, mean, min, max, std, histogram);
						maxHistogramIndex = 0;
						limitHistogramIndex = 0;
						sumHistogramArea = 0;
						for (m=poreBrightnessLimit; m<histogram.length; m++) { // ignore typical pore area
							if ( histogram[maxHistogramIndex] < histogram[m] ) {
								maxHistogramIndex = m;
							}
							sumHistogramArea = sumHistogramArea + histogram[m];
							if ( ( limitHistogramIndex == 0 ) && ( sumHistogramArea/area > percentileLimit ) ) {
								limitHistogramIndex = m-1;
							}
						}
						indexDifference = maxHistogramIndex - limitHistogramIndex;
						
						setResult("MeanGrayValue", rowCounter, mean);
						setResult("MeanGrayStdDev", rowCounter, std);
						setResult("5%-Limit-Index", rowCounter, limitHistogramIndex);
						setResult("Max Index", rowCounter, maxHistogramIndex);
						setResult("difference", rowCounter, indexDifference);
						setResult("x", rowCounter, k);
						setResult("y", rowCounter, l);
						rowCounter = rowCounter +1;
					}
				}
				print( "  saving histogram analysis..." );
				updateResults();
				selectWindow("Results");
				saveAs("Text", outputDir_Threshold_Uniformity + substring(filename, 0, lengthOf(filename)-4) + "_histogrammStats.csv");
				run("Clear Results");
				
				makeRectangle(0, 0, width, height);
				run("Set Measurements...", "area area_fraction redirect=None decimal=5");
				
				path_pores = outputDir_PoresPNG + substring(filename, 0, lengthOf(filename)-4)+ "_" + poreBrightnessLimit + ".png";
				if ( File.exists( path_pores ) ) {
					print( "  Pore-TIF already exits..." );
					selectImage(imageId);
					close();
					open( path_pores );
					imageId = getImageID();
					selectImage(imageId);
				} else {
					setThreshold(0, poreBrightnessLimit);
					run("Convert to Mask");
					print( "  saving pores PNG ..." );
					saveAs("PNG", path_pores );
				}
				run("Measure");
				print( "  saving pores CSV ..." );
				selectWindow("Results");
				saveAs("Text", outputDir_PoresCSV + substring(filename, 0, lengthOf(filename)-4)+"_pores.csv");
				Table.deleteRows(0, 1);
				print( "  closing file ..." );
				selectImage(imageId);
				close();
				
				print( "" );
			}
		}
	}
	print("Done!");
	if ( arg != "" ) {
		//run("Quit");
	}
}
