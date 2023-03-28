//Set path for saving results
path = "C:/Users/gabek/Dropbox/sptScope/2023-03-27_GK_MDA-MB-231_Talin-linker_GFP-Binder/analyzed/processed/";

//Flatfield correction and automatic correction factor calculation --------------------------------
name = getTitle();

selectWindow("blank");
run("Duplicate...", "title=Blank duplicate");
run("Split Channels");

selectWindow("C1-Blank");
getStatistics(area, mean1, min, max, std, histogram);

selectWindow("C2-Blank");
getStatistics(area, mean2, min, max, std, histogram);

selectWindow(name);
run("Split Channels");

run("Calculator Plus", "i1=[C1-"+name+"] i2=C1-Blank operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+mean1+" k2=0 create");
rename("C1-Result");

run("Calculator Plus", "i1=[C2-"+name+"] i2=C2-Blank operation=[Divide: i2 = (i1/i2) x k1 + k2] k1="+mean2+" k2=0 create");
rename("C2-Result");

run("Merge Channels...", "c1=C1-Result c2=C2-Result create");

rename(name);

run("Re-order Hyperstack ...", "channels=[Channels (c)] slices=[Frames (t)] frames=[Slices (z)]");

close("C1-Blank");
close("C2-Blank");
close("C1-"+name);
close("C2-"+name);

//Correct jitters or 3D drift ---------------------------------------------------------------------
//jitterCorrction = getBoolean("Correct jitters or drift?");
//	if (jitterCorrction==1) {
//		name = getTitle();
//		
//		getDimensions(width, height, channels, slices, frames);
//		
//		waitForUser("Draw an ROI for drift correction");
//		
//		run("Correct 3D drift", "channel=1 only=0 lowest=1 highest=1 max_shift_x=10.000000000 max_shift_y=10.000000000 max_shift_z=10");
//		
//		close(name);
//		
//		selectWindow("registered time points");
//		
//		rename(name);
//		
//		makeRectangle(0, 0, width, height);
//		
//		waitForUser("Move the Roi for cropping");
//		
//		run("Crop");
//	}

//Background subtraction --------------------------------------------------------------------------
setTool("rectangle");

//Min Max reset loop
getDimensions(width, height, channels, slices, frames);
for (c = 1; c <= channels; c++) {
    Stack.setChannel(c);
    resetMinAndMax();
}

Stack.setDisplayMode("color");

waitForUser("Background subtraction: Draw an ROI to indicate the background, then press OK");

//Background subtraction loop
for (i=1; i<=nSlices; i++) {

 setSlice(i);

 getStatistics(area, mean);

 run("Select None");

 run("Subtract...", "value="+mean);

 run("Restore Selection");

 }

run("Select None");

//Min Max reset loop
getDimensions(width, height, channels, slices, frames);
for (c = 1; c <= channels; c++) {
    Stack.setChannel(c);
    resetMinAndMax();
}

// Define cell for analysis so that other cells can be deleted --------------------------------
setTool("polygon");
waitForUser("Draw an ROI around the cell, then press OK");

run("Set Measurements...", "area mean integrated display redirect=None decimal=5");

run("Clear Results");
Stack.setChannel(1);
run("Measure");

Stack.setChannel(2);
run("Measure");

name = replace(name, ".tif", "");
name = replace(name, '"', "");
name = replace(name, " ", "_");

saveAs("Results", path + "Ratio_" + name + ".csv");
 
run("Select None");
 
setTool("rectangle");
 
 //Min Max reset loop
getDimensions(width, height, channels, slices, frames);
for (c = 1; c <= channels; c++) {
    Stack.setChannel(c);
    resetMinAndMax();
}

//Segment adhesions ------------------------------------------------------------------------------
name = getTitle();

run("Duplicate...", "title=image duplicate channels=1");

run("Subtract Background...", "rolling=20 stack");

for (s = 1; s <= nSlices; s++) {
    setSlice(s);
    
    //Percent done
	percent = (s) / nSlices * 100;
	print("\\Clear");
	print(percent + " % Done");

	run("Enhance Local Contrast (CLAHE)", "blocksize=10 histogram=256 maximum=3 mask=*None* fast_(less_accurate)");
}

run("Exp", "stack");

//Delete signal outside of cell
run("Restore Selection");
run("Make Inverse");
run("Select None");
for (d = 1; d <= nSlices; d++) {
    setSlice(d);
    run("Restore Selection");
	run("Clear", "slice");
	run("Select None");
}

setAutoThreshold("Huang dark no-reset");

waitForUser("set threshold");

run("Convert to Mask", "method=Huang background=Light black");

run("Analyze Particles...", "size=30-Infinity exclude clear include add stack");

close("image");

//Inpaint background subtraction ------------------------------------------------------------
setBatchMode("hide");

selectImage(name);
run("Split Channels");
selectImage("C1-"+name);
rename("binder");
selectImage("C2-"+name);
rename("tag");

getDimensions(width, height, channels, slices, frames);

newImage("Ratio", "32-bit black", width, height, frames); // Make new blank canvas

//Loop through rois
n = roiManager('count');
for (r = 0; r < n; r++) {

//Percent done
percent = (r + 1) / n * 100;
print("\\Clear");
print(percent + " % Done");


//Binder processing -------------------
selectWindow("binder");
    
roiManager('select', r);

run("Enlarge...", "enlarge=1 ");

run("Duplicate...", "title=temp1");

run("Duplicate...", "title=mask");

run("Duplicate...", "title=adhesion_binder");

//make adhesion image
selectImage("adhesion_binder");
run("Enlarge...", "enlarge=-1");
roiManager("Add");
run("Make Inverse");
selectImage("adhesion_binder");
run("Clear", "slice");
run("Select None");

//make mask image
selectImage("mask");
run("Enlarge...", "enlarge=-1");
run("Make Inverse");
selectImage("mask");
run("Clear", "slice");
run("Select None");
setThreshold(1, 65535, "raw");
run("Convert to Mask");
run("Divide...", "value=255");

//make background images
selectImage("temp1");
run("Enlarge...", "enlarge=-1");
run("Clear", "slice");
run("Enlarge...", "enlarge=1");
run("Make Inverse");
selectImage("temp1");
run("Clear", "slice");
run("Select None");

run("32-bit");

setThreshold(0.000000001, 1000000000000000000000000000000.000000000);

run("NaN Background");

run("Duplicate...", "title=temp2");

selectImage("temp1");

getDimensions(width, height, channels, slices, frames);

for (i = 0; i < height; i++) {
	for (l = 0; l < width; l++) {

		makeRectangle(l, i, 1, 1);

		getRawStatistics(nPixels1, mean1, min1, max1, std1, histogram1);

		run("Make Band...", "band=1");

		getRawStatistics(nPixels2, mean2, min2, max2, std2, histogram2);

		run("Undo");

		NAN = isNaN(mean1);

		if (NAN) {
		setPixel(l, i, mean2);
		}
	}
}

selectImage("temp2");

getDimensions(width, height, channels, slices, frames);

for (i = height-1; i >= 0; i--) {
	for (l = width-1; l >= 0; l--) {

		makeRectangle(l, i, 1, 1);

		getRawStatistics(nPixels1, mean1, min1, max1, std1, histogram1);

		run("Make Band...", "band=1");

		getRawStatistics(nPixels2, mean2, min2, max2, std2, histogram2);

		run("Undo");

		NAN = isNaN(mean1);

		if (NAN) {
		setPixel(l, i, mean2);
		}
	}
}

//calculate background and cleanup
imageCalculator("Average", "temp1","temp2");

selectImage("temp1");

run("Conversions...", " ");
run("16-bit");

close("temp2");

// build background correction image
selectImage("temp1");

imageCalculator("Multiply", "temp1","mask");
close("mask");

imageCalculator("Subtract 32-bit", "adhesion_binder","temp1");

close("temp1");
close("adhesion_binder");

//tag processing -------------------
selectWindow("tag");
    
roiManager('select', r);

run("Enlarge...", "enlarge=1");

run("Duplicate...", "title=temp1");

run("Duplicate...", "title=mask");

run("Duplicate...", "title=adhesion_tag");

//make adhesion image
selectImage("adhesion_tag");
run("Enlarge...", "enlarge=-1");
run("Make Inverse");
selectImage("adhesion_tag");
run("Clear", "slice");
run("Select None");

//make mask image
selectImage("mask");
run("Enlarge...", "enlarge=-1");
run("Make Inverse");
selectImage("mask");
run("Clear", "slice");
run("Select None");
setThreshold(1, 65535, "raw");
run("Convert to Mask");
run("Divide...", "value=255");

//make background images
selectImage("temp1");
run("Enlarge...", "enlarge=-1");
run("Clear", "slice");
run("Enlarge...", "enlarge=1");
run("Make Inverse");
selectImage("temp1");
run("Clear", "slice");
run("Select None");

run("32-bit");

setThreshold(0.000000001, 1000000000000000000000000000000.000000000);

run("NaN Background");

run("Duplicate...", "title=temp2");

selectImage("temp1");

getDimensions(width, height, channels, slices, frames);

for (i = 0; i < height; i++) {
	for (l = 0; l < width; l++) {

		makeRectangle(l, i, 1, 1);

		getRawStatistics(nPixels1, mean1, min1, max1, std1, histogram1);

		run("Make Band...", "band=1");

		getRawStatistics(nPixels2, mean2, min2, max2, std2, histogram2);

		run("Undo");

		NAN = isNaN(mean1);

		if (NAN) {
		setPixel(l, i, mean2);
		}
	}
}

selectImage("temp2");

getDimensions(width, height, channels, slices, frames);

for (i = height-1; i >= 0; i--) {
	for (l = width-1; l >= 0; l--) {

		makeRectangle(l, i, 1, 1);

		getRawStatistics(nPixels1, mean1, min1, max1, std1, histogram1);

		run("Make Band...", "band=1");

		getRawStatistics(nPixels2, mean2, min2, max2, std2, histogram2);

		run("Undo");

		NAN = isNaN(mean1);

		if (NAN) {
		setPixel(l, i, mean2);
		}
	}
}

//calculate background and cleanup
imageCalculator("Average", "temp1","temp2");

selectImage("temp1");

run("Conversions...", " ");
run("16-bit");

close("temp2");

// build background correction image
selectImage("temp1");

imageCalculator("Multiply", "temp1","mask");
close("mask");

imageCalculator("Subtract 32-bit", "adhesion_tag","temp1");

close("temp1");
close("adhesion_tag");

//Calculate ratio ------------------------------------------------------------------------------

imageCalculator("Divide 32-bit", "Result of adhesion_tag","Result of adhesion_binder");
close("Result of adhesion_binder");

//Paste adhesion into blank image
selectImage("Result of adhesion_tag");
roiManager("Select", n);
run("Copy");
selectImage("Ratio");
roiManager("Select", r);
run("Enlarge...", "enlarge=1");
run("Enlarge...", "enlarge=-1");
run("Paste");

//Delete temp roi
roiManager("Select", n);
roiManager("Delete");
run("Select None");

close("Result of adhesion_tag");
}

close("binder");
close("tag");

setBatchMode("exit and display");

//Set the scale to a defined amount -------------------------------------
selectWindow("Ratio");

run("Remove Overlay");

setMinAndMax(0.00, 0.50);

run("16_colors");

//Save data
name = replace(name, ".tif", "");
name = replace(name, '"', "");
name = replace(name, " ", "_");

saveAs("tiff", path + "Ratio_" + name + ".tif");
roiManager("save", path + "Ratio_" + name + ".zip");

//close();