//To export GoPro metadata: https://tailorandwayne.com/GPMD2CSV
//TODO

import processing.video.*;
import processing.svg.*;

//Customisable
//IMPORTANT
//NOTE: remember to set the proper sketch size for your video in setup()
String[] filenames = {"GPFR0079","GF010079"};//file to search for, common to all files. Add more filename strings separated by commas if you want to merge them first
float vFov = 69.7;
//vertical field of view in degrees. H5 Session 16:9 = 69.7 |||||| 4:3 = 94.5  https://gopro.com/help/articles/Question_Answer/HERO5-Session-Field-of-View-FOV-Information
// H5 Black: https://gopro.com/help/articles/Question_Answer/HERO5-Black-Field-of-View-FOV-Information

//OPTIONAL
boolean CSVinstead = true;  //export csv with relevant values for use in After Effects or anywhere else. Differs from the input csv because the calculations are applied per frame
float goproRate = 25f;  //framerate of video will be overwritten if a video file with a different framerate is present. Important when working with frames only or csv only
PVector drift = new PVector(-0.0115070922,0.0090878531,0.0029803664); //rads per second that we should compensate. Might vary per camera and situation. Measured by sitting still and looking at the average values in the csv.
//The H5 does not have enough sensors to guess the absolute orientation, and there appears to be some drift caused by small inaccuracies that add up so an always flat horizon is only possible by manually adjusting drift, maybe)
//the gyro sensor maxes out at 8.7262316911 rad/s (83.33rpm) above that, calculations are wrong
PVector adjustAccl = new PVector(0.3071090151,-0.0826711669,0.1142378056);  //Accelerometer bias. Measured by leaving the camera flat on each side minus gravity. Might not be constant nor proportional. Might vary per camera
//Accl sensor maxes out at 78.3899521531 m/s2 (about 8G). Above that, data will be incorrect
float magnify = 1; //increase size to hide borders (there are better ways to hide / regenerate borders, with video editing software). 1 = no resize.
boolean embedData = false;  //whether or not metadata is printed on the output images (you see it anyway)
int firstDataFrame = 0;  //first frame to analyse from original GoPro file
boolean dataVideoSync = true; // False to start frames at 0 when stills have been extracted as a section of the original GoPro file
float rotationZoffset = radians(0);  //if horizon is generally tilted, compensate here. Radians
float realHeight = 0;//zero for auto (non optically corrected clips) //real use in pixels of the fov in the input file (useful when optically compensated) - (check in After Effects)
int offset = -30;//in milliseconds, can be float for better adjustment. difference in time between frames and csvs
String fileType = ".jpg";//extension
String videoFileType = ".mp4";//if loading from a video
int digits = 3;//number of zeros. Will be overwritten if frames are extracted from the video file
boolean rescale = false;  //scale to sketch size, independent of magnify. Useful when source is larger than sketch
float smooth = .95;//reduce x and y rotation progressively, 1 for not smoothing (image goes back to centre after a correction)
float smoothZ= .95;//reduce z rotation progressively, 1 = no reduction, 0 = no rotation
float limitY = .02;//limit movement per axis to percentage of image/angle. -1 = no limit. ie, avoid displaying too much margins
float limitX = .03;//if optically compensated, X can be wider
float limitZ = .06;//not really a percentage, -1 FOR FLAT HORIZON (MotoGP gyrocam style.
float[] AEgForces = new float[5];  //we will average data for smoothing
float[] AErpms = new float[5];  //we will average data for smoothing
float[] AEvibrhzs = new float[30];  //we will average data for smoothing
float vibrTreshold = 1; //subjective, when to start considering an acceleration change a vibration

void setup() {
  size(1280, 720);  //if exporting images, needs the same ratio as the input usable area, 16:9 4:3 etc
  imageMode(CENTER);  //draw from centre
  if (realHeight == 0) {
    realHeight = height;
  }
  realWidth = realHeight*(width/height);//for limiting movement
  pixelsPerRad = realHeight/radians(vFov);
  if (!CSVinstead) {  //only if exporting images
    File movieFile = new File(dataPath(filenames[0]+videoFileType));  //look for movie file
    if (movieFile.exists()) {  //check if a video file exists to launch it and deduce its info (duration, framerate)
      myMovie = new Movie(this, filenames[0]+videoFileType);  //start movie
      myMovie.play();
    } else {  //if no movie file we can continue
      finishSetup();
    }
  } else {  //if exporting full csv
    AEPosition = new Table();
    AEPosition.addColumn();  //will AE info
    AEPosition.addColumn();  //will contain frame number
    AEPosition.addColumn();  //will contain GyroX
    AEPosition.addColumn();  //will contain GyroY//
    
    TableRow newRow = AEPosition.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AEPosition.addRow();
    newRow.setString(0, "");
    newRow = AEPosition.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AEPosition.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AEPosition.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AEPosition.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEPosition.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEPosition.addRow();
    newRow.setString(0, "");
    newRow = AEPosition.addRow();
    newRow.setString(0, "Transform");
    newRow.setString(1, "Anchor Point");
    newRow = AEPosition.addRow();
    newRow.setString(1, "Frame");
    newRow.setString(2, "X pixels");
    newRow.setString(3, "Y pixels");
    newRow.setString(4, "Z pixels");
    
    AERotation = new Table();
    AERotation.addColumn();  //will AE info
    AERotation.addColumn();  //will contain frame number
    AERotation.addColumn();  //will contain GyroZ
    
    newRow = AERotation.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AERotation.addRow();
    newRow.setString(0, "");
    newRow = AERotation.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AERotation.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AERotation.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AERotation.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AERotation.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AERotation.addRow();
    newRow.setString(0, "");
    newRow = AERotation.addRow();
    newRow.setString(0, "Transform");
    newRow.setString(1, "Rotation");
    newRow = AERotation.addRow();
    newRow.setString(1, "Frame");
    newRow.setString(2, "degrees");
    
    AELocations = new Table();
    AELocations.addColumn();  //will AE info
    AELocations.addColumn();  //will contain frame number
    AELocations.addColumn();  //
    AELocations.addColumn();  //
    AELocations.addColumn();  //
    
    newRow = AELocations.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AELocations.addRow();
    newRow.setString(0, "");
    newRow = AELocations.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AELocations.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AELocations.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AELocations.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AELocations.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AELocations.addRow();
    newRow.setString(0, "");
    newRow = AELocations.addRow();
    newRow.setString(0, "Transform");
    newRow.setString(1, "Position");
    newRow = AELocations.addRow();
    newRow.setString(1, "Frame");
    newRow.setString(2, "X pixels");
    newRow.setString(3, "Y pixels");
    newRow.setString(4, "Z pixels");
    
    AEgForce = new Table();
    AEgForce.addColumn();  //will AE info
    AEgForce.addColumn();  //will contain frame number
    AEgForce.addColumn();  //will contain Gforce
    
    newRow = AEgForce.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AEgForce.addRow();
    newRow.setString(0, "");
    newRow = AEgForce.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AEgForce.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AEgForce.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AEgForce.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEgForce.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEgForce.addRow();
    newRow.setString(0, "");
    newRow = AEgForce.addRow();
    newRow.setString(0, "Effects");
    newRow.setString(1, "Slider Control #1");
    newRow.setString(2, "Slider #2");
    newRow = AEgForce.addRow();
    newRow.setString(1, "Frame");
  
    //populate smoothing array
    for (int i=0; i<AEgForces.length; i++) {
      AEgForces[i] = 0f;
    }  
    
    AErpm = new Table();
    AErpm.addColumn();  //will AE info
    AErpm.addColumn();  //will contain frame number
    AErpm.addColumn();  //will contain Gforce
    
    newRow = AErpm.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AErpm.addRow();
    newRow.setString(0, "");
    newRow = AErpm.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AErpm.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AErpm.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AErpm.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AErpm.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AErpm.addRow();
    newRow.setString(0, "");
    newRow = AErpm.addRow();
    newRow.setString(0, "Effects");
    newRow.setString(1, "Slider Control #1");
    newRow.setString(2, "Slider #2");
    newRow = AErpm.addRow();
    newRow.setString(1, "Frame");
  
    //populate smoothing array
    for (int i=0; i<AErpms.length; i++) {
      AErpms[i] = 0f;
    }  
    
    AEvibr = new Table();
    AEvibr.addColumn();  //will AE info
    AEvibr.addColumn();  //will contain frame number
    AEvibr.addColumn();  //
    AEvibr.addColumn();  //
    
    newRow = AEvibr.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AEvibr.addRow();
    newRow.setString(0, "");
    newRow = AEvibr.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AEvibr.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AEvibr.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AEvibr.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEvibr.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEvibr.addRow();
    newRow.setString(0, "");
    newRow = AEvibr.addRow();
    newRow.setString(0, "Transform");
    newRow.setString(1, "Anchor Point");
    newRow = AEvibr.addRow();
    newRow.setString(1, "Frame");
    newRow.setString(2, "X pixels");
    newRow.setString(3, "Y pixels");
    newRow.setString(4, "Z pixels");
    
    AEvibrhz = new Table();
    AEvibrhz.addColumn();  //will AE info
    AEvibrhz.addColumn();  //will contain frame number
    AEvibrhz.addColumn();  //will contain Gforce
    
    newRow = AEvibrhz.addRow();
    newRow.setString(0, "Adobe After Effects 8.0 Keyframe Data");
    newRow = AEvibrhz.addRow();
    newRow.setString(0, "");
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Units Per Second");
    newRow.setFloat(2, goproRate);
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Source Width");
    newRow.setInt(2, 100);
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Source Height");
    newRow.setInt(2, 100);
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Source Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Comp Pixel Aspect Ratio");
    newRow.setInt(2, 1);
    newRow = AEvibrhz.addRow();
    newRow.setString(0, "");
    newRow = AEvibrhz.addRow();
    newRow.setString(0, "Effects");
    newRow.setString(1, "Slider Control #1");
    newRow.setString(2, "Slider #2");
    newRow = AEvibrhz.addRow();
    newRow.setString(1, "Frame");
    
    //populate smoothing array
    for (int i=0; i<AEvibrhzs.length; i++) {
      AEvibrhzs[i] = 0f;
    }  


    firstDataFrame = 0;  //first frame to analyse from original GoPro file
    dataVideoSync = true; // False to start frames at 0 when stills have been extracted as a section of the original GoPro file
    digits = 3;//number of zeros. Will be overwritten if frames are extracted from the video file
    finishSetup();
  }
}

void draw() {
  if (setupFinished && (areFramesSaved || CSVinstead)) {  //process if all encesary info is loaded
    File stillsFile = null;
    int frameToLoad = 0;
    frameToLoad = currentFrame;
    if (!dataVideoSync) {  //copensate offsets
      frameToLoad -= firstDataFrame;
    } 
    
    stillsFile = new File(dataPath(filenames[0]+nf(frameToLoad,digits)+fileType));  //try to load frame
        
    if (stillsFile.exists() || CSVinstead) {  //if we still have images
      if (!CSVinstead) {  //if we want images
        currentImage = loadImage(filenames[0]+nf(frameToLoad,digits)+fileType);
      }
      float currentMilliseconds = ((float(currentFrame+1))*(1000f/goproRate))+offset;//time we are at
      PVector gyroDisplay = new PVector(0,0,0);  //will pass it to the display function
      if (lastRow < table.getRowCount()) {  //if we still have rows
        float gyroFrameTime = 0;//will remember total time of frame, independent of framerate, just in case
        ArrayList<float[]> gyroVectors = new ArrayList<float[]>();  //store the data to apply it proportionally after looping through all valid rows, for displaying it. Will be in rad/s, while the one for stabilisation (rotation) is in rad. so better not mixed
        while (float(table.getRow(lastRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
          float millisecondsDifference = (float(table.getRow(lastRow).getString("Milliseconds"))-lastMilliseconds)/1000f;  //how much time since last gyro?
          lastMilliseconds = float(table.getRow(lastRow).getString("Milliseconds"));  //save current time
          PVector preRotation = new PVector(float(table.getRow(lastRow).getString("GyroX")),float(table.getRow(lastRow).getString("GyroY")),float(table.getRow(lastRow).getString("GyroZ"))); //calculate perfect compensation of movements, (radians/time)*time passed
          preRotation.mult(millisecondsDifference);
          preRotation.sub(PVector.mult(drift, millisecondsDifference));  //compensate for drift
          PVector smoother = new PVector(1,1,1);  //if all goes well, apply fully
          if (limitX >= 0) {  //if we have set limitations to X
            if ((rotation.x > 0 && preRotation.x > 0) || (rotation.x < 0 && preRotation.x < 0)) {  //check if rotation is going to increase
              smoother.x = constrain(1-((abs(rotation.x)*pixelsPerRad)/(limitX*realWidth)),0,1);  //smooth more the closest we are to the limit
            }
          }
          if (limitY >= 0) {  //if we have set limitations to Y
            if ((rotation.y > 0 && preRotation.y > 0) || (rotation.y < 0 && preRotation.y < 0)) {//the same for Y
              smoother.y = constrain(1-((abs(rotation.y)*pixelsPerRad)/(limitY*realHeight)),0,1);
            }
          }
          if (limitZ >= 0) {  //if we have set limitations to X
            if ((rotation.z > 0 && preRotation.z > 0) || (rotation.z < 0 && preRotation.z < 0)) {
              smoother.z =constrain(1-(abs(rotation.z)/(limitZ*QUARTER_PI)),0,1);    //this is a bit subjective, quarter pi is not a full circle but otherwise the limit is clearly wider than in X and Y, might need a separate setting.
            }
          }
          rotation.x += smoother.x*preRotation.x;   //apply rotations
          rotation.y += smoother.y*preRotation.y;
          rotation.z += smoother.z*preRotation.z; 
          float[] gyroRow = { float(table.getRow(lastRow).getString("GyroX")),float(table.getRow(lastRow).getString("GyroY")),float(table.getRow(lastRow).getString("GyroZ")),millisecondsDifference};  //store all the relevant data of the row
          gyroVectors.add( gyroRow );  //save in the arraylist
          lastRow++;  //next row
          gyroFrameTime += millisecondsDifference;
          if (lastRow >= table.getRowCount()) {
            println("Gyro CSV finished before video");
            break;
          } 
        }
        
        for (int i = 0; i < gyroVectors.size() ; i++) {
          gyroDisplay.x += (gyroVectors.get(i)[0]*(gyroVectors.get(i)[3]/gyroFrameTime));  //multiply each row's gyro by its proportional weight in the frame time, probably more accurate if the gyro pace is not constant between frames/hertz
          gyroDisplay.y += (gyroVectors.get(i)[1]*(gyroVectors.get(i)[3]/gyroFrameTime));
          gyroDisplay.z += (gyroVectors.get(i)[2]*(gyroVectors.get(i)[3]/gyroFrameTime));
        }
        gyroDisplay.sub(drift);  //substract adjustments to correct sensor problems 
        gyroDisplay.div(TWO_PI);  //divide by one rev to get revs/second
        gyroDisplay.mult(60);  //multiply by 60 to get rpm
      } else {
        
        if (CSVinstead) {
          println("Finished Gyro CSV");
          finishedCSVs++;
          if (finishedCSVs >= 4) {
            finishCSVs();
          }
        } else {
          println("Skipping CSV");
        }
      }

      //accelerometer calculations
      PVector acclDisplay = new PVector(0,0,0); //for displaying data
      
      
      if (acclLastRow < acclTable.getRowCount()) {
        float acclFrameTime = 0;//will remember total time of frame
        ArrayList<float[]> acclVectors = new ArrayList<float[]>();  //store the data to apply it proportionally after looping through all valid rows
        int vibrationsInFrame = 0;
        while (float(acclTable.getRow(acclLastRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
          float millisecondsDifference = (float(acclTable.getRow(acclLastRow).getString("Milliseconds"))-acclLastMilliseconds)/1000f;  //how much time since last gyro?
          acclLastMilliseconds = float(acclTable.getRow(acclLastRow).getString("Milliseconds"));  //save current time
          float[] acclRow = { float(acclTable.getRow(acclLastRow).getString("AcclX")),float(acclTable.getRow(acclLastRow).getString("AcclY")),float(acclTable.getRow(acclLastRow).getString("AcclZ")),millisecondsDifference};  //store all the relevant data of the row
          acclVectors.add( acclRow );  //save in the arraylist
          PVector acclCurrent = new PVector(float(acclTable.getRow(acclLastRow).getString("AcclY")),float(acclTable.getRow(acclLastRow).getString("AcclX")),float(acclTable.getRow(acclLastRow).getString("AcclZ"))); //for measuring vibration
          boolean vibrated = false;
          if ((isPositive(acclCurrent.x) != isPositive(acclLast.x))) {  //measure acceleration changes in both the x and y axis to detect a vibration
            if (abs(acclCurrent.x-acclLast.x) > vibrTreshold) {
              vibrated = true;
            }
          }
          if ((isPositive(acclCurrent.y) != isPositive(acclLast.y))) {
            if (abs(acclCurrent.y-acclLast.y) > vibrTreshold) {
              vibrated = true;
            }
          }
          if ((isPositive(acclCurrent.z) != isPositive(acclLast.z))) {
            if (abs(acclCurrent.z-acclLast.z) > vibrTreshold) {
              vibrated = true;
            }
          }
          if (vibrated) vibrationsInFrame++;
          acclLast = acclCurrent.copy();
          acclLastRow++;  //next row
          acclFrameTime += millisecondsDifference;
          if (acclLastRow >= acclTable.getRowCount()) {
            if (CSVinstead) {
              println("Finished Accel CSV");
              finishedCSVs++;
              if (finishedCSVs >= 4) {
                finishCSVs();
              }
              break;
            } else {
              println("Accel CSV finished before video");
              break;
            }
            
          } 
        }
        vibrDisplay = vibrationsInFrame * goproRate;
        for (int i = 0; i < acclVectors.size() ; i++) {
          acclDisplay.x += (acclVectors.get(i)[0]*(acclVectors.get(i)[3]/acclFrameTime));  //multiply each row's acceleration by its proportional weight in the frame time, probably more accurate if the accl pace is not constant
          acclDisplay.y += (acclVectors.get(i)[1]*(acclVectors.get(i)[3]/acclFrameTime));
          acclDisplay.z += (acclVectors.get(i)[2]*(acclVectors.get(i)[3]/acclFrameTime));
        }
        acclDisplay.sub(adjustAccl);  //substract adjustments to correct sensor problems (might not be the best method, for example if bias is proportional)
        acclDisplay.div(9.80665);  //divide by gravity to express in Gs
      }
      //temperature calculations
      if (tempLastRow < tempTable.getRowCount()) {
        if (float(tempTable.getRow(tempLastRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
          tempLastMilliseconds = float(tempTable.getRow(tempLastRow).getString("Milliseconds"));  //save current time
          tempDisplay = float(tempTable.getRow(tempLastRow).getString("Temp"));  //update for displaying data,
          tempLastRow++;  //next row
          if (tempLastRow >= tempTable.getRowCount()) {
            if (CSVinstead) {
              println("Finished Temp CSV");
              finishedCSVs++;
              if (finishedCSVs >= 4) {
                finishCSVs();
              }
            } else {
              println("Temp CSV finished before video");
            }
            
          } 
        }
      }
      
      PVector gpsDisplay = new PVector(0,0,0);  //will pass it to the display function
      if (gpsLastRow < gpsTable.getRowCount()) {
        ///////////////////////////////////////
        float gpsFrameTime = 0;//will remember total time of frame, independent of framerate, just in case
        ArrayList<float[]> gpsVectors = new ArrayList<float[]>();  //store the data to apply it proportionally after looping through all valid rows, for displaying it. Will be in rad/s, while the one for stabilisation (rotation) is in rad. so better not mixed
        while (float(gpsTable.getRow(gpsLastRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
          float millisecondsDifference = (float(gpsTable.getRow(gpsLastRow).getString("Milliseconds"))-lastMilliseconds)/1000f;  //how much time since last gps?
          lastMilliseconds = float(gpsTable.getRow(gpsLastRow).getString("Milliseconds"));  //save current time
          float[] gpsRow = { cleanLatLon.get(gpsLastRow).x,cleanLatLon.get(gpsLastRow).y,cleanLatLon.get(gpsLastRow).z,millisecondsDifference};  //store all the relevant data of the row
          gpsVectors.add( gpsRow );  //save in the arraylist
          gpsLastRow++;  //next row
          gpsFrameTime += millisecondsDifference;
          if (gpsLastRow >= gpsTable.getRowCount()) {
            println("Gps CSV finished before video");
            break;
          } 
        }
        
        if (gpsVectors.size() < 1) {
          if (gpsLastRow+1 < gpsTable.getRowCount() && gpsLastRow > 0) {
            float millisecondsDifference = (float(gpsTable.getRow(gpsLastRow).getString("Milliseconds"))-lastMilliseconds)/1000f;  //how much time since last gps?
            float nextRowTime = float(gpsTable.getRow(gpsLastRow).getString("Milliseconds"));
            float timeTillNext = nextRowTime - lastMilliseconds;
            float lerping = millisecondsDifference / timeTillNext;
            gpsDisplay.x = lerp(cleanLatLon.get(gpsLastRow).x, cleanLatLon.get(gpsLastRow+1).x, lerping);
            gpsDisplay.y = lerp(cleanLatLon.get(gpsLastRow).y, cleanLatLon.get(gpsLastRow+1).y, lerping);
            gpsDisplay.z = lerp(cleanLatLon.get(gpsLastRow).z, cleanLatLon.get(gpsLastRow+1).z, lerping);
          } else if (gpsLastRow+1 >= gpsTable.getRowCount()) {
            gpsDisplay = cleanLatLon.get(gpsLastRow-1).copy();
          } else {
            gpsDisplay = cleanLatLon.get(gpsLastRow+1).copy();
          }
        } else {
          for (int i = 0; i < gpsVectors.size() ; i++) {
            gpsDisplay.x = (gpsVectors.get(i)[0]*(gpsVectors.get(i)[3]/gpsFrameTime));  //multiply each row's gps by its proportional weight in the frame time, probably more accurate if the gps pace is not constant between frames/hertz
            gpsDisplay.y = (gpsVectors.get(i)[1]*(gpsVectors.get(i)[3]/gpsFrameTime));
            gpsDisplay.z = (gpsVectors.get(i)[2]*(gpsVectors.get(i)[3]/gpsFrameTime));
          }
        }

      } else if (gpsTable.getRowCount() > 1) {
        gpsDisplay = cleanLatLon.get(cleanLatLon.size()-1).copy();
        if (CSVinstead) {
          println("Finished gps CSV");
          finishedCSVs++;
          if (finishedCSVs >= 4) {
            finishCSVs();
          }
        } else {
          println("Skipping CSV");
        }
      }
      
      TableRow newRowPos = null;
      TableRow newRowRot = null;
      TableRow newRowG = null;
      TableRow newRowRpm = null;
      TableRow newRowVibr = null;
      TableRow newRowVibrhz = null;
      TableRow newRowLoc = null;
      if (CSVinstead) {  //create new CSV row
        newRowPos = AEPosition.addRow();
        newRowPos.setInt(1, currentFrame+1);
        newRowRot = AERotation.addRow();
        newRowRot.setInt(1, currentFrame+1);
        newRowLoc = AELocations.addRow();
        newRowLoc.setInt(1, currentFrame+1);
        newRowG = AEgForce.addRow();
        newRowG.setInt(1, currentFrame+1);
        newRowRpm = AErpm.addRow();
        newRowRpm.setInt(1, currentFrame+1);
        newRowVibr = AEvibr.addRow();
        newRowVibr.setInt(1, currentFrame+1);
        newRowVibrhz = AEvibrhz.addRow();
        newRowVibrhz.setInt(1, currentFrame+1);
      }

    //let's draw  
      background(0);
      
      pushMatrix();
        translate(width/2, height/2);  //draw from centre
        while (rotation.y > PI) {  //simplify to +-360 degrees
          rotation.y -= TWO_PI;
        }
        while (rotation.y < -PI) {  //simplify to +-180 degrees
          rotation.y += TWO_PI;
        }
        while (rotation.x > PI) {
          rotation.x -= TWO_PI;
        }
        while (rotation.x < -PI) {
          rotation.x += TWO_PI;
        }
        while (rotation.z > PI) {
          rotation.z -= TWO_PI;
        }
        while (rotation.z < -PI) {
          rotation.z += TWO_PI;
        }
        rotation.x *= smooth;  //slowly go to the centre
        rotation.y *= smooth;
        rotation.z *= smoothZ;  //and straighten if we want so
        
        if (limitX >= 0) {  //if we have set limitations to X
          if (CSVinstead) {  //save to csv
            newRowPos.setFloat(2, -constrain(-rotation.x*pixelsPerRad,-limitX*realWidth,limitX*realWidth));
          } else {  //move image
            translate(constrain(-rotation.x*pixelsPerRad,-limitX*realWidth,limitX*realWidth),0);    //then translate X
          }
        } else {
          if (CSVinstead) {  //save to csv
            newRowPos.setFloat(2, -(-rotation.x*pixelsPerRad));
          } else {  //move image
            translate(-rotation.x*pixelsPerRad,0);    //then translate X
          }
        }
        if (limitY >= 0) {  //if we have set limitations to Y
          if (CSVinstead) {  //save to csv
            newRowPos.setFloat(3, -constrain(rotation.y*pixelsPerRad,-limitY*realHeight,limitX*realHeight));
            newRowPos.setInt(4, 0);
          } else {  //move image
            translate(0,constrain(rotation.y*pixelsPerRad,-limitY*realHeight,limitX*realHeight));    //then translate Y
          }
        } else {
          if (CSVinstead) {  //save to csv
            newRowPos.setFloat(3, -(rotation.y*pixelsPerRad));
            newRowPos.setInt(4, 0);
          } else {  //move image
            translate(0,rotation.y*pixelsPerRad);    //then translate Y
          }
        }
        if (limitZ >= 0) {  //if we have set limitations to X
          if (CSVinstead) {  //save to csv
            newRowRot.setFloat(2, degrees(constrain(-rotation.z,-limitZ*QUARTER_PI,limitZ*QUARTER_PI)+rotationZoffset));
          } else {  //move image
            rotate(constrain(-rotation.z,-limitZ*QUARTER_PI,limitZ*QUARTER_PI)+rotationZoffset);   //rotate first
          }
        } else {
          if (CSVinstead) {  //save to csv
            newRowRot.setFloat(2, degrees(-rotation.z+rotationZoffset));
          } else {  //move image
            rotate(-rotation.z+rotationZoffset);   //rotate first
          }
        }
        
        if (CSVinstead) {  //save to csv
          //add other info to AE tables//
          for (int i=AEgForces.length-1; i>0 ; i--) {
            AEgForces[i] = AEgForces[i-1];
          }
          if (Float.isNaN(acclDisplay.mag())) {
            AEgForces[0] = 0;
          } else {
            AEgForces[0] = acclDisplay.mag(); //optionally, change for one of the components
          }
          float total = 0;
          for (int i=0; i<AEgForces.length ; i++) {
            total += AEgForces[i];
          }
          float average = total/AEgForces.length;
          newRowG.setFloat(2, average);
          
          if (!(gpsDisplay.x == 0 && gpsDisplay.y == 0 && gpsDisplay.y == 0)) {
            newRowLoc.setFloat(2,gpsDisplay.x);
            newRowLoc.setFloat(3,gpsDisplay.y);
            newRowLoc.setFloat(4,gpsDisplay.z);
            gpsFramesArr.add(gpsDisplay);
          }

          //rpms
          for (int i=AErpms.length-1; i>0 ; i--) {
            AErpms[i] = AErpms[i-1];
          }
          if (Float.isNaN(gyroDisplay.mag())) {
            AErpms[0] = 0;
          } else {
            PVector loops = new PVector(gyroDisplay.y,gyroDisplay.z);
            AErpms[0] = loops.mag();  //optionally, change for one of the components
          }
          total = 0;
          for (int i=0; i<AErpms.length ; i++) {
            total += AErpms[i];
          }
          average = total/AErpms.length;
          newRowRpm.setFloat(2, average);
          
          newRowVibr.setFloat(2, acclDisplay.y);
          newRowVibr.setFloat(3, acclDisplay.x);
          newRowVibr.setFloat(4, acclDisplay.z);
          
          //
          for (int i=AEvibrhzs.length-1; i>0 ; i--) {
            AEvibrhzs[i] = AEvibrhzs[i-1];
          }
          if (Float.isNaN(vibrDisplay)) {
            AEvibrhzs[0] = 0;
          } else {
            AEvibrhzs[0] = vibrDisplay;
          }
          total = 0;
          for (int i=0; i<AEvibrhzs.length ; i++) {
            total += AEvibrhzs[i];
          }
          average = total/AEvibrhzs.length;
          newRowVibrhz.setFloat(2, average);
        }
        
        if (!CSVinstead) {  //if we want images
          if (rescale) {
            image(currentImage, 0,0, width*magnify, height*magnify);     //print image
          } else {
            image(currentImage, 0,0, currentImage.width*magnify, currentImage.height*magnify);     //print image
          }
        } else {  //save remainig data to csv
          /*newRow.setFloat(4, acclDisplay.x);
          newRow.setFloat(5, acclDisplay.y);
          newRow.setFloat(6, acclDisplay.z);
          newRow.setFloat(7, tempDisplay);*/
        }
        popMatrix();
      
      if (embedData) {  //print data on screen if not printed on image
        displayData(gyroDisplay,acclDisplay,tempDisplay,vibrDisplay,gpsDisplay);  //display metadata after saving the image
      }
      if (!CSVinstead) {
        saveFrame(filenames[0]+"-Out-"+nf(currentFrame,digits)+fileType);    //save it
      }
      if (!embedData) {  //print data on screen if not printed on image
        displayData(gyroDisplay,acclDisplay, tempDisplay, vibrDisplay,gpsDisplay);  //display metadata after saving the image
      }
      displayNonPritableData();
      currentFrame++;  //next frame
    } else {  //end of video
      println("Video finished");
      noLoop();
    }
  }
}
