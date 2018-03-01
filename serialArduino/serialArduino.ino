


/*  PulseSensor™ Starter Project and Signal Tester
 *  The Best Way to Get Started  With, or See the Raw Signal of, your PulseSensor™ & Arduino.
 *
 *  Here is a link to the tutorial
 *  https://pulsesensor.com/pages/code-and-guide
 *
 *  WATCH ME (Tutorial Video):
 *  https://www.youtube.com/watch?v=82T_zBZQkOE
 *
 *
-------------------------------------------------------------
1) This shows a live human Heartbeat Pulse.
2) Live visualization in Arduino's Cool "Serial Plotter".
3) Blink an LED on each Heartbeat.
4) This is the direct Pulse Sensor's Signal.
5) A great first-step in troubleshooting your circuit and connections.
6) "Human-readable" code that is newbie friendly."

*/

///////////////////////////////////////////////////////////////////////////////////////
// Servo code
#include <Servo.h>
Servo myservo;  // create servo object to control a servo
int pos = 0;    // initial position 

///////////////////////////////////////////////////////////////////////////////////////
// Accelerometer code 
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_ADXL345_U.h>

/* Assign a unique ID to this sensor at the same time */
Adafruit_ADXL345_Unified accel = Adafruit_ADXL345_Unified(12345);

float x, y, z;

void displaySensorDetails(void)
{
  sensor_t sensor;
  accel.getSensor(&sensor);
  Serial.println("------------------------------------");
  Serial.print  ("Sensor:       "); Serial.println(sensor.name);
  Serial.print  ("Driver Ver:   "); Serial.println(sensor.version);
  Serial.print  ("Unique ID:    "); Serial.println(sensor.sensor_id);
  Serial.print  ("Max Value:    "); Serial.print(sensor.max_value); Serial.println(" m/s^2");
  Serial.print  ("Min Value:    "); Serial.print(sensor.min_value); Serial.println(" m/s^2");
  Serial.print  ("Resolution:   "); Serial.print(sensor.resolution); Serial.println(" m/s^2");  
  Serial.println("------------------------------------");
  Serial.println("");
  delay(5000);
}

void displayDataRate(void) {
  Serial.print  ("Data Rate:    "); 
  switch(accel.getDataRate())
  {
    case ADXL345_DATARATE_3200_HZ:
      Serial.print  ("3200 "); 
      break;
    case ADXL345_DATARATE_1600_HZ:
      Serial.print  ("1600 "); 
      break;
    case ADXL345_DATARATE_800_HZ:
      Serial.print  ("800 "); 
      break;
    case ADXL345_DATARATE_400_HZ:
      Serial.print  ("400 "); 
      break;
    case ADXL345_DATARATE_200_HZ:
      Serial.print  ("200 "); 
      break;
    case ADXL345_DATARATE_100_HZ:
      Serial.print  ("100 "); 
      break;
    case ADXL345_DATARATE_50_HZ:
      Serial.print  ("50 "); 
      break;
    case ADXL345_DATARATE_25_HZ:
      Serial.print  ("25 "); 
      break;
    case ADXL345_DATARATE_12_5_HZ:
      Serial.print  ("12.5 "); 
      break;
    case ADXL345_DATARATE_6_25HZ:
      Serial.print  ("6.25 "); 
      break;
    case ADXL345_DATARATE_3_13_HZ:
      Serial.print  ("3.13 "); 
      break;
    case ADXL345_DATARATE_1_56_HZ:
      Serial.print  ("1.56 "); 
      break;
    case ADXL345_DATARATE_0_78_HZ:
      Serial.print  ("0.78 "); 
      break;
    case ADXL345_DATARATE_0_39_HZ:
      Serial.print  ("0.39 "); 
      break;
    case ADXL345_DATARATE_0_20_HZ:
      Serial.print  ("0.20 "); 
      break;
    case ADXL345_DATARATE_0_10_HZ:
      Serial.print  ("0.10 "); 
      break;
    default:
      Serial.print  ("???? "); 
      break;
  }  
  Serial.println(" Hz");  
}


void displayRange(void)
{
  Serial.print  ("Range:         +/- "); 
  
  switch(accel.getRange())
  {
    case ADXL345_RANGE_16_G:
      Serial.print  ("16 "); 
      break;
    case ADXL345_RANGE_8_G:
      Serial.print  ("8 "); 
      break;
    case ADXL345_RANGE_4_G:
      Serial.print  ("4 "); 
      break;
    case ADXL345_RANGE_2_G:
      Serial.print  ("2 "); 
      break;
    default:
      Serial.print  ("?? "); 
      break;
  }  
  Serial.println(" g");  
}
///////////////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////////////
// Pulse Sensor code
//  Variables
int PulseSensorPurplePin = 0; // Pulse Sensor PURPLE WIRE connected to ANALOG PIN 0
int LED13 = 13; // The on-board Arduino LED

int hrs; // holds the incoming raw heart rate signal. Signal value can range from 0-1024                
int hrThreshold = 550; // Determine which Signal to "count as a beat", and which to ingore.            

//PulseSensorPlayground pulseSensor;

bool debugging = false;
///////////////////////////////////////////////////////////////////////////////////////

// The SetUp Function:
void setup() {
  
  Serial.begin(115200);
  
  ////////////////////////////
  // Accelerometer
//  Serial.println("Accelerometer Test"); Serial.println("");
  /* Initialise the sensor */
  if(!accel.begin()) {
    /* There was a problem detecting the ADXL345 ... check your connections */
//    Serial.println("Ooops, no ADXL345 detected ... Check your wiring!");
//    while(1);
  }

  // Set the range to whatever is appropriate for your project
  accel.setRange(ADXL345_RANGE_16_G);
  // displaySetRange(ADXL345_RANGE_8_G);
  // displaySetRange(ADXL345_RANGE_4_G);
  // displaySetRange(ADXL345_RANGE_2_G);
  printSensorDetails();

  ////////////////////////////
  // Heart Rate Sensor
  // pin that will blink to your heartbeat!
  pinMode(LED13,OUTPUT);

  ////////////////////////////
  // Servo  
  // Attaches the servo on pin 9 to the servo object
  myservo.attach(9);  

  // Block any further work until processing responds
  establishContact();

}

// The Main Loop Function
void loop() {
  readHR();
  readAcc();   
  checkProcessing();
  delay(10);
}

// Construct a string to send to processing
String constructDataForProcessing() {
  String hr = String(hrs);
  String xs = String(x);
  String ys = String(y);
  String zs = String(z);
  String ps = String(pos);
  String ts = String(micros());
  String s = hr + "," + xs + "," + ys + "," + zs + "," + ps + "," + ts;
  
  return s;
}

// Manipulates global state variable hrs
// also visualizes the signal on the LED pin for debugging
void readHR() {
  hrs = analogRead(PulseSensorPurplePin);
  // Visualize on LED just for debugging sake
  checkSignal();
}

// Read accelerometer data
void readAcc() {
  /* Get a new sensor event */ 
  sensors_event_t event; 
  accel.getEvent(&event);
  x = event.acceleration.x;
  y = event.acceleration.y;
  z = event.acceleration.z;
}

// Print "hello" until Processing responds
// Note that this is a blocking loop
void establishContact() {
 while (Serial.available() <= 0) {
      Serial.println("hello");   // send a starting message
      delay(300);
   }
 }

// Deal with instructions from Processing sketch
void checkProcessing() {
  if (Serial.available() > 0) { // If data is available to read,
     int temp = Serial.read();
     handleData(temp);
  }
}

// Do something with the data from Processing
void handleData(int p) {
  if (p == pos) {
    // do not send to servo to reduce jitters
  } else {
    pos = p;
    myservo.write(pos);
  }  
  Serial.println(constructDataForProcessing());
}

// Visualize on LED just for debugging sake
void checkSignal() {
  // If the signal is above "550", then "turn-on" Arduino's on-Board LED.
  // Else, the signal must be below "550", so "turn-off" this LED.
  if (debugging) {
    if (hrs > hrThreshold){                          
      digitalWrite(LED13,HIGH);
    } else {
      digitalWrite(LED13,LOW);                
    }
  }
}

// Print sensor stats to serial
void printSensorDetails() {  
  /* Display some basic information on this sensor */
    displaySensorDetails();
  
  /* Display additional settings (outside the scope of sensor_t) */
  displayDataRate();
  displayRange();
  Serial.println("");
}

