/**
 * provide a calculation and demonstration in server
 * final angle used for complementary (Kalmen w/o variation modification): x_fil, y_fil, z_fil
 * acc & gyro for other calculation: las_acc_gyro.x/y/z_accel/gyro
 * the demonstration animation is just for reference (there are some issue in specific angle)
 */
 
import processing.serial.*;

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
    x_accel=xa;
    y_accel=ya;
    z_accel=za;
    x_gyro=xg;
    y_gyro=yg;
    z_gyro=zg;
    angle_x=ax;
    angle_y=ay;
    angle_z=az;
    }
};

//constant define
float RADIANS_TO_DEGREES = 180/3.14159; 
float alpha = 0.8;

acc_gyro last_acc_gyro = new acc_gyro();  //previous acc and gyro
acc_gyro now_acc_gyro = new acc_gyro();  //current acc and gyro
Serial  myPort;
short   portIndex = 2;
int     lf = 10;       //ASCII linefeed
String  inString;      //String for testing serial communication
int     calibrating;

float   temp;   //temperature
float   dt;     //delta time
float   x_gyr;  //Gyroscope angle
float   y_gyr;
float   z_gyr;
float   x_acc;  //Accelerometer angle
float   y_acc;
float   z_acc;
float   x_fil;  //Filtered angle
float   y_fil;
float   z_fil;

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
  myPort = new Serial(this, portName, 19200);
  myPort.clear();
  myPort.bufferUntil(lf);
  last_acc_gyro.set_value(0,0,0,0,0,0,0,0,0);
} 

void draw_rect_rainbow() {
  scale(90);
  beginShape(QUADS);

  fill(0, 1, 1); vertex(-1,  1.5,  0.25);
  fill(1, 1, 1); vertex( 1,  1.5,  0.25);
  fill(1, 0, 1); vertex( 1, -1.5,  0.25);
  fill(0, 0, 1); vertex(-1, -1.5,  0.25);

  fill(1, 1, 1); vertex( 1,  1.5,  0.25);
  fill(1, 1, 0); vertex( 1,  1.5, -0.25);
  fill(1, 0, 0); vertex( 1, -1.5, -0.25);
  fill(1, 0, 1); vertex( 1, -1.5,  0.25);

  fill(1, 1, 0); vertex( 1,  1.5, -0.25);
  fill(0, 1, 0); vertex(-1,  1.5, -0.25);
  fill(0, 0, 0); vertex(-1, -1.5, -0.25);
  fill(1, 0, 0); vertex( 1, -1.5, -0.25);

  fill(0, 1, 0); vertex(-1,  1.5, -0.25);
  fill(0, 1, 1); vertex(-1,  1.5,  0.25);
  fill(0, 0, 1); vertex(-1, -1.5,  0.25);
  fill(0, 0, 0); vertex(-1, -1.5, -0.25);

  fill(0, 1, 0); vertex(-1,  1.5, -0.25);
  fill(1, 1, 0); vertex( 1,  1.5, -0.25);
  fill(1, 1, 1); vertex( 1,  1.5,  0.25);
  fill(0, 1, 1); vertex(-1,  1.5,  0.25);

  fill(0, 0, 0); vertex(-1, -1.5, -0.25);
  fill(1, 0, 0); vertex( 1, -1.5, -0.25);
  fill(1, 0, 1); vertex( 1, -1.5,  0.25);
  fill(0, 0, 1); vertex(-1, -1.5,  0.25);

  endShape();
  
  
}

void draw_rect(int r, int g, int b) {
  scale(90);
  beginShape(QUADS);
  
  fill(r, g, b);
  vertex(-1,  1.5,  0.25);
  vertex( 1,  1.5,  0.25);
  vertex( 1, -1.5,  0.25);
  vertex(-1, -1.5,  0.25);

  vertex( 1,  1.5,  0.25);
  vertex( 1,  1.5, -0.25);
  vertex( 1, -1.5, -0.25);
  vertex( 1, -1.5,  0.25);

  vertex( 1,  1.5, -0.25);
  vertex(-1,  1.5, -0.25);
  vertex(-1, -1.5, -0.25);
  vertex( 1, -1.5, -0.25);

  vertex(-1,  1.5, -0.25);
  vertex(-1,  1.5,  0.25);
  vertex(-1, -1.5,  0.25);
  vertex(-1, -1.5, -0.25);

  vertex(-1,  1.5, -0.25);
  vertex( 1,  1.5, -0.25);
  vertex( 1,  1.5,  0.25);
  vertex(-1,  1.5,  0.25);

  vertex(-1, -1.5, -0.25);
  vertex( 1, -1.5, -0.25);
  vertex( 1, -1.5,  0.25);
  vertex(-1, -1.5,  0.25);

  endShape();
  
  
}

void draw()  { 
  
  background(0);
  lights();
    
  // Tweak the view of the rectangles
  int distance = 50;
  int x_rotation = 90;
  
  //Show gyro data
  pushMatrix(); 
  translate(width/6, height/2, -50); 
  rotateX(radians(-x_gyr - x_rotation));
  rotateY(radians(-y_gyr));
  draw_rect(249, 250, 50);
  
  popMatrix(); 

  //Show accel data
  pushMatrix();
  translate(width/2, height/2, -50);
  rotateX(radians(-x_acc - x_rotation));
  rotateY(radians(-y_acc));
  draw_rect(56, 140, 206);
  popMatrix();
  
  //Show combined data
  pushMatrix();
  translate(5*width/6, height/2, -50);
  rotateX(radians(-x_fil - x_rotation));
  rotateY(radians(-y_fil));
  draw_rect(93, 175, 83);
  popMatrix();
 
  textSize(24);
  String accStr = "(" + (int) x_acc + ", " + (int) y_acc + ")";
  String gyrStr = "(" + (int) x_gyr + ", " + (int) y_gyr + ")";
  String filStr = "(" + (int) x_fil + ", " + (int) y_fil + ")";
 

  fill(249, 250, 50);
  text("Gyroscope", (int) width/6.0 - 60, 25);
  text(gyrStr, (int) (width/6.0) - 40, 50);

  fill(56, 140, 206);
  text("Accelerometer", (int) width/2.0 - 50, 25);
  text(accStr, (int) (width/2.0) - 30, 50); 
  
  fill(83, 175, 93);
  text("Combination", (int) (5.0*width/6.0) - 40, 25);
  text(filStr, (int) (5.0*width/6.0) - 20, 50);

} 

void serialEvent(Serial p) {

  inString = (myPort.readString());
  print(inString);
  try {
    // Parse the data
    String[] dataStrings = split(inString, '#');
    for (int i = 0; i < dataStrings.length; i++) {
      String type = dataStrings[i].substring(0, 4);
      String dataval = dataStrings[i].substring(4);
    if (type.equals("DEL:")) {
        dt = float(dataval);
      } else if (type.equals("ACC:")) {
        String data[] = split(dataval, ',');
        now_acc_gyro.x_accel = float(data[0]);
        now_acc_gyro.y_accel = float(data[1]);
        now_acc_gyro.z_accel = float(data[2]);
        x_acc = atan(now_acc_gyro.x_accel/sqrt(pow(now_acc_gyro.y_accel,2) + pow(now_acc_gyro.z_accel,2)))*RADIANS_TO_DEGREES;
        y_acc = atan(now_acc_gyro.y_accel/sqrt(pow(now_acc_gyro.x_accel,2) + pow(now_acc_gyro.z_accel,2)))*RADIANS_TO_DEGREES;
        z_acc = atan(sqrt(pow(now_acc_gyro.x_accel,2) + pow(now_acc_gyro.y_accel,2))/now_acc_gyro.z_accel)*RADIANS_TO_DEGREES;
      } else if (type.equals("GYR:")) {
        String data[] = split(dataval, ',');
        now_acc_gyro.x_gyro = float(data[0]);
        now_acc_gyro.y_gyro = float(data[1]);
        now_acc_gyro.z_gyro = float(data[2]);
        x_gyr=now_acc_gyro.x_gyro * dt / (1.0-alpha)+last_acc_gyro.angle_x;
        y_gyr=now_acc_gyro.y_gyro * dt / (1.0-alpha)+last_acc_gyro.angle_y;
        z_gyr=now_acc_gyro.z_gyro * dt / (1.0-alpha)+last_acc_gyro.angle_z;
      } else if (type.equals("TMP:")) {
        temp = float(dataval);
      }
    }
    now_acc_gyro.angle_x = alpha * x_acc + (1.0 - alpha) * x_gyr;
    now_acc_gyro.angle_y = alpha * y_acc + (1.0 - alpha) * y_gyr;
    now_acc_gyro.angle_z = alpha * z_acc + (1.0 - alpha) * z_gyr;
    x_fil = now_acc_gyro.angle_x;
    y_fil = now_acc_gyro.angle_y;
    z_fil = now_acc_gyro.angle_z;
    set_last_angle(now_acc_gyro);  //set now to last angle
  } catch (Exception e) {
      println("Caught Exception");
  }
      

  
}

