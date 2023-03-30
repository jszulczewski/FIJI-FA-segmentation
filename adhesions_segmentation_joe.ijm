//added save FA_mask to current folder. 

//Segment adhesions
//This script assumes that the sensor is in channel 1 and the binder is in channel 2
//Inspired by this paper: https://doi.org/10.1016/j.mex.2014.06.004
name = getTitle();
sve=getDirectory("image");

close("ROI Manager");

run("Duplicate...", "title=image duplicate channels=1");

Boolean = getBoolean("Isolate cell for segmentation?");

if (Boolean == 1) {

	setTool("freehand");

	waitForUser("Draw ROI around cell");
	
	run("Make Inverse");
	
	run("Select None");
}

//Rolling ball background subtraction
run("Subtract Background...", "rolling=20 stack");

//Enhance local contrast
for (s = 1; s <= nSlices; s++) {
    setSlice(s);
    
    //Percent done
	percent = (s) / nSlices * 100;
	print("\\Clear");
	print(percent + " % Done");

	run("Enhance Local Contrast (CLAHE)", "blocksize=10 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
}

// Apply mathematical exponential (exp) to further minimize the background
run("Exp", "stack");

//Delete signal outside of cell
if (Boolean == 1) {

	//Loop through stack
	for (d = 1; d <= nSlices; d++) {
    	setSlice(d);
    	run("Restore Selection");
		run("Clear", "slice");
		run("Select None");
	}	
}

setAutoThreshold("Huang dark no-reset");
rename("mask");

waitForUser("Set threshold");

run("Convert to Mask", "method=Huang background=Light black");
selectWindow("mask");
saveAs("Tiff",sve+"/FA_mask.tif");
run("Analyze Particles...", "size=30-Infinity exclude clear include add stack");

close("mask"); 



//close("image");
selectWindow(name);

roiManager("Show All without labels");

