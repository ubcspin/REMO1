import processing.serial.*;
import processing.video.*;

Serial myPort;  // Create object from Serial class
String val;     // Data received from the serial port

Movie video;
boolean videoPlaying = false;

PrintWriter output;

// Button globals
int rectX, rectY, rectSize;
color rectColor, baseColor;
color rectHighlight;
color currentColor;

boolean rectOver = false;

int position = 0; // servo position

void setup()
{
  // I know that the first port in the serial list on my mac
  // is Serial.list()[0].
  // On Windows machines, this generally opens COM1.
  // Open whatever port is the one you're using.
  String portName = Serial.list()[1]; //change the 0 to a 1 or 2 etc. to match your port
  for (int i = 0; i < Serial.list().length; i++) {
    println(Serial.list()[i]);
  }
  myPort = new Serial(this, portName, 9600);
  
  
  ////////////////////////////////////////////////////////
  // Video
  size(640, 360); // needs to be changed to the right size
  output = createWriter("record" + getTimestamp() + ".txt");
  video = new Movie(this, "totoro.mp4"); // needs to be zak"s film
 
  ////////////////////////////////////////////////////////
  // Button
  initButton();
  
}

void draw() {
  handleVideo();
  readSerial();  
  
  // output servo position
  // after waiting for 10 seconds
  if (millis() > 100) {
    position = getPosition();
    writeServoToSerial(); 
  }
 
  
  // button loop
  update(mouseX, mouseY);

}

// Initialize the play button
void initButton() {
  rectColor = color(0);
  rectHighlight = color(51);
  baseColor = color(102);
  currentColor = baseColor;
  rectSize = 25;
  rectX = 0;
  rectY = 0;
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
    background(currentColor);
    if (rectOver) {
      fill(rectHighlight);
    } else {
      fill(rectColor);
    }
    stroke(255);
    rect(rectX, rectY, rectSize, rectSize);
  }
}

void readSerial() {
    // If data is available,
    //while(myPort.available() < 1){
    //} // blocking loop
  if ( myPort.available() > 0) {  
    // read it and store it in val
    val = myPort.readStringUntil('\n');
    if (val != null && val != "\n") {
      println(val); //print it out in the console
    }
  }
  
}

void writeServoToSerial() {
  myPort.write(position);
}

// Movie helper fucntion
void movieEvent(Movie m) {
  m.read();
}

// Servo helper functions
int getPosition() {
  // sine wave stub
  float t = millis() * 0.001;
  float f = 0.25;
  int pos = floor((sin(2*PI*f*t) + 1) * 0.5 * 180); // vary between 0-180 degrees 
  return pos; 
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
  recordData("start experiment");
}

void stopExperiment() {
  videoPlaying = false;
  video.stop();
  recordData("end experiment");
}

// Return a stringified timestamp in milliseconds
String getTimestamp() {
  String timestamp = Long.toString(System.currentTimeMillis()); //day() + "/" + month() + "/" + year() + "-" + hour() + ":" + minute() + ":" + second();
  return timestamp;
}


void recordData(String msg) {
  //output.println(hr + ", " + ac + ", " + position + ", " + getTimestamp() + "," + video.time() + ", " + msg);
  output.println(getTimestamp() + msg);
}