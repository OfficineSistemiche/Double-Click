/* doubleCLICK - by OfficineSISTEMICHE - april 2014
 assembled and hacked from:
 http://creativecomputing.cc/p5libs/procontroll/index.htm
 http://foxssic.wordpress.com/2007/02/06/dual-mouse-control-in-processing/
 Sine Wave Signal - by Damien Di Fede.
 
 before running on linux:
 * allow procontroll library to read the mice input 
 copy and paste to terminal ---> sudo chmod go=u /dev/input/event*
 * allow processing to read the serial data from arduino
 copy and paste to terminal ---> sudo ln -s /dev/ttyACM0 /dev/ttyS42
 */

// load libraries
import processing.serial.*;
import procontroll.*;
import java.io.*;
// libraries for audio
import ddf.minim.*;
import ddf.minim.signals.*;

// declare objects
Serial port;
int[] serialInArray = new int[1];    // Where we'll put what we receive
int serialCount = 0;                 // A count of how many bytes we receive
boolean firstContact = false;        // Whether we've heard from the microcontroller

ControllIO controll;
ControllSlider slider_m1X, slider_m1Y;
ControllSlider slider_m2X, slider_m2Y;

Minim minim;
AudioOutput out;
SineWave sine;

// declare mice coordinates variables
float m1X, m1Y;
float m2X, m2Y;
// declare previous mice coordinates variables
float pm1X, pm1Y;
float pm2X, pm2Y;

// declare initial mice angle (0 = horizontal)
float ang1 = 0;

// declare variable for storing the movement of the brush
int brush;

// declare variables for background image
PImage bg;
int imageX;
int imageY;

// declare variable for color value
float col;
float colOut;
// color under the reference point
float col2;


// declare pen coordinates
float penX, penY;
// declare previous pen coordinates
float penXprev, penYprev;
// declare the coordinates for color getting
float penXget, penYget;
// declare variables for sound check
float freq = 0;
float vol = 0;

// CHANGE FOLLOWING VARIABLES IN ACCORDANCE WITH YOUR SETUP
// distance between mice sensors (in inches)
//float distance = 9.35/2.54;
float distance = 9.2/2.54;
// resolution of the screen (in dpi)
float screenRes = 106;
// height of canvan where drawing (in cm)
float canvheight = 70;
//float canvheight = 60;
// height of the display window (in pixel)
int dispheight = 800;
// distance between brush center (motorino spazzola) and midpoint of mice sensors (in inches)
float distPenMiceY = 11.4/2.54;
float distPenMiceX = -5.8/2.54;
// radius of brush (in inches)
float Rbrush = 6.4/2.54;

// per la spazzola. anticipo in funzione della scala del pennino??
int anticipo = 2;
int gradi = 20;

// serve ?
int advance = 3;

  
// mouse input adjustment * 400dpi
float mouseAdjust = 4.25;

// mouse input adjustment * 3500dpi --- aumenta gli errori!?
//float mouseAdjust = 33.4;

// number of marks on Y axis
int marks = 10;

// calculates the value for scaling the coordinates
float scala = canvheight / ((dispheight/screenRes) * 2.54) ;
// scales distance between mice
float largh = (distance*screenRes) / scala;

// dimension reference schema
float raggio = ((22/2.54)*screenRes) / scala;


float penXorig; 
float penYorig;
float PrepenXorig; 
float PrepenYorig;
// scales distance between pen and midpoint of mice sensors
float spenY = int(((distPenMiceY)*screenRes)/scala);
float spenX = int(((distPenMiceX)*screenRes)/scala);
float Pbrush;
float Nbrush;
float Rb = (Rbrush*screenRes)/scala;

// use this to set a reference point for positioning the device (for example the corner of the case)
// distance da midpoint of mice sensors (in inches) to case reference
float ddistRifY = 6.3/2.54;
float ddistRifX = 8/2.54;
float distRifY = int(((ddistRifY)*screenRes)/scala);
float distRifX = int(((ddistRifX)*screenRes)/scala);
float RifY;
float RifX;

// scale the mice input
float adatta = mouseAdjust * scala;


void setup()
{

  size(1400, dispheight);
  background(255);
  noStroke();
  noSmooth();
  noCursor();
  colorMode(RGB);
  frameRate(60);

  println("Available serial ports:");
  println(Serial.list());

  // Uses the first port in this list (number 0).  Change this to
  // select the port corresponding to your Arduino board.  The last
  // parameter (e.g. 9600) is the speed of the communication.  It
  // has to correspond to the value passed to Serial.begin() in your
  // Arduino sketch.
  
  port = new Serial(this, Serial.list()[0], 9600);  
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

  // If you know the name of the port used by the Arduino board, you
  // can specify it directly like this.
  //port = new Serial(this, "COM1", 9600);

  // load and place image
  bg = loadImage("victory.jpg");

  imageX = bg.width;
  imageY = bg.height;

  imageX = (height * imageX)/imageY;
  imageY = height;

  image(bg, 0, 0, imageX, imageY);

  fill(0);
  
  // print devices list
  controll = ControllIO.getInstance(this);
  controll.printDevices();

  // ControllDevice device = controll.getDevice(number assigned to RIGHT mouse in devices list)
  ControllDevice device = controll.getDevice(4);//gets the mouse on the RIGHT
  slider_m1X = device.getSlider(0);
  slider_m1Y = device.getSlider(1);
  
  // start the RIGHT mouse in the bottom right corner of the image 
  m1X = imageX - distRifX + largh/2 ;
  m1Y = imageY - distRifY - 50;
  
  // use these to adjust the vertical align of mouse
  //m1Y -= largh / 20;

  // position RIGHT mouse in center (for reference schema):
  //  m1X = width/2 + largh/2;
  //  m1Y = height/2 + raggio;

  // ControllDevice device = controll.getDevice(number assigned to LEFT mouse in devices list)
  device = controll.getDevice(5);//gets the mouse on the LEFT
  slider_m2X = device.getSlider(0);
  slider_m2Y = device.getSlider(1);
  
  // start the LEFT mouse in the bottom right corner of the image 
  m2X = imageX - distRifX - largh/2;
  m2Y = imageY - distRifY - 50;


  // position LEFT mouse in center (for reference schema):
  //  m2X = width/2 - largh/2;
  //  m2Y = height/2 + raggio;



  // vertical grid marks
  for (int i=1; i<imageY; i = i + (imageY/marks)) {
    stroke(0);
    line(imageX, i, imageX + 10, i);
    text(i/(imageY/marks), imageX + 20, i);
    line(0, i, 20, i);
    text(i/(imageY/marks), 20, i);
    
  // orizontal marks (same distance of the vertical ones)
    line(imageX - i, 795, imageX - i, height);
  }
  
  // Initialize sound object
  minim = new Minim(this);
  out = minim.getLineOut(Minim.MONO);
  sine = new SineWave(440, 0, out.sampleRate());
  sine.portamento(200);
  out.addSignal(sine);
}

void draw()
{
  //background(255);
  miceupdate();
  fill(100);
  
  /* -------------------------------------------------------------------- uncomment to show reference schema
  pushMatrix();
  noFill();
  translate(width/2, height/2);
  ellipse(0, 0, raggio*2, raggio*2);
  line(-raggio, 0, raggio, 0);
  popMatrix();

  pushMatrix();
  noFill();
  translate(width/2 - raggio, height/2);
  rotate(radians(-60));
      line(raggio - largh/2, 0, raggio + largh/2, 0);
  rotate(radians(120));
        line(raggio - largh/2, 0, raggio + largh/2, 0);
  ellipse(0, 0, raggio*2, raggio*2);
  popMatrix();
  
  pushMatrix();
  noFill();
  translate(width/2 + raggio, height/2);
  rotate(radians(-120));
      line(raggio - largh/2, 0, raggio + largh/2, 0);
  rotate(radians(240));
        line(raggio - largh/2, 0, raggio + largh/2, 0);
  ellipse(0, 0, raggio*2, raggio*2);
  popMatrix();
  
  pushMatrix();
  float ruota = radians(30);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();
  
    pushMatrix();
  ruota = radians(45);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();

  pushMatrix();
  ruota = radians(60);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();

  pushMatrix();
  ruota = radians(90);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();
    
  pushMatrix();
  ruota = radians(-30);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();
  
    pushMatrix();
  ruota = radians(-45);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();

  pushMatrix();
  ruota = radians(-60);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();

  pushMatrix();
  ruota = radians(0);
  translate(width/2, height/2);
  rotate(ruota);
    line(-raggio, 0, raggio, 0);
  translate(-raggio, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  rotate(ruota);
  translate(raggio*2, 0);
  rotate(-ruota);
    line(-largh/2, 0, largh/2, 0);
  popMatrix();
  
  */

  /* ---------------------------------------------------------------------------- uncomment to show contruction lines
  line (imageX - largh/2, 0, imageX - largh/2, height);
  line (imageX + largh/2, 0, imageX + largh/2, height);

  noStroke();
  fill(0, 255, 0, 5);
  ellipse(m1X, m1Y, 5, 5);
  fill(0, 0, 255, 5);
  ellipse(m2X, m2Y, 5, 5);
  stroke(255, 0, 0, 5);
  line(m1X, m1Y, m2X, m2Y);

  fill(0, 255, 0, 5);
  ellipse(m1Xe, m1Ye, 5, 5);
  ellipse(m2Xe, m2Ye, 5, 5);

  stroke(1);
  ellipse(int(m2X + ((m1X-m2X)/2)), int(m2Y + ((m1Y-m2Y)/2)), 10, 10);
  noFill();
  ellipse(penX, penY, 10, 10);

  fill(0, 255, 0, 5);
  ellipse(penXget, penYget, 5, 5);
  */

  // get color value
  col=brightness(get(int(penXget), int(penYget)));

  // remember! serial writes in ascii !!
  
  // when image color is NOT white...
  if (col <= 250) {
    // convert brightness into value from 1 to 9
    colOut = int(col)*9/255;
    
    // leave a trace on the image (in black, you won't see that)
    stroke(col, 0, 0);
    point(int(penXget), int(penYget));
  } 
  else {
    // image color is white...
    colOut = 9;
    
    // leave a trace on the image (in red, you'll see that!)
    stroke(255, 0, 0);
    point(int(penXget), int(penYget));
  }

  penXprev = penX;
  penYprev = penY;
  
  Pbrush = brush;
  
}
//-------------------------------------------------------------serial communic
void serialEvent(Serial port) {
  // read a byte from the serial port:
  int inByte = port.read();
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:
  if (firstContact == false) {
    if (inByte == 'A') { 
      port.clear();          // clear the serial port buffer
      firstContact = true;     // you've had first contact from the microcontroller
      port.write('A');       // ask for more
    } 
  } 
  else {
    // Add the latest byte from the serial port to array:
    serialInArray[serialCount] = inByte;
    serialCount++;

    // If we have 3 bytes:
    if (serialCount > 0 ) {
      brush = serialInArray[0];
      //ypos = serialInArray[1];

      // Send color:
      port.write(int(colOut));
      
      // Reset serialCount:
      serialCount = 0;
    }
  }
}

void miceupdate()
{

    // calculate the angle between mice
    ang1 = atan2((m1Y - m2Y), (m1X - m2X));

    // uncomment this if you want an automatic reset of distance between mice at every loop (since accumulatin errors lead to a wrong "virtual" distance)
    /*
    float dmXY = dist (m1X, m1Y, m2X, m2Y);

    float dm1X = (m1X - m2X) - (largh*cos(ang1));
    float dm1Y = (m1Y - m2Y) - (largh*sin(ang1));

    float dm2X = (m2X - m1X) + (largh*cos(ang1));
    float dm2Y = (m2Y - m1Y) + (largh*sin(ang1));

    float em1X = (dm1X/2 * cos(ang1) - dm1Y/2 * sin(ang1));
    float em1Y = (dm1Y/2 * cos(ang1) + dm1X/2 * sin(ang1));

    float em2X = (dm2X/2 * cos(ang1) - dm2Y/2 * sin(ang1));
    float em2Y = (dm2Y/2 * cos(ang1) + dm2X/2 * sin(ang1));

    m1X -= em1X;
    m1Y -= em1Y;

    m2X -= em2X;
    m2Y -= em2Y;
    
  // calculate again the angle between mice
  ang1 = atan2((m1Y - m2Y), (m1X - m2X));
  */

  // get mice input values with correction. These changes from mouse to mouse (devices are not identical!)
  float sliderm1X = slider_m1X.getValue() * 1.0;
  float sliderm1Y = slider_m1Y.getValue() * 1.0;
  float sliderm2X = slider_m2X.getValue() * 0.99;
  float sliderm2Y = slider_m2Y.getValue() * 0.99;
  
  
  // calculate position of RIGHT mouse
  float rm1 = sqrt((sliderm1X * sliderm1X) + (sliderm1Y * sliderm1Y));
  float angm1 = atan2(sliderm1Y, sliderm1X);
      //println("angm1 " + degrees(angm1));
      //println(rm1);
  angm1 += radians(+0.0); //---------------------- change if you experience not parallel device
 
  angm1 += ang1; //----------------------------------------------- comment this to set the device indipentent from the other (fot testing disparity)
  sliderm1X = cos(angm1+radians(0.0)) * rm1;
  sliderm1Y = sin(angm1+radians(0.0)) * rm1;
  
  
  // calculate position of LEFT mouse
  float rm2 = sqrt((sliderm2X * sliderm2X) + (sliderm2Y * sliderm2Y));
  float angm2 = atan2(sliderm2Y, sliderm2X);
      //println("angm2 " + degrees(angm2));
  angm2 += radians(-0.2); //---------------------- change if you experience not parallel device
  
  angm2 += ang1; //----------------------------------------------- comment this to set the device indipentent from the other (fot testing disparity)
  sliderm2X = cos(angm2+radians(-0.0)) * rm2;
  sliderm2Y = sin(angm2+radians(-0.0)) * rm2;
  
  

  // scale mice input according to canvan 
  sliderm1X /= adatta;
  sliderm1Y /= adatta;
  sliderm2X /= adatta;
  sliderm2Y /= adatta;

  // ----------------------------------------------- finally obtain the screen coordinates of mice

    float X1 = sliderm1X;
    float Y1 = sliderm1Y;
    float X2 = sliderm2X;
    float Y2 = sliderm2Y;
    
  m1X += X1;
  m1Y += Y1;
  m2X += X2;
  m2Y += Y2;
  

  // tell me angle degreee and discrepancy from real and virtual mice distance
   println (degrees(ang1) +"° "+ (dist(m1X, m1Y, m2X, m2Y) - largh));
  //------------------------------------------------------ use sound to advise the distance error (here the limit is 4)
    vol = map(abs(dist(m1X, m1Y, m2X, m2Y) - largh), 0, 4, 0, 1);
  //vol += map(degrees(abs(ang1)), 0, 2, 0, 1);

  if (vol > 1) {
    vol = 1;
  }
  sine.setFreq(map(vol, 0, 1, 100, 400));
  sine.setAmp(vol);


  // ----------------------------------------------------- calculate pen coordinates

  penXorig = m2X + (m1X-m2X)/2;
  penYorig = m2Y + (m1Y-m2Y)/2;
  
  
  // calculate in advance the position of the moving brush
  if(Pbrush != brush){
    
    if(Pbrush > brush){
      Nbrush = brush - anticipo;
      if (Nbrush < 0){
        Nbrush = 0 - Nbrush;
      }
    }
      if(Pbrush < brush){
      Nbrush = brush + anticipo;
      if (Nbrush > gradi){
        Nbrush = gradi + (gradi - Nbrush);
      }
    }
    
   } 
  //println(Pbrush + " " + brush + " " + Nbrush);
  
  // calculate coordinates of the pen

  float sspenX = spenX + (Rb * cos(radians( 15 - Nbrush)));
  float sspenY = spenY - (Rb * sin(radians( 15 - Nbrush)));

  float pX = (sspenX * cos(ang1) - sspenY * sin(ang1));
  float pY = (sspenY * cos(ang1) + sspenX * sin(ang1));

  penX =  penXorig + pX;
  penY =  penYorig + pY;

  // --------get the color in front of the pen (to avoid delay between get and draw)
  float pXa = PrepenXorig - penXorig;
  float pYa = PrepenYorig - penYorig;

  float pXv = ((pXa*advance) * cos(PI) - (pYa*advance) * sin(PI));
  float pYv = ((pYa*advance) * cos(PI) + (pXa*advance) * sin(PI));
  
  penXget =  penX + pXv;
  penYget =  penY + pYv;
  
  pm1X = m1X;
  pm1Y = m1Y;
  pm2X = m2X;
  pm2Y = m2Y;
  

  PrepenXorig = pm2X + (pm1X-pm2X)/2;
  PrepenYorig = pm2Y + (pm1Y-pm2Y)/2;
  
  // calculate coordinates of the reference point
  float rX = (distRifX * cos(ang1) - distRifY * sin(ang1));
  float rY = (distRifY * cos(ang1) + distRifX * sin(ang1));

  RifX =  penXorig + rX;
  RifY =  penYorig + rY;
  
  // get color in reference point and leave a sign
  col2 = get(int(RifX), int(RifY));
  stroke(0, 0, brightness(int(col2)));
  point(RifX, RifY);
  
}

void mousePressed() {
  if (mouseButton == LEFT) {
    
    // when left mouse button pressed set the angle to orizontal and adjust distance errors
    ang1 = 0;

    float dmXY = dist (m1X, m1Y, m2X, m2Y);

    float dm1X = (m1X - m2X) - (largh*cos(ang1));
    float dm1Y = (m1Y - m2Y) - (largh*sin(ang1));

    float dm2X = (m2X - m1X) + (largh*cos(ang1));
    float dm2Y = (m2Y - m1Y) + (largh*sin(ang1));

    float em1X = (dm1X/2 * cos(ang1) - dm1Y/2 * sin(ang1));
    float em1Y = (dm1Y/2 * cos(ang1) + dm1X/2 * sin(ang1));

    float em2X = (dm2X/2 * cos(ang1) - dm2Y/2 * sin(ang1));
    float em2Y = (dm2Y/2 * cos(ang1) + dm2X/2 * sin(ang1));

    m1X -= em1X;
    m1Y -= em1Y;

    m2X -= em2X;
    m2Y -= em2Y;
  }

  if (mouseButton == RIGHT) {

    // when right mouse button is pressed set coordinates to the nearest intersection of the grid
    int penXAlign = 0;
    int penYAlign = 0;
    int qualetaccaY = 0;
    int qualetaccaX = 0;

    int taccheY = marks;
    int larghTacca = imageY / taccheY;
    penYget += larghTacca/2;

//usare round(...)?

    float iY = map(penYget, 0, imageY, 0, taccheY);
    qualetaccaY = int(iY);
    penYAlign = qualetaccaY * larghTacca;

    // occhio le tacche sono riferite a imageY/marks !
    int taccheX = imageX / larghTacca;
    penXget -= larghTacca/2;

    float iX = map(penXget, 0, imageX, taccheX, 0);
    qualetaccaX = int(iX);
    penXAlign = imageX - (qualetaccaX * (larghTacca));

    m1X = penXAlign + largh/2;
    m1Y = penYAlign - spenY;

    m2X = penXAlign - largh/2;
    m2Y = penYAlign - spenY;
  }
}

void keyPressed() {
  if (keyCode == SHIFT) {
    
    // when SHIFT is pressed set coordinates to the left edge of the image
    ang1 = 0;

    float dmXY = dist (m1X, m1Y, m2X, m2Y);

    float dm1X = (m1X - m2X) - (largh*cos(ang1));
    float dm1Y = (m1Y - m2Y) - (largh*sin(ang1));

    float dm2X = (m2X - m1X) + (largh*cos(ang1));
    float dm2Y = (m2Y - m1Y) + (largh*sin(ang1));

    float em1X = (dm1X/2 * cos(ang1) - dm1Y/2 * sin(ang1));
    float em1Y = (dm1Y/2 * cos(ang1) + dm1X/2 * sin(ang1));

    float em2X = (dm2X/2 * cos(ang1) - dm2Y/2 * sin(ang1));
    float em2Y = (dm2Y/2 * cos(ang1) + dm2X/2 * sin(ang1));

    m1X -= em1X;
    m1Y -= em1Y;

    m2X -= em2X;
    m2Y -= em2Y;

    m1X = imageX + largh/2;
    m2X = imageX - largh/2;
  }
  
  // adjust the position with arrows

  if (keyCode == UP) {
    m1Y -= 1;
    m2Y -= 1;
    point(int(penXget), int(penYget));
  }
  if (keyCode == DOWN) {
    m1Y += 1;
    m2Y += 1;
    stroke(255, 255, 255);
    point(int(penXget), int(penYget));
  }
  if (keyCode == LEFT) {
    m1X -= 1;
    m2X -= 1;
    stroke(255, 255, 255);
    point(int(penXget), int(penYget));
  }
  if (keyCode == RIGHT) {
    m1X += 1;
    m2X += 1;
    stroke(255, 255, 255);
    point(int(penXget), int(penYget));
  }
  
  // tweak the advance variable
    if (keyCode == TAB) {
    advance += 1;
    println(advance);
  }
      if (keyCode == DELETE) {
    advance -= 1;
    println(advance);
  }
}


void stop()
{
  // always close Minim audio classes when you are done with them
  out.close();
  minim.stop();

  super.stop();
}
