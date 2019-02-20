Table addExtraFiles(Table table, String s) {
//add rows from  extra files
    if (filenames.length > 1) {
      for (int i=1; i<filenames.length; i++ ) {
        File extraFile = new File(dataPath(filenames[i]+"-"+s+".csv"));  //try to load CSV file
        if (extraFile.exists()) {
          Table extraTable = loadTable(filenames[i]+"-"+s+".csv", "header");
          int previousLength = table.getRowCount();
          float lastMillis = table.getRow(table.getRowCount()-1).getFloat("Milliseconds");
          table.setRowCount(previousLength+extraTable.getRowCount());
          float offsetMillis = table.getRow(0).getFloat("Milliseconds");
          float millisToAdd = lastMillis - offsetMillis;
          // add milliseconds to extra table
          for (int j=0; j<extraTable.getRowCount();j++) {
            TableRow row = extraTable.getRow(j);
            float currVal = row.getFloat("Milliseconds");
            row.setString("Milliseconds",str(currVal+millisToAdd));
            TableRow newRow = table.getRow(previousLength+j);
            for (int k=0; k<row.getColumnCount(); k++) {
              newRow.setString(k,row.getString(k));
            }
          }
        } else {
          println("No "+filenames[i]+"-"+s+".csv file found in /data");
        }
      }
    }
    return table;
}

void finishSetup() {  //we need to receive a movie frame to use its info (duration, framerate...) before we finish loading
  File csvFile = new File(dataPath(filenames[0]+"-gyro.csv"));  //try to load CSV file
  if (csvFile.exists()) {
    table = loadTable(filenames[0]+"-gyro.csv", "header");
    table = addExtraFiles(table,"gyro");
    //find first row to analyse
    float currentMilliseconds = ((float(firstDataFrame))*(1000f/goproRate))+offset;//time we start at
    int checkRow = 0;
    while (float(table.getRow(checkRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
      checkRow++;
      lastMilliseconds = float(table.getRow(checkRow).getString("Milliseconds"));  //save current time
    }
    lastRow = checkRow;
    currentFrame = firstDataFrame;
    //create frames if they don't exist
    validFrame = currentFrame;  //frame count taking offsets into account
    if (!dataVideoSync) {
      validFrame -= firstDataFrame;
    }
    
    if (!CSVinstead) {  //only if exporting images
      File stillsFile = new File(dataPath(filenames[0]+nf(validFrame,digits)+fileType));  //try to load necessary video files
      File movieFile = new File(dataPath(filenames[0]+videoFileType));
      if (stillsFile.exists()) {
        areFramesSaved = true;  //we can start
        int iter = 0;
        while (stillsFile.exists()) {
          stillsFile = new File(dataPath(filenames[0]+nf(validFrame+iter,digits)+fileType));  //try to load necessary video files
          iter++;
          totalFrames = iter;
        }
        
      } else if ( !movieFile.exists()) {  //otherwise
        println("No video file "+filenames[0]+videoFileType+" found in /data");
      }
    } else {  //if exporting full csv
      totalFrames = int(int(table.getRow(table.getRowCount()-1).getString("Milliseconds"))*goproRate/1000);
    }
  } else {
    println("No "+filenames[0]+"-gyro.csv file found in /data");
  }
  
  File acclFile = new File(dataPath(filenames[0]+"-accl.csv"));  //try to load CSV file
  if (acclFile.exists()) {
    acclTable = loadTable(filenames[0]+"-accl.csv", "header");
    acclTable = addExtraFiles(acclTable,"accl");
    //load accl data
    float currentMilliseconds = ((float(firstDataFrame))*(1000f/goproRate))+offset;//time we start at
    int checkRow = 0;
    while (float(acclTable.getRow(checkRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
      checkRow++;
      acclLastMilliseconds = float(acclTable.getRow(checkRow).getString("Milliseconds"));  //save current time
    }
    acclLastRow = checkRow;
  }
  
  File tempFile = new File(dataPath(filenames[0]+"-temp.csv"));  //try to load CSV file
  if (tempFile.exists()) {
    tempTable = loadTable(filenames[0]+"-temp.csv", "header");
    tempTable = addExtraFiles(tempTable,"temp");
    //load temp data
    float currentMilliseconds = ((float(firstDataFrame))*(1000f/goproRate))+offset;//time we start at
    int checkRow = 0;
    while (float(tempTable.getRow(checkRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
      checkRow++;
      tempLastMilliseconds = float(tempTable.getRow(checkRow).getString("Milliseconds"));  //save current time
    }
    tempLastRow = checkRow;
  }
  
  File gpsFile = new File(dataPath(filenames[0]+"-gps.csv"));  //try to load CSV file
  if (gpsFile.exists()) {
    gpsTable = loadTable(filenames[0]+"-gps.csv", "header");
    gpsTable = addExtraFiles(gpsTable,"gps");
    //load gps data
    float currentMilliseconds = ((float(firstDataFrame))*(1000f/goproRate))+offset;//time we start at
    int checkRow = 0;
      if (gpsTable.getRowCount() > 1) {
        while (float(gpsTable.getRow(checkRow).getString("Milliseconds")) < currentMilliseconds) {  //get rows under our time
          checkRow++;
          gpsLastMilliseconds = float(gpsTable.getRow(checkRow).getString("Milliseconds"));  //save current time
        }

      gpsLastRow = checkRow;
      locPre = null;
      locMax = new PVector(-180f,-85f);
      locMin = new PVector(180f,85f);
      for (TableRow row : gpsTable.rows()) {
        PVector curr = new PVector(row.getFloat("Longitude"),row.getFloat("Latitude"),row.getFloat("Altitude"));
        int accuracy = row.getInt("GpsAccuracy");
        if (accuracy < 1000) {
          if (curr.x > locMax.x) locMax.x = curr.x;
          if (-curr.y > locMax.y) locMax.y = -curr.y;
          if (curr.x < locMin.x) locMin.x = curr.x;
          if (-curr.y < locMin.y) locMin.y = -curr.y;
          cleanLatLon.add(curr.copy());
        } else {
          cleanLatLon.add(null);
        }
      }
      
      cleanLatLon = cleanLocations(cleanLatLon);
      
      //aqui remove this debugging
      String[] strings = new String[cleanLatLon.size()-1];
      for (int i=0; i<cleanLatLon.size()-1; i++) {
        if (cleanLatLon.get(i) != null) {
          strings[i] = cleanLatLon.get(i).x+","+cleanLatLon.get(i).y+","+cleanLatLon.get(i).z;
        } else {
          strings[i] = "missing";
        }
        
      }
      saveStrings("strings.txt",strings);

      locDiff = PVector.sub(locMax,locMin);
      locFactor = locDiff.x/locDiff.y;
      PGraphics svg = createGraphics(1080, 1080, SVG,"exports/"+ filenames[0]+"-latlong.svg");
      svg.beginDraw();
      for (int i=0; i<cleanLatLon.size();i++) {
        PVector curr = new PVector(cleanLatLon.get(i).x,cleanLatLon.get(i).y);
        curr.x = map(curr.x,locMin.x,locMax.x,0,1080);
        curr.y = map(-curr.y,locMin.y,locMax.y,0,1080);
        if (locFactor > 1) {
          curr.y /= locFactor;
        } else {
          curr.y *= locFactor;
        }
        
        if (locPre != null) {
          svg.line(locPre.x, locPre.y, curr.x, curr.y);
        }
        locPre = curr.copy();
      }
      svg.dispose();
      svg.endDraw();

    }
  }
  
  setupFinished = true;
}

ArrayList<PVector> cleanLocations(ArrayList<PVector> list) {
  //aqui
  PVector pre = new PVector(1000,1000);
  for (int i=0; i<list.size(); i++) {
    PVector curr = list.get(i);
    if (curr == null) {
      int steps;
      PVector destination = null;
      for (steps = 1; steps<list.size();steps++) {
        destination = list.get(steps);
        if (destination != null) {
          break;
        }
      }
      if (pre.x != 1000) {//not first valid value
        if (destination != null) {  //there is a next valid value
          curr = new PVector(pre.x + (destination.x-pre.x)/(steps+1),pre.y + (destination.y-pre.y)/(steps+1),pre.z + (destination.z-pre.z)/(steps+1));
        } else {  //no next valid value
          curr = pre.copy();
        } 
      } else { //still no valid value
        if (destination != null) {  //there is a next valid value
          curr = destination.copy();
        } else {  //no next valid value
        } 
      }
      
    }
    if (curr != null) pre = curr.copy();
    list.set(i,curr);
  }
  return list;
}


static final String nfj(final float n, final int l, final int r) {
  final String s = nfs(n, l, r);
  final boolean is2ndMinus = s.charAt(1) == '-';
 
  if (!is2ndMinus && s.charAt(0) == ' ')  return s;
  if (is2ndMinus)  return s.replaceFirst("-", "");
 
  return float(s.replaceFirst(",", ".")) == 0.0?
    s.replaceFirst("-", " ") : s;
}

void displayData(PVector g,PVector a, float t, float v, PVector gp) {  //display metadata
  if (setupFinished) {
    String text = "GyroX:"+nfj(g.x,0,2)+"RPM\nGyroY:"+nfj(g.y,0,2)+"RPM\n"+"GyroZ:"+nfj(g.z,0,2)+"RPM\nGyro:"+nfj(g.mag(),0,2)+"RPM\nAcclX:"+nfj(a.x,0,3)+"G\nAcclY:"+nfj(a.y,0,3)+"G\nAcclZ:"+nfj(a.z,0,3)+"G\nAccl:"+nfj(a.mag(),0,3)+"G\nVibr:"+nfj(v,0,1)+"Hz\nTemp:"+nfj(t,0,1)+"ºC\nLon: "+gp.x+"\nLat: "+gp.y+"\nAlt: "+gp.z;
    int shadow = 1;//distance to shadow
    textSize(12);
    textAlign(LEFT,TOP);  
    fill(0);
    text(text, 10+shadow, 30+shadow); //draw shadow first
    fill(255);
    text(text, 10, 30); //then text
    stroke(255,10);
    strokeWeight(1);
    pushMatrix();
    translate(width-60-height/3,height-30-height/3);
    locPre = null;
    for (int i=0; i<cleanLatLon.size();i++) {
        PVector curr = new PVector(cleanLatLon.get(i).x,cleanLatLon.get(i).y);
        curr.x = map(curr.x,locMin.x,locMax.x,0f,height/3f);
        curr.y = map(-curr.y,locMin.y,locMax.y,0f,height/3f);
        if (locFactor > 1) {
          curr.y /= locFactor;
        } else {
          curr.y *= locFactor;
        }
        
        if (locPre != null) {
          line(locPre.x, locPre.y, curr.x, curr.y);
        }
        locPre = curr.copy();
      }
      PVector pre = null;
      stroke(255);
      strokeWeight(2);
      for (int j=0; j< gpsFramesArr.size();j++) {
        PVector curr = gpsFramesArr.get(j).copy();
        curr.x = map(curr.x,locMin.x,locMax.x,0f,height/3f);
        curr.y = map(-curr.y,locMin.y,locMax.y,0f,height/3f);
        if (locFactor > 1) {
          curr.y /= locFactor;
        } else {
          curr.y *= locFactor;
        }
        if (pre != null) {
          line(pre.x, pre.y, curr.x, curr.y);
        }
        pre = curr.copy();
      }
      popMatrix();
  }
}

void displayNonPritableData() {
  String txt = "";
    txt = nfc(constrain(100*(currentFrame-firstDataFrame)/(totalFrames),0,100),0)+"%";
    int shadow = 1;//distance to shadow
    textSize(12);
    textAlign(LEFT,BOTTOM);  
    fill(0);
    text(txt, 10+shadow, height-30+shadow); //draw shadow first
    fill(255);
    text(txt, 10, height-30); //then text
}

void movieEvent(Movie m) { //when a frame is ready
  m.read();
  if (!finishingSetup) {//finish loading everything according to the movie info
    finishingSetup = true;
    goproRate = myMovie.frameRate;  //we can now set the framerate based on the video file
    validFrame = firstDataFrame;  //frame count taking offsets into account
    if (!dataVideoSync) {
      validFrame -= firstDataFrame;
    }
    File stillsFile = new File(dataPath(filenames[0]+nf(validFrame,digits)+fileType));  //try to load necessary video files
    if (stillsFile.exists()) {  //if still frames are there
      skipMovie = true;  //don't extract movie frames
    } else {
      savedFrames = validFrame;    //count from the right one
      //check how many digits we need to save the frames
      totalFrames = int(myMovie.duration()*goproRate);
      float durationInFrames = totalFrames;
      digits = 1;
      while (durationInFrames > 1) {  //calculate digits needed to save the number of files and overwrite the preset
        durationInFrames /= 10;
        digits++;
      }
      stillsFile = new File(dataPath(filenames[0]+nf(validFrame,digits)+fileType));  //try to load necessary video files with this new value, which would be right if the movie has been extracted and the preset was wrong
      if (stillsFile.exists()) {  //if still frames are there
        skipMovie = true;//don't extract movie frames
      }
    
    }
    
    finishSetup();
  }
  
  if (!skipMovie) {//only save frames if necessary
    m.save("/data/"+filenames[0]+nf(savedFrames,digits)+fileType);    //save it
    println("Extracting frame "+savedFrames+" of ~"+int(totalFrames));
    savedFrames++;
    currentFrameLoad++; 
    if (m.time() >= m.duration()-(2*(1f/goproRate))) {  //if all loaded (actually a little earlier, since this is not precise and we don't want to risk it not firing)
      areFramesSaved = true;
    }
  }
}

void finishCSVs() {
  
                TableRow newRow = AEPosition.addRow();
                newRow.setString(0, "");
                newRow = AEPosition.addRow();
                newRow.setString(0, "");
                newRow = AEPosition.addRow();
                newRow.setString(0, "End of Keyframe Data");
                saveTable(AEPosition,"exports/"+ filenames[0]+"-AEposition.csv");
                
                newRow = AERotation.addRow();
                newRow.setString(0, "");
                newRow = AERotation.addRow();
                newRow.setString(0, "");
                newRow = AERotation.addRow();
                newRow.setString(0, "End of Keyframe Data");
                saveTable(AERotation,"exports/"+ filenames[0]+"-AErotation.csv");
                
                newRow = AELocations.addRow();
                newRow.setString(0, "");
                newRow = AELocations.addRow();
                newRow.setString(0, "");
                newRow = AELocations.addRow();
                newRow.setString(0, "End of Keyframe Data");
                saveTable(AELocations,"exports/"+ filenames[0]+"-AElocations.csv");
                
                newRow = AEgForce.addRow();
                newRow.setString(0, "");
                newRow = AEgForce.addRow();
                newRow.setString(0, "");
                newRow = AEgForce.addRow();
                newRow.setString(0, "End of Keyframe Data");
                saveTable(AEgForce,"exports/"+ filenames[0]+"-AEgForce.csv");
                
                newRow = AErpm.addRow();
                newRow.setString(0, "");
                newRow = AErpm.addRow();
                newRow.setString(0, "");
                newRow = AErpm.addRow();
                newRow.setString(0, "End of Keyframe Data");
                saveTable(AErpm,"exports/"+ filenames[0]+"-AErpm.csv");
                
                 newRow = AEvibr.addRow();
                  newRow.setString(0, "");
                  newRow = AEvibr.addRow();
                  newRow.setString(0, "");
                  newRow = AEvibr.addRow();
                  newRow.setString(0, "End of Keyframe Data");
                  saveTable(AEvibr,"exports/"+ filenames[0]+"-AEvibr.csv");
                  
                  newRow = AEvibrhz.addRow();
                  newRow.setString(0, "");
                  newRow = AEvibrhz.addRow();
                  newRow.setString(0, "");
                  newRow = AEvibrhz.addRow();
                  newRow.setString(0, "End of Keyframe Data");
                  saveTable(AEvibrhz,"exports/"+ filenames[0]+"-AEvibrhz.csv");
            
                noLoop();
              
}

boolean isPositive(float n) {
  if (n>=0)  return true;
  else return false;
}
