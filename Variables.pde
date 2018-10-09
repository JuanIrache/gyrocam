Table table;  //will contain the input gyro file
Table acclTable;  //will contain the input accelerometer file
Table gpsTable;  //will contain the input gps file
ArrayList<PVector> cleanLatLon = new ArrayList<PVector>(); //will contain cleaner gps data
Table tempTable;  //will contain the input temperature file
PVector rotation = new PVector (0,0,0);
float pixelsPerRad = 0;
float lastMilliseconds = 0;  //time of last info applied
float acclLastMilliseconds = 0;  //time of last info applied
float tempLastMilliseconds = 0;  //time of last info applied
float gpsLastMilliseconds = 0;
int currentFrame = 0;  
int lastRow = 0;  
float realWidth;  //deduced from conditional realheight and sketch ratio
PImage currentImage = new PImage();
int savedFrames = 0;
Movie myMovie;
int currentFrameLoad = 0;
boolean areFramesSaved = false;
int validFrame;
boolean setupFinished = false;
boolean finishingSetup = false;
boolean skipMovie = false;
int acclLastRow = 0;  //to read accl csv
int tempLastRow = 0;  //to read temp csv
int gpsLastRow = 0;  //to read gps csv
float tempDisplay = 0; 
int totalFrames;
Table AERotation;  //table for exporting sensor values per frame
Table AEPosition;  //table for exporting sensor values per frame
Table AEgForce;  //will contain the output g-force for after effects
Table AErpm;  //will contain the output rpm for after effects
Table AEvibr;  //will contain the output vibrations for after effects visualisation
Table AEvibrhz;  //will contain the output vibrations in hertz for after effects display value
Table AELocations;  //table for exporting gps values per frame
ArrayList<PVector> gpsFramesArr = new ArrayList<PVector>();
int finishedCSVs = 0;//how many csv documents for AE are completed?
float vibrhz =0;//stores vibrations in frequency
PVector acclLast = new PVector(0,0,0);//stores the previous acceleration vector to measure vibration
float vibrDisplay; //will contain the vibrations per second (hz) of a frame
PVector locPre;
PVector locDiff;
float locFactor;
PVector locMax;
PVector locMin;
