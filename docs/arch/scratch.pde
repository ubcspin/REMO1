import processing.serial.*
import java.nio.ByteBuffer;
import java.nio.ByteOrder;


Serial myPort;

String serialPortName = "/dev/tty.usbserial-A9007N9A";

int SERIAL_WRITE_LENGTH = 32;


void setup()
{
  myPort = new Serial(this, serialPortName, 115200);
}




void WriteFloat(float f)
{
  String s = str(f);
  while(s.length() < SERIAL_WRITE_LENGTH)
  {
    s = s + "\0";
  }

   myPort.write(s);
}

void WriteInt(int i)
{
  String s = str(i);
  while(s.length() < SERIAL_WRITE_LENGTH)
  {
    s = s + "\0";
  }
   myPort.write(s);
}


public void UpdateArduino()
{
   myPort.write('p');
   curP = nb[P].getValue();
   WriteFloat(curP);
   myPort.write('t');
   curTarget = (int)nb[TARGET].getValue();
   WriteInt(curTarget);
}


void UpdatePositions()
{
  boolean added = false;
  inputString = "";
  
  byte input[] = new byte[256];
  while(myPort.available() > 0)
  {
    input = myPort.readBytes();
   }
   if (input != null)
   {
     inputString = new String(input);
     String[] inputStrings = inputString.split("\r\n");
     if (inputStrings.length >= 2)
     {
       curPosition = Integer.parseInt(inputStrings[inputStrings.length-2]);
     }
   }     
  
  positions.append(curPosition);
  targets.append(curTarget);
  
  while (positions.size() > nPositions)
  {
    positions.remove(0);
    targets.remove(0);
  }
}