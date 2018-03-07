import processing.serial.*;
import processing.video.*;
import java.util.*;

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

void setup() {
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
  size(640, 360); // needs to be changed to the right size
  background(255, 204, 0);
  video = new Movie(this, "video.mp4"); // in data folder

  ////////////////////////////////////////////////////////
  // File output
  participantID = getPtpt();
  conditionID = getCondition();
  
  output = createWriter("recordings/record_" + getTimestamp() + "_" + participantID + conditionID + ".txt");
  
  output.println("Robot Emotion Regulation Study Early 2018");
  output.println("Zak Witkower, Laura Cang, Paul Bucci");
  output.println("zakwitkower@gmail.com, cang@cs.ubc.ca, pbucci@cs.ubc.ca");
  
  output.println("Participant ID: " + participantID);
  output.println("Condition ID: " + conditionID);
  output.println("-------------------------------------------------------------\n");
  // example data: 1519702417037,517,10.47,-0.71,0.63,57,5462284
  output.println("unix_timestamp,heart_rate_voltage,accelerometer_x,accelerometer_y,accelerometer_z,servo_position,arduino_timestamp");
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
  list.add("1");
  list.add("2");
  //list.add("3");
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
  if (videoPlaying) {
    image(video, 0, 0);
    // check if video is done
    if (video.time() == video.duration()) {
      stopExperiment();
    }
  } else {
    drawData();
  }
}

void drawText() {
  background(255, 204, 0);
  fill(0);
  text("x-acc", 10, ydist(1) - spacer);
  text("y-acc", 10, ydist(2) - spacer);
  text("z-acc", 10, ydist(3) - spacer);
  text("servo position", 10, ydist(4) - spacer);
  text("HR voltage", 10, ydist(5) - spacer);
  text("Press ENTER or RETURN to start experiment.", width - 230, 10);
  text("Particiapnt ID : " + participantID + conditionID, width - 230, 25);
  
}

void stop() {
  output.flush();
  output.close();
} 

void drawData() {
  // line(x1,y1,x2,y2)
  if (frameCount % width == 1) {
    recalculateReferences();
    drawText();
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

// Servo helper functions
int updatePosition() {
  // sine wave stub
  float t = millis() * 0.001;
  float f = 0.125; // default neutral
  float fout = f;
  float fmax = 0;
  int easeIn = 20; // seconds to ease in
  int easeOut = 20; // seconds to ease in
  
  float timeIn  = (2 * 60) + 14; // timecode 2:14
  float timeOut = (3 * 60) + 40; // timecode 3:40
  
  if (conditionID == "1") {
    // fast
    fmax = 2.0; 
  } else if (conditionID == "2") {
    // regular
    fmax = 0.125;
  } else if (conditionID == "3") {
    // dead
    return 0;
  }
  
  if (videoPlaying) {
    if (video.time() > timeIn && video.time() < timeIn + easeIn) {
      fout = lerp(f, fmax, (video.time() - timeIn) / easeIn);
    } else if (video.time() > timeOut && video.time() < timeOut + easeOut) {
      fout = lerp(f, fmax, (video.time() - timeOut) / easeOut);
    }
  } else {
    fout = f; // redundant 
  }
  
  int pos = floor((sin(2*PI*fout*t) + 1) * 0.5 * 180); // vary between 0-180 degrees

  return pos; 
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
      
      recordData(myString);
      println(myString);
      myPort.write((int) position);
    }
    
  }
}


// Experiment functions
void startExperiment() {
  videoPlaying = true;
  video.play();
  recordData("start experiment");
}

void stopExperiment() {
  videoPlaying = false;
  video.stop();
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
  output.println(getTimestamp() + "," + msg);
}