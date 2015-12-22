/**
 * provide a calculation and demonstration in server
 * final angle used for complementary (Kalmen w/o variation modification): x_fil, y_fil, z_fil
 * acc & gyro for other calculation: las_acc_gyro.x/y/z_accel/gyro
 * the demonstration animation is just for reference (there are some issue in specific angle)
 */
 
import processing.serial.*;
import processing.net.*;
import processing.opengl.*;
import toxi.geom.*;
import toxi.processing.*;

public class acc_gyro
{
    public float x_accel;
    public float y_accel;
    public float z_accel;
    public float x_gyro;
    public float y_gyro;
    public float z_gyro;
    public float angle_x;
    public float angle_y;
    public float angle_z;
    
    public void set_value(float xa, float ya, float za,float xg, float yg, float zg, float ax, float ay, float az){
        x_accel = xa;
        y_accel = ya;
        z_accel = za;
        x_gyro = xg;
        y_gyro = yg;
        z_gyro = zg;
        angle_x = ax;
        angle_y = ay;
        angle_z = az;
    }
    
    public void set_value(float[] val){
        x_accel = val[0];
        y_accel = val[1];
        z_accel = val[2];
        x_gyro = val[3];
        y_gyro = val[4];
        z_gyro = val[5];
        angle_x = val[6];
        angle_y = val[7];
        angle_z = val[8];
    }
};

//constant define
float RADIANS_TO_DEGREES = 180/3.14159;
float alpha = 0.8;
//
char[] teapotPacket = new char[14];  // InvenSense Teapot packet
int serialCount = 2;                 // current packet byte position
int synced = 1;                      //synchronization flag
int interval = 0;                    //time interval
float dt = 0;                      //delta t
float[] q = new float[4];
Quaternion quat = new Quaternion(1, 0, 0, 0);
float[] gravity = new float[3];
float[] euler = new float[3];
float[] ypr = new float[3];
acc_gyro last_acc_gyro = new acc_gyro();  //previous acc and gyro
acc_gyro now_acc_gyro = new acc_gyro();  //current acc and gyro

Serial  myPort;
short   portIndex = 1;
int     lf = 9;       //ASCII linefeed
String  inString;      //String for testing serial communication
int     calibrating;


// Server
Client myClient;
String ip = "127.0.0.1";
int port = 10002;
byte[] buf = new byte[36];
float[] f = new float[9];

void set_last_angle(acc_gyro input) {
  last_acc_gyro.x_accel = input.x_accel;
  last_acc_gyro.y_accel = input.y_accel;
  last_acc_gyro.z_accel = input.z_accel;
  last_acc_gyro.x_gyro = input.x_gyro;
  last_acc_gyro.y_gyro = input.y_gyro;
  last_acc_gyro.z_gyro = input.z_gyro;
  last_acc_gyro.angle_x = input.angle_x;
  last_acc_gyro.angle_y = input.angle_y;
  last_acc_gyro.angle_z = input.angle_z;
}
 
void setup()  { 
//  size(640, 360, P3D); 
  size(1400, 800, P3D);
  noStroke();
  colorMode(RGB, 256); 
 
//  println("in setup");
  String portName = Serial.list()[portIndex];
//  println(Serial.list());
//  println(" Connecting to -> " + Serial.list()[portIndex]);
  myPort = new Serial(this, portName, 38400);
  myPort.write('r');
//  myPort.clear();
//  myPort.bufferUntil(lf);
  last_acc_gyro.set_value(0,0,0,0,0,0,0,0,0);
  
// Client
  myClient = new Client(this, ip, port);
} 

void draw_rect_up(int r, int g, int b) {
  scale(90);
  beginShape(QUADS);
  translate(0, -0.6, 0);
  fill(r, g, b);
  box(0.3, 1, 0.3);
  fill(168, 25, 25);
  translate(0, -1, 0);
  sphere(0.35);
  endShape();
}

void draw_rect_lw(int r, int g, int b) {
  scale(90);
  beginShape(QUADS);
  translate(0, 0.6, 0);
  fill(r, g, b);
  box(0.3, 1, 0.3);
  endShape();
}

void draw()  { 
  
  if (millis() - interval > 1000) {
        // resend single character to trigger DMP init/start
        // in case the MPU is halted/reset while applet is running
        myPort.write('r');
        interval = millis();
    }
    
  background(0);
  lights();
    
  // Tweak the view of the rectangles
  int distance = 50;
  
  //draw upper body
  pushMatrix();
  translate(1*width/6, height/2, -50);
  //float[] axis = quat.toAxisAngle();  //quaternion ratation
  //  rotate(-axis[0], -axis[1], -axis[3], axis[2]);  
  rotateZ(0); //rotate z direction
  rotateX(0); //rotate y direction
  draw_rect_up(93, 175, 83);
  popMatrix();
  
  //draw lower body
  pushMatrix();
  translate(1*width/6, height/2, -50);
  rotateZ(ypr[2]);
  rotateX(ypr[1]);
  draw_rect_lw(93, 175, 0);
  popMatrix();
  
 //draw text angle
  textSize(24);
  String filStr = "(" + (int) now_acc_gyro.angle_x * RADIANS_TO_DEGREES + ", " + (int) now_acc_gyro.angle_y *RADIANS_TO_DEGREES + ", " + (int) now_acc_gyro.angle_z *RADIANS_TO_DEGREES + ")";  
  fill(83, 175, 93);
  text("Combination", (int) (1.0*width/6.0) - 40, 25);
  text(filStr, (int) (1.0*width/6.0) - 20, 50);

  // Client
  f[0] = now_acc_gyro.x_accel;
  f[1] = now_acc_gyro.y_accel;
  f[2] = now_acc_gyro.z_accel;
  f[3] = now_acc_gyro.x_gyro;
  f[4] = now_acc_gyro.y_gyro;
  f[5] = now_acc_gyro.z_gyro;
  f[6] = now_acc_gyro.angle_x;
  f[7] = now_acc_gyro.angle_y;
  f[8] = now_acc_gyro.angle_z;
  
  // send
  for(int i = 0; i < 9; i++){
    int intBit = Float.floatToIntBits(f[i]);
    buf[i*4 + 3] = byte((intBit >> 24) & 0xff);
    buf[i*4 + 2] = byte((intBit >> 16) & 0xff);
    buf[i*4 + 1] = byte((intBit >> 8) & 0xff);
    buf[i*4] = byte(intBit & 0xff);
  }
  myClient.write(buf);
  
  // receive
  int vibrate = myClient.read();
  if(vibrate == 'Y'){
    // TODO: vibrate code
    
    //println(vibrate);
  }
  
  delay(30);  // delay
} 

void serialEvent(Serial port) {
    interval = millis();
    while (port.available() > 0) {
        int ch = port.read();
        if (synced == 0 && ch != '$') return;   // initial synchronization - also used to resync/realign if needed
        synced = 1;
        //print catch buffer
        //print ((char)ch);

        if ((serialCount == 1 && ch != 2)
            || (serialCount == 12 && ch != '\r')
            || (serialCount == 13 && ch != '\n'))  {
            serialCount = 0;
            synced = 0;
            return;
        }
        
        if (serialCount > 0 || ch == '$') {
            teapotPacket[serialCount++] = (char)ch;
            
            if (serialCount == 14) {
                serialCount = 0; // restart packet byte position
                
                // get quaternion from data packet
                q[0] = ((teapotPacket[2] << 8) | teapotPacket[3]) / 16384.0f;
                q[1] = ((teapotPacket[4] << 8) | teapotPacket[5]) / 16384.0f;
                q[2] = ((teapotPacket[6] << 8) | teapotPacket[7]) / 16384.0f;
                q[3] = ((teapotPacket[8] << 8) | teapotPacket[9]) / 16384.0f;
                for (int i = 0; i < 4; i++) if (q[i] >= 2) q[i] = -4 + q[i];
                // set our toxilibs quaternion to new data
                quat.set(q[0], q[1], q[2], q[3]);
                println(quat);
                gravity[0] = 2 * (q[1]*q[3] - q[0]*q[2]);  // acc in x
                gravity[1] = 2 * (q[0]*q[1] + q[2]*q[3]);  // acc in y 
                gravity[2] = q[0]*q[0] - q[1]*q[1] - q[2]*q[2] + q[3]*q[3];  //acc in z
             
                // calculate yaw/pitch/roll angles
                ypr[0] = atan(sqrt(pow(gravity[0],2) + pow(gravity[1],2))/gravity[2]);  //angle x
                ypr[1] = atan(gravity[1] / sqrt(gravity[0]*gravity[0] + gravity[2]*gravity[2]));  //angle y
                ypr[2] = atan(gravity[2] / sqrt(gravity[0]*gravity[0] + gravity[1]*gravity[1]));  //angle z
                
                println("gravity: "+gravity[0]+" "+gravity[1]+" "+gravity[2]);
                println("euler: "+euler[0]+" "+euler[1]+" "+euler[2]);
                println("ypr: "+ypr[0]*RADIANS_TO_DEGREES+" "+ypr[1]*RADIANS_TO_DEGREES+" "+ypr[2]*RADIANS_TO_DEGREES);
                
                now_acc_gyro.x_accel = gravity[0];
                now_acc_gyro.y_accel = gravity[1];
                now_acc_gyro.z_accel = gravity[2];
                now_acc_gyro.x_gyro = ypr[0]*RADIANS_TO_DEGREES;
                now_acc_gyro.y_gyro = ypr[1]*RADIANS_TO_DEGREES;
                now_acc_gyro.z_gyro = ypr[2]*RADIANS_TO_DEGREES;
                now_acc_gyro.angle_x = ypr[0];
                now_acc_gyro.angle_y = ypr[1];
                now_acc_gyro.angle_z = ypr[2];
                
                set_last_angle(now_acc_gyro);  //set now to last angle
            }
        }
    }
}
