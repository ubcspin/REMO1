import processing.video.*;
import processing.serial.*;
import cc.arduino.*;

Movie video;
boolean videoPlaying = false;

Arduino arduino;
int servoPin = 9;
int heartRatePin = 5; // analog
int accelerometerPin = 1; // analog

// Button globals
int rectX, rectY, rectSize;
color rectColor, baseColor;
color rectHighlight;
color currentColor;

boolean rectOver = false;

PrintWriter output;


void setup() {
  size(640, 360); // needs to be changed to the right size
  output = createWriter("record" + getTimestamp() + ".txt");
  video = new Movie(this, "totoro.mp4"); // needs to be zak"s film
 
  // Arduino
  //println(Arduino.list());
  arduino = new Arduino(this, Arduino.list()[0], 57600);
  arduino.pinMode(servoPin, Arduino.SERVO);
  
  arduino.pinMode(heartRatePin, Arduino.ANALOG);
  arduino.pinMode(accelerometerPin, Arduino.ANALOG);
  
  // Button
  initButton();

}

void initButton() {
  rectColor = color(0);
  rectHighlight = color(51);
  baseColor = color(102);
  currentColor = baseColor;
  rectSize = 25;
  rectX = 0;
  rectY = 0;
}

void draw() {
  //// Video loop
  if (videoPlaying) {
    image(video, 0, 0);
    // check if video is done
    if (video.time() == video.duration()) {
      stopExperiment();
    }
  } else {
    background(currentColor);
    if (rectOver) {
      fill(rectHighlight);
    } else {
      fill(rectColor);
    }
    stroke(255);
    rect(rectX, rectY, rectSize, rectSize);
  }
  
 
  //// Arduino loop
  // Read sensors
  float hr = arduino.analogRead(heartRatePin);
  float ac = arduino.analogRead(accelerometerPin);
  
  // output servo position
  int position = getPosition();
  arduino.servoWrite(servoPin, position);
  
  // Record arduino data
  recordData(hr, ac, position, " ");
  
  //// button loop
  update(mouseX, mouseY);
}

// Movie helper fucntion
void movieEvent(Movie m) {
  m.read();
}

// Servo helper functions
int getPosition() {
  return 1; // stub
}


// Button helper functions
void update(int x, int y) {
  if ( overRect(rectX, rectY, rectSize, rectSize) ) {
    rectOver = true;
  } else {
    rectOver = false;
  }
}

void mousePressed() {
  if (rectOver && !videoPlaying) {
    startExperiment();
  } else {
    stopExperiment();
  }
}

boolean overRect(int x, int y, int width, int height)  {
  if (mouseX >= x && mouseX <= x+width && 
      mouseY >= y && mouseY <= y+height) {
    return true;
  } else {
    return false;
  }
}


// Experiment functions
void startExperiment() {
  videoPlaying = true;
  video.play();
  recordData(0,0,0,"start experiment");
}

void stopExperiment() {
  videoPlaying = false;
  video.stop();
  recordData(0,0,0,"end experiment");
}

// Return a stringified timestamp in milliseconds
String getTimestamp() {
  String timestamp = Long.toString(System.currentTimeMillis()); //day() + "/" + month() + "/" + year() + "-" + hour() + ":" + minute() + ":" + second();
  return timestamp;
}


void recordData(float hr, float ac, int position, String msg) {
  output.println(hr + ", " + ac + ", " + position + ", " + getTimestamp() + "," + video.time() + ", " + msg);
}