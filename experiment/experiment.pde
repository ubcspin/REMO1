import processing.serial.*;
import processing.video.*;
import java.util.*;
// debugging
boolean debugging = true;

boolean connected = false;
boolean firstConnect = false;

// Create object from Serial class
Serial myPort;  
// Data received from the serial port
String val;     

// Servo position
int position = 0;
// have we talked to Arduino yet?
boolean firstContact = false;

// Video stuff
Movie video;
boolean videoPlaying = false;

// File recording
PrintWriter output;

// Visualizing data
float hr, x, y, z, p; // for visualization ONLY!!! Don't rely on these values.
float lhr, dx, dy, dz, lp; // for visualization ONLY!!! Don't rely on these values.

float [] hrvals;
float hrmax = 1000; 
float hrmin = 0;

int fps = 120;

PFont font;

int spacer = 40; // space between plots
int h = 25; // height of plots

String participantID;
String conditionID;

final int videoWidth = 640;
final int videoHeight = 360;


ArrayList recordedBehaviour;
int frameZero = 0;

int easeIn = 20;   // length of ease in
int easeOut = 10;   // length of ease out

int timeIn = 5; // time when we start the ease
int timeOut = timeIn + easeIn + 5; // time when we start the ease

int maxNumBins = fps * (4);
int minNumBins = fps * (1);

int diffBins = maxNumBins - minNumBins; // 360
int sizeOfStepIn  = diffBins / easeIn;  // 18
int sizeOfStepOut = diffBins / easeOut; // 36

void setup() {
  
  recordedBehaviour = new ArrayList();
  generateBehaviour();
  
  // I know that the first port in the serial list on my mac
  // is Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  
  frameRate(fps);
  

  for (int i = 0; i < Serial.list().length; i++) {
    println(i + " : " + Serial.list()[i]);
  }

  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  myPort = new Serial(this, portName, 115200);
  
  ////////////////////////////////////////////////////////
  // Video
  
  
  background(255, 204, 0);
  
  video = new Movie(this, "video.mp4"); // in data folder
  //if (debugging) {
    size(640, 360); // from finals above
  //} else {
    //fullScreen();
  //}
  
  ////////////////////////////////////////////////////////
  // File output
  participantID = getPtpt();
  conditionID = getCondition();
  
  output = createWriter("recordings/record_" + getTimestamp() + "_" + participantID + conditionID + ".csv");
  
  output.println("Robot Emotion Regulation Study Early 2018");
  output.println("Zak Witkower, Laura Cang, Paul Bucci");
  output.println("zakwitkower@gmail.com, cang@cs.ubc.ca, pbucci@cs.ubc.ca");
  
  output.println("Participant ID: " + participantID);
  output.println("Condition ID: " + conditionID);
  output.println("-------------------------------------------------------------\n");
  // example data: 1519702417037,517,10.47,-0.71,0.63,57,5462284,note1
  output.println("unix_timestamp,heart_rate_voltage,accelerometer_x,accelerometer_y,accelerometer_z,servo_position,arduino_timestamp,note");
  output.flush();
  
  ////////////////////////////////////////////////////////
  // Typography
  font = loadFont("AvenirNext-Bold-10-alias.vlw");
  textFont(font);
  
  ////////////////////////////////////////////////////////
  // Misc.
  hrvals = new float[width];
}

String getCondition() {
  List<String> list = new ArrayList<String>();
  if (debugging) {
    list.add("1");
  } else {
    list.add("1");
    list.add("2");
    list.add("3");
  }
  Random randomizer = new Random();
  String random = list.get(randomizer.nextInt(list.size()));
  return random;
}

String getPtpt() {
  //int num_mins = 60*24*30*6; // 60 mins * 24 hours * 30 days * 6 months = 259200 mins
  // 2^20 - 259200 = 918976 

  long mins_in_milli = 1000*60; // number of milliseconds in a minute
  
  long current = 1519769096390L; // current unix time on Feb 27 2pm
  long diff = System.currentTimeMillis() - current;
  int num_minutes_since = (int) (diff / mins_in_milli);
  String ptptID = String.format("%06X", num_minutes_since);
  
  return ptptID;
}


void draw() {
   handleVideo();
   position = updatePosition();
}


void handleVideo() {
  //// Video loop
  if (!connected) {
    fill(0);
    text("connecting to arduino...", width / 2, height / 2);
  } else if (firstConnect) {
    firstConnect = false;
    background(255, 204, 0);
  }
  else if (videoPlaying) {
    drawData();
    //background(0);
    //image(video, (0.5) * (width - videoWidth), 0.5 * (height - videoHeight)); // comment out to hide video screen
    // check if video is done
    if (video.time() == video.duration()) {
      stopExperiment();
    }
  } else {
    drawData();
  }
}

void drawText() {
  fill(0);
  text("x-acc", 10, ydist(1) - spacer);
  text("y-acc", 10, ydist(2) - spacer);
  text("z-acc", 10, ydist(3) - spacer);
  text("servo position", 10, ydist(4) - spacer);
  text("HR voltage", 10, ydist(5) - spacer);
  text("Press ENTER or RETURN to start experiment.", width - 230, 10);
  text("Particiapnt ID : " + participantID + conditionID, width - 230, 25); 
}

void exit() {
  println("Stopping program.");
  myPort.clear();
  myPort.stop();
  
  output.flush();
  output.close();
  
  super.exit();
} 

void drawData() {
  // line(x1,y1,x2,y2)
  drawText();
  if (frameCount % width == 1) {
    background(255, 204, 0);
    recalculateReferences();
  }
  
  int xend = frameCount % width;
  int xstart = (frameCount % width) - 1;
  
  line(xstart, ydist(1) - dx, xend, ydist(1));
  line(xstart, ydist(2) - dy, xend, ydist(2));
  line(xstart, ydist(3) - dz, xend, ydist(3));
  line(xstart, ydist(4) - map(lp, 0, 180, 0, h), xend, ydist(4) - map(p, 0, 180, 0, h));
  line(xstart, ydist(5) - map(lhr, hrmin, hrmax, 0, h), xend, ydist(5) - map(hr, hrmin, hrmax, 0, h)); 
}


int ydist(int row) {
  int dst = row * spacer + row * h; 
  return dst;
}

// Movie helper fucntion
void movieEvent(Movie m) {
  m.read();
}

void keyPressed() {
  if (key == ENTER || keyCode == RETURN || keyCode == SHIFT) {
    if (!videoPlaying) {
      startExperiment();
    } else {
      stopExperiment();
    }
  }
}


int updatePosition() {
  //int i = frameCount % (fps * 4);
  //if (conditionID == "3") { // dead condition
  //  return 0;
  //} else if (conditionID == "1") { // faster condition
  //   if (videoPlaying && video.time() > (60 * 2) + (24 * 1)) {
  //     if (frameZero == 0) { // frameZero is the frame count into the program that the video start at
  //       println("Started accelerated breathing.");
  //       frameZero = frameCount;
  //       recordData("start bad video");
  //     } else {
  //       i = frameCount - frameZero;
  //     }
  //  }
  //}// else just return the normal for condition "2"
  ////int i = frameCount;
  //int pos = (int) recordedBehaviour.get(i);
  ////println("i: " + i + "\t\t pos: " + pos); 
  //p = pos;
  //return pos;
  
  int i = frameCount % 480;
  if (videoPlaying && video.time() <= video.duration()) {
     i = frameCount - frameZero;
   }
  int pos = (int) recordedBehaviour.get(i);
  p = pos;
  return pos; 
  
}


void generateBehaviour() {
  
    int startDelay = (fps * 60 * 2) + (24 * fps); // number of frames between end of easeIn and video end
    int delayNumBins = startDelay / maxNumBins;
  
    for (int j = 0; j < delayNumBins; j++) {
      int[] bins = new int[maxNumBins];
      bins[0] = 0;
      float currentPos = 0;
        
      float slope = 180f / ((float) bins.length / 2);
      printD("slope: " + slope + " bins.length: " + bins.length);
      for (int i = 1; i < bins.length / 2; i++) {
        currentPos = currentPos + slope;
        bins[i] = (int) currentPos;
      }
      
      for (int i = bins.length / 2; i < bins.length; i++) {
        currentPos = currentPos - slope;
        bins[i] = (int) currentPos;
      }
      bins[bins.length - 1] = 0;
      
      for (int i = 0; i < bins.length; i++) {
        recordedBehaviour.add(bins[i]);
      }
    }
  
    for (int k = maxNumBins; k > minNumBins; k = k - sizeOfStepIn) {
  
        int[] bins = new int[k];
        bins[0] = 0;
        
        float currentPos = 0;
        
        float slope = 180f / ((float) bins.length / 2);
        printD("slope: " + slope + " bins.length: " + bins.length);
        
        for (int i = 1; i < bins.length / 2; i++) {
          currentPos = currentPos + slope;
          bins[i] = (int) currentPos;
        }
        for (int i = bins.length / 2; i < bins.length; i++) {
          currentPos = currentPos - slope;
          bins[i] = (int) currentPos;
        }
        
        bins[bins.length - 1] = 0; 
        
        for (int i = 0; i < bins.length; i++) {
          recordedBehaviour.add(bins[i]);
        }
    }
    
    // Pause from:
    //3.24.02
    //3.48.03
    
    int pauseLength = 24 * fps; // number of frames between end of easeIn and video end
    int pauseNumBins = pauseLength / minNumBins;
  
    for (int j = 0; j < pauseNumBins; j++) {
      int[] bins = new int[minNumBins];
      bins[0] = 0;
      float currentPos = 0;
        
      float slope = 180f / ((float) bins.length / 2);
      printD("slope: " + slope + " bins.length: " + bins.length);
      for (int i = 1; i < bins.length / 2; i++) {
        currentPos = currentPos + slope;
        bins[i] = (int) currentPos;
      }
      
      for (int i = bins.length / 2; i < bins.length; i++) {
        currentPos = currentPos - slope;
        bins[i] = (int) currentPos;
      }
      bins[bins.length - 1] = 0;
      
      for (int i = 0; i < bins.length; i++) {
        recordedBehaviour.add(bins[i]);
      }
    }
    
     for (int k = minNumBins; k <= maxNumBins; k = k + sizeOfStepOut) {
        
        int[] bins = new int[k];
        bins[0] = 0;
        
        float currentPos = 0;
        
        float slope = 180f / ((float) bins.length / 2);
        printD("slope: " + slope + " bins.length: " + bins.length);
        
        for (int i = 1; i < bins.length / 2; i++) {
          currentPos = currentPos + slope;
          bins[i] = (int) currentPos;
        }
        for (int i = bins.length / 2; i < bins.length; i++) {
          currentPos = currentPos - slope;
          bins[i] = (int) currentPos;
        }
        
        bins[bins.length - 1] = 0; 
        
        for (int i = 0; i < bins.length; i++) {
          recordedBehaviour.add(bins[i]);
        }
    }
    
    
    if (debugging) {
      PrintWriter testoutput = createWriter("recordings/testoutput" + ".txt");
      for (int i = 0; i < recordedBehaviour.size(); i++) {
        testoutput.print(recordedBehaviour.get(i) + ",");
      }
      testoutput.println();
      testoutput.flush();
      testoutput.close();
      println("Number of bins: " + recordedBehaviour.size());
      
      //24360
    }
    
   
} // generateBehaviour()

void printD(String msg) {
  if (debugging) {
    println(msg);
  }
}

void recalculateReferences() {
  float min = 1000;
  float max = 0;
  
  for (int i = hrvals.length / 2; i < hrvals.length - 1; i++) {
    hrvals[i] = (hrvals[i-1] + hrvals[i+1]) / 2;
  }
  
  for (int i = hrvals.length / 2; i < hrvals.length; i++) {
    if (hrvals[i] < min) {
      min = hrvals[i];
    }
    if (hrvals[i] > max) {
      max = hrvals[i];
    }
  }
  hrmin = min;
  hrmax = max;
  if (hrmin == hrmax) {
    hrmax = hrmin + 1;
  }
}



void serialEvent(Serial myPort) {
  
  try {    
    // read the serial buffer:
    String myString = myPort.readStringUntil('\n');
    // if you got any bytes other than the linefeed:
    if (myString != null) {
   
      myString = trim(myString);
   
      // if you haven't heard from the microncontroller yet, listen:
      if (firstContact == false) {
        if (myString.equals("hello")) {
          myPort.clear();          // clear the serial port buffer
          firstContact = true;     // you've had first contact from the microcontroller
          println("First contact established.");
          connected = true;
          firstConnect = true;
          myPort.write((int) 0);   // ask for more, zero is arbitrary
        }
      }
      // if you have heard from the microcontroller, proceed:
      else {
        // when you've parsed the data you have, ask for more:
        String [] list = split(myString, ",");
        
        lhr = hr;
        lp = p;
        hrvals[frameCount % width] = hr;
        
        dx = x - float(list[1]);
        dy = y - float(list[2]);
        dz = z - float(list[3]);  
        
        hr = float(list[0]);
        x = float(list[1]);
        y = float(list[2]);
        z = float(list[3]);
        p = float(list[4]);
        // list[5] is arduino (currently microsecond) timestamp
        
        recordData(myString + ",datapoint");
        //printD(myString + " FPS: " + frameRate);
        myPort.write((int) position);
      }
      
    }
  } catch(RuntimeException e) {
    e.printStackTrace();
    exit();
  }
}

// Experiment functions
void startExperiment() {
  videoPlaying = true;
  video.play();
  frameZero = frameCount;
  recordData("start experiment");
}

void stopExperiment() {
  videoPlaying = false;
  video.stop();
  frameZero = 0;
  recordData("end experiment");
  background(255, 204, 0);
}

// Return a stringified timestamp in milliseconds
String getTimestamp() {
  String timestamp = Long.toString(System.currentTimeMillis()); //day() + "/" + month() + "/" + year() + "-" + hour() + ":" + minute() + ":" + second();
  return timestamp;
}

String getHumanReadableTimestamp() {
  return day() + "-" + month() + "-" + year() + "_" + hour() + "." + minute() + "." + second();
}

void recordData(String msg) {
  //output.println(hr + ", " + ac + ", " + position + ", " + getTimestamp() + "," + video.time() + ", " + msg);
  int acc = 0;
  for (int i = 0; i < msg.length(); i++) {
    if (msg.charAt(i) == ',') {
      acc++;
    }
  }
  if (acc == 0) {
    msg = "null,null,null,null,null,null," + msg;
  }
  output.println(getTimestamp() + "," + msg);
}