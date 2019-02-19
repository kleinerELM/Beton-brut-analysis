import csv
import os
import subprocess
import tkinter as tk
from tkinter import filedialog
from subprocess import check_output

#global definitions
root = tk.Tk()
root.withdraw()

# define sektor grid
# 8 x 8 for a 500 x 500 mm area
rows = 8 
colums = 4

# turn off ImageJ analysis
runImageJ_Script = True #True

uniformity_dir = "/CSV_Uniformity/"
threshold_uniformity_dir = "/CSV_Threshold_Uniformity/"
pores_dir = "/CSV_Pores/"

home_dir = os.path.dirname(os.path.realpath(__file__))
print( "I am living in '" + home_dir + "'" )
directory = filedialog.askdirectory(title='Please select the data directory')
print( directory )
resultHeader = ""

def processScliceResults(filename, nameSuffix, rows, columns ):
    print( " analyse dataset " + nameSuffix )
    # grey scale analysis
    with open(directory + uniformity_dir + filename + "_" + nameSuffix + ".csv", 'r') as csv_file:
        # init vars
        csv_reader = csv.reader(csv_file)
        x = 0
        y = 0
        scliceArray = [[0 for i in range(rows)] for k in range(columns)]
        nDASize = (columns-1)*rows + columns*(rows-1) # Amount of neighbourDelta values in the array
        neighbourDeltaArray = [0 for i in range(nDASize)]
        brightnessSum = float(0)
        sigmaSum = float(0)
        neighbourDeltaSum = float(0)
        lineNr = 0
        print("  calculating mean color")
        for line in csv_reader:
            if lineNr > 0: #exclude table head
                brightnessSum += float(line[1])
                sigmaSum += float(line[2])
                scliceArray[x][y] = line[1] # stores the mean color/brightness value of a single sektor
                #print(x, y, line[1])
                x += 1
                if x >= columns :
                    y += 1
                    x = 0
            lineNr += 1
        #print(scliceArray)
        
        k = 0 # counter for neighbourDeltaArray
        print("  calculating horizontal neighour delta")
        neighbourDeltaMax = 0
        # horizontal neighour delta
        i = 0
        j = 0
        while i < columns:
            #print(i)
            while j < rows-1:
                #print(j, k)
                neighbourDeltaArray[k] = abs(float(scliceArray[i][j]) - float(scliceArray[i][j+1]))
                neighbourDeltaSum += neighbourDeltaArray[k]
                if neighbourDeltaMax < neighbourDeltaArray[k]:
                    neighbourDeltaMax = neighbourDeltaArray[k]
                #print(neighbourDeltaArray[k])
                k += 1
                j += 1
            i += 1
            j = 0

        print("  calculating vertical neighbour delta")
        # vertical neighbour delta
        i = 0
        j = 0
        while i < columns-1:
            #print(i)
            while j < rows:
                #print(j, k)
                neighbourDeltaArray[k] = abs(float(scliceArray[i][j]) - float(scliceArray[i+1][j]))
                neighbourDeltaSum += neighbourDeltaArray[k]
                if neighbourDeltaMax < neighbourDeltaArray[k]:
                    neighbourDeltaMax = neighbourDeltaArray[k]
                #print(neighbourDeltaArray[k])
                k += 1
                j += 1
            i += 1
            j = 0

        brightnessMean = brightnessSum / lineNr
        sigmaMean = sigmaSum / lineNr
        neighbourDelta = neighbourDeltaSum / nDASize
        neighbourDeltaPercent = neighbourDelta / brightnessMean * 100
        neighbourDeltaMaxPercent = neighbourDeltaMax / brightnessMean * 100
        sigmaMeanPercent = sigmaMean / brightnessMean * 100
        
        #return str( "%f" % neighbourDelta) + "," + str( "%f" % neighbourDeltaMax) + ", " + str( "%f" % neighbourDeltaPercent) + ", " + str( "%f" % neighbourDeltaMaxPercent) + ", " + str( "%f" % sigmaMean) + ", " + str( "%f" % sigmaMeanPercent) + ", " + str( "%f" % brightnessMean)+ ", "
        result = str( "%f" % neighbourDeltaPercent) + ", " + str( "%f" % neighbourDeltaMaxPercent) + ", " + str( "%f" % sigmaMeanPercent) + ", "
        print("  " + nameSuffix + " results: " + result)
        return result

def processThresholdScliceResults(filename, nameSuffix, rows, columns ):
    print( " analyse dataset " + nameSuffix )
    # grey scale analysis
    with open(directory + threshold_uniformity_dir + filename + "_" + nameSuffix + ".csv", 'r') as csv_file:
        # init vars
        csv_reader = csv.reader(csv_file)
        x = 0
        y = 0
        scliceDiffArray = [[0 for i in range(rows)] for k in range(columns)]
        nDASize = (columns-1)*rows + columns*(rows-1) # Amount of neighbourDelta values in the array
        neighbourDeltaDiffArray = [0 for i in range(nDASize)]
        neighbourDeltaDiffSum = float(0)
        areaSum = float(0)
        countSum = 0
        lineNr = 0
        
        differenceSum = 0
        differenceMin = 256
        differenceMax = 0
        
        print("  reading CSV")
        for line in csv_reader:
            if lineNr > 0: #exclude table head
                differenceSum += int( line[5] )
                if differenceMin > int( line[5] ):
                    differenceMin = int( line[5] )
                if differenceMax < int( line[5] ):
                    differenceMax = int( line[5] )
                scliceDiffArray[x][y] = int(  line[5] ) #.replace("NaN", "0") ) # stores the Difference value of a single sektor
                x += 1
                if x >= columns :
                    y += 1
                    x = 0
            lineNr += 1
        
        k = 0 # counter for neighbourDeltaArray
        print("  calculating horizontal neighbor delta")
        neighbourDeltaDiffMax = 0
        # horizontal neighbor delta
        i = 0
        j = 0
        while i < columns:
            while j < rows-1:
                neighbourDeltaDiffArray[k] = abs(float(scliceDiffArray[i][j]) - float(scliceDiffArray[i][j+1]))
                neighbourDeltaDiffSum += neighbourDeltaDiffArray[k]
                if neighbourDeltaDiffMax < neighbourDeltaDiffArray[k]:
                    neighbourDeltaDiffMax = neighbourDeltaDiffArray[k]
                k += 1
                j += 1
            i += 1
            j = 0

        print("  calculating vertical neighbor delta")
        # vertical neighbor delta
        i = 0
        j = 0
        while i < columns-1:
            while j < rows:
                neighbourDeltaDiffArray[k] = abs(float(scliceDiffArray[i][j]) - float(scliceDiffArray[i+1][j]))
                neighbourDeltaDiffSum += neighbourDeltaDiffArray[k]
                if neighbourDeltaDiffMax < neighbourDeltaDiffArray[k]:
                    neighbourDeltaDiffMax = neighbourDeltaDiffArray[k]
                k += 1
                j += 1
            i += 1
            j = 0

        neighbourDeltaDiff = neighbourDeltaDiffSum / nDASize
        #neighbourDeltaDiffPercent = neighbourDelta / brightnessMean * 100
        #neighbourDeltaDiffMaxPercent = neighbourDeltaDiffMax / brightnessMean * 100
        #sigmaMeanPercent = sigmaMean / brightnessMean * 100
        
        #return str( "%f" % neighbourDelta) + "," + str( "%f" % neighbourDeltaMax) + ", " + str( "%f" % neighbourDeltaPercent) + ", " + str( "%f" % neighbourDeltaMaxPercent) + ", " + str( "%f" % sigmaMean) + ", " + str( "%f" % sigmaMeanPercent) + ", " + str( "%f" % brightnessMean)+ ", "
        result = str( "%f" % neighbourDeltaDiff) + ", " + str( "%f" % neighbourDeltaDiffMax ) + ", " + str( "%f" % ( differenceSum / ( rows * columns ) ) ) + ", " + str( "%f" % differenceMin ) + ", " + str( "%f" % differenceMax ) + ", " 
        print("  " + nameSuffix + " results: " + result)
        return result

def processData(filename, rows, columns):
    print("------")
    print(filename)
    # pore analysis
    with open(directory + pores_dir + filename + "_pores.csv", 'r') as csv_file:
        csv_reader = csv.reader(csv_file)

        Area = 0
        poreAreaPercent = float(0)
        lineNr = 0
        imageArea = 0
        print(" analysing dataset pores")
        for line in csv_reader:
            if ( lineNr > 0 and line[1] != "" ): # line 1 is somehow not always the wanted result its always in the last line
                imageArea = line[1]
                poreAreaPercent = float(line[2])
            lineNr += 1
        poreResult = str( imageArea ) + ", " + str( poreAreaPercent )
        print("  pore results: " + poreResult)
    with open(directory + threshold_uniformity_dir + filename + "_meanBD.csv", 'r') as csv_file:
        csv_reader = csv.reader(csv_file)

        Area = 0
        poreAreaPercent = float(0)
        lineNr = 0
        imageArea = 0
        print(" analysing dataset mean brightness distribution")
        for line in csv_reader:
            if ( lineNr > 0 ): 
                verticalMeanBD = float( line[1] )
                horizontalMeanBD = float( line[2] )
                meanBDhighXPercent = float( line[3] )
                meanBDhighYPercent = float( line[4] )
            lineNr += 1
        meanBD = str( verticalMeanBD ) + ", " + str( horizontalMeanBD ) + ", " + str( meanBDhighXPercent ) + ", " + str( meanBDhighYPercent )
        print("  mean brightness distribution results: " + meanBD)
    # grey scale analysis
    resultLine = os.path.splitext(filename)[0] + ", "
    # resultLine = resultLine + processScliceResults(filename, "uniformity", rows, columns )
    
    #resultLine = resultLine + processThresholdScliceResults(filename, "visualdefects_high", rows, columns )
    resultLine = resultLine + processThresholdScliceResults(filename, "histogrammStats", rows, columns )
    
    # color (Lab) analysis (a - red-green)
    #resultLine = resultLine + processScliceResults(filename, "a", rows, columns )
    # color (Lab) analysis (b - blue-yellow)
    #resultLine = resultLine + processScliceResults(filename, "b", rows, columns )
    
    resultLine = resultLine + meanBD + "," + poreResult
    
    #create result csv line
    csv_file = open(directory + '/results' + str(rows) + "x" + str(colums) + '.csv', 'a')
    csv_file.write( resultLine + "\n" )
    csv_file.close()
    #with open(directory + '/results' + str(rows) + "x" + str(colums) + '.csv', 'a', newline='') as csvfile:
    #    spamwriter = csv.writer(csvfile, delimiter=',',
    #                            quotechar='|', quoting=csv.QUOTE_MINIMAL)
    #    #spamwriter.writerow(['name', 'neighbourDelta', 'neighbourDeltaMax', 'neighbourDeltaPercent', 'neighbourDeltaMaxPercent', 'sigmaMean', 'sigmaMeanPercent', 'brightnessMean', 'imageArea', 'poreAreaPercent'])
    #    spamwriter.writerow(resultLine)

#main process
if os.path.isdir(directory):
    if ( runImageJ_Script ):
        command = "..\Fiji.app\ImageJ-win64.exe -macro \"" + home_dir +"\Sichtbetonanalyse_Grey.ijm\" \"" + directory + "/|" + str(rows) + "|" + str(colums) + "\""
        print( "starting ImageJ Macro..." )
        try:
            subprocess.check_output(command, shell=True, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            print( "Error" )#"returned error (code {}): {}".format(e.returncode, e.output))
            pass
        #command = "..\Fiji.app\ImageJ-win64.exe -macro \"" + home_dir +"\Sichtbetonanalyse_Color.ijm\" \"" + directory + "/|" + str(rows) + "|" + str(colums) + "\""
        #print( command )
        #check_output(command, shell=True)
    if os.path.isdir(directory+uniformity_dir):
        csv_file = open(directory + '/results' + str(rows) + "x" + str(colums) + '.csv', 'w')
        # csv_file.write( 'name, neighbourDeltaPercent, neighbourDeltaMaxPercent, sigmaMeanPercent, neighbourDeltaDiff_T_Low, neighbourDeltaDiffMax_T_Low, areaSum_T_Low, countSum_T_Low, imageArea, poreAreaPercent' + "\n" )
        csv_file.write( 'name, neighbourDeltaDiff, neighbourDeltaDiffMax, differenceMean, differenceMin, differenceMax, verticalMeanBD, horizontalMeanBD,MeanBDHighXPercent,MeanBDHighYPercent, imageArea, poreAreaPercent' + "\n" )
        
        csv_file.close()
        #with open(directory + '/results' + str(rows) + "x" + str(colums) + '.csv', 'w', newline='') as csvfile:
        #    spamwriter = csv.writer(csvfile, delimiter=',',
        #                                    quotechar='|', quoting=csv.QUOTE_MINIMAL)
        #    #spamwriter.writerow(['name', 'neighbourDelta', 'neighbourDeltaMax', 'neighbourDeltaPercent', 'neighbourDeltaMaxPercent', 'sigmaMean', 'sigmaMeanPercent', 'brightnessMean', 'imageArea', 'poreAreaPercent'])
        #    spamwriter.writerow(['name', 'neighbourDeltaPercent', 'neighbourDeltaMaxPercent', 'sigmaMeanPercent', 'neighbourDelta_T_High', 'neighbourDeltaMax_T_High', 'neighbourDelta_T_Low', 'neighbourDeltaMax_T_Low', 'imageArea', 'poreAreaPercent'])

        for file in os.listdir(directory):
            filename = os.fsdecode(file)
            if ( filename.endswith(".jpg") or filename.endswith(".JPG") or filename.endswith(".tif") or filename.endswith(".TIF")):
                csv_filename = os.path.splitext(filename)[0]
                if os.path.exists( directory + threshold_uniformity_dir +csv_filename + "_histogrammStats.csv" ) and os.path.exists( directory + pores_dir +csv_filename + "_pores.csv" ):
                    processData( csv_filename, rows, colums )
                else:
                    print(csv_filename +"_histogrammStats.csv not found!")
            else:
                print(filename + " is no Jpg / Tiff! Skipping!")
    else:
        print("Folder '" + uniformity_dir + "' does not exist! Run ImageJ Macro first!")
else:
    print("Folder '" + directory + "' does not exist! Run ImageJ Macro first!")

print("-------")
print("DONE!")
