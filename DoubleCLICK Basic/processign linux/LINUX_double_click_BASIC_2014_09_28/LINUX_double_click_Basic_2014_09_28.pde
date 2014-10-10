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

String[] line = loadStrings("/home/alessandro/sketchbook_processing/double_click_ROMA/double_click_2014_09_12_ROMA_muovi_gradiente/data/scelta.txt");

// variables to manage the zoom windows
PGraphics pg0, pg1, pg2, pg3;
int pgwidth = 150;
int pgheight = 150;
int pgXorigin = 1000;
int pgYorigin = 0;

// declare mice coordinates variables
float m1X, m1Y;
float m2X, m2Y;
// declare previous mice coordinates variables
float pm1X, pm1Y;
float pm2X, pm2Y;

// declare initial mice angle (0 = horizontal)
float ang1 = 0;

// declare variable for storing the movement of the brush
// from arduino the angle data comes in Microseconds
float brushmicro;
float brush;

// declare variables for background image
PImage bg;
int imageX;
int imageY;
String sceltaimmagine = line[0];


// declare variable for color value
float col;
float colOut;
// color under mice point
float colm1;
float colm2;


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
//float distance = 9.2/2.54;
float distance = 6.1/2.54;
// resolution of the screen (in dpi)
float screenRes = 106;
// height of canvan where drawing (in cm)
//int canvheight = int(line[x]);   <<<<<<<<<--------------------------<<<<<<<<<<
//float canvheight = 80;
//float canvheight = 70;
float canvheight = 25;
//float canvheight = 30;

// height of the display window (in pixel)
int dispheight = 800;
// distance between brush center (motorino spazzola) and midpoint of mice sensors (in inches)
float distPenMiceY = 12.0/2.54;
float distPenMiceX = -0.5/2.54;
// radius of brush (in inches)
float Rbrush = 0.0/2.54;

// brush variables
int anticipo = 0;
int gradiinizio = 0;
int gradi = 20;
//int gradi = int(line[x]);   <<<<<<<<<--------------------------<<<<<<<<<<

// factor for detecting in advance the pixel color
int advance = 2;

// mouse input adjustment * 400dpi (razer abyssus)
float mouseAdjust = 10.8;

// mouse input adjustment * 3500dpi --- aumenta gli errori!?
//float mouseAdjust = 33.4;

// calculates the value for scaling the coordinates
float scala = canvheight / ((dispheight/screenRes) * 2.54) ;
// scales distance between mice
float largh = (distance*screenRes) / scala;

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

// scale the mice input
float adatta = mouseAdjust * scala;

// is the pen up?
boolean pause = true;

void setup()
{
  size(1400, dispheight);
  background(255);
  noStroke();
  noSmooth();
  noCursor();
  colorMode(RGB);
  frameRate(60);
  
  pg0 = createGraphics(pgwidth, pgheight);
  pg1 = createGraphics(pgwidth, pgheight);
  pg2 = createGraphics(pgwidth, pgheight);
  pg3 = createGraphics(pgwidth, pgheight);

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
  ControllDevice device = controll.getDevice(1);//gets the mouse on the RIGHT
  slider_m1X = device.getSlider(0);
  slider_m1Y = device.getSlider(1);
  // start the RIGHT mouse in the bottom right corner of the image 
  m1X = imageX/2;
  m1Y = imageY/2;
  //float m1XintPos = ????(line[x]); <<<<<<<<<<<<<<<<<<<<----------------<<<<<<<<<<<<<<<<<<<<
  //float m1YintPos = ????(line[x]); <<<<<<<<<<<<<<<<<<<<----------------<<<<<<<<<<<<<<<<<<<<


  // ControllDevice device = controll.getDevice(number assigned to LEFT mouse in devices list)
  device = controll.getDevice(2);//gets the mouse on the LEFT
  slider_m2X = device.getSlider(0);
  slider_m2Y = device.getSlider(1);
  // start the LEFT mouse in the bottom right corner of the image 
  m2X = imageX/2;
  m2Y = imageY/2;
  //float m2XintPos = ????(line[x]); <<<<<<<<<<<<<<<<<<<<----------------<<<<<<<<<<<<<<<<<<<<
  //float m2YintPos = ????(line[x]); <<<<<<<<<<<<<<<<<<<<----------------<<<<<<<<<<<<<<<<<<<<
  
  // Initialize sound object
  minim = new Minim(this);
  out = minim.getLineOut(Minim.MONO);
  sine = new SineWave(440, 0, out.sampleRate());
  sine.portamento(200);
  out.addSignal(sine);
}

void draw()
{
  miceupdate();
  fill(100);

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

  stroke(1);
  ellipse(int(m2X + ((m1X-m2X)/2)), int(m2Y + ((m1Y-m2Y)/2)), 10, 10);
  noFill();
  ellipse(penX, penY, 10, 10);

  fill(0, 255, 0, 5);
  //ellipse(penXget, penYget, 5, 5);

  float centroserX = (spenX * cos(ang1) - spenY * sin(ang1));
  float centroserY = (spenY * cos(ang1) + spenX * sin(ang1));
  float centroservoX = penXorig + centroserX;
  float centroservoY = penYorig + centroserY;
    
  //point(centroservoX, centroservoY);
  line(centroservoX, centroservoY, penX, penY);
  
  */

  // get color value
  col=brightness(get(int(penXget), int(penYget)));

  // remember! serial writes in ascii !!
  
  
  /* greyscale is converted in values to send to arduino:
  0 = NOT USE IT, cause errors in the arduino
  1 to 8 = values for greyscale
  9 = means the pen is up
  */
  
  // when image color is NOT white...
  if (col <= 250) {
    // convert brightness into value from 1 to 9
        // occhio alla scala di grigio, lo 0 è quello che stacca
    colOut = int(col)*8/255 + 1;
    
    //colOut = 1;
    
    // leave a trace on the image (if background is black, you won't see that)
    stroke(col, 0, 0);
    point(int(penXget), int(penYget));
  } 
  else {
    // image color is white...
    colOut = 8;
    
    // leave a trace on the image (in red, you'll see that!)
    stroke(255, 0, 0);
    point(int(penXget), int(penYget));
  }

// store pen position
  penXprev = penX;
  penYprev = penY;

// store brush position
  Pbrush = brush;
  
  //-----------------------------------zoom
  
  pg0.beginDraw();
  pg0.background(col);
  pg0.endDraw();
  image(pg0, pgXorigin, pgYorigin);
  
  pg1.beginDraw();
  pg1.image(bg, (-penXget * 10) + (pgwidth/2), (-penYget * 10) + (pgheight/2), imageX*10, imageY*10);
  pg1.strokeWeight(1);
  pg1.stroke(255, 0, 0);
  pg1.noFill();
  pg1.rect(pgwidth/2 - 2, pgheight/2 - 2, 4, 4);
  pg1.endDraw();
  image(pg1, pgXorigin, pgYorigin + pgheight);
  
  pg2.beginDraw();
  pg2.image(bg, (-penXget * 2) + (pgwidth/2), (-penYget * 2) + (pgheight/2), imageX*2, imageY*2);
  pg1.strokeWeight(2);
  pg2.stroke(255, 0, 0);
  pg2.noFill();
  pg2.rect(pgwidth/2 - 3, pgheight/2 - 3, 6, 6);
  pg2.endDraw();
  image(pg2, pgXorigin, pgYorigin + (pgheight*2)); 
  
  pg3.beginDraw();
  pg3.image(bg, (-penXget / 2) + (pgwidth/2), (-penYget / 2) + (pgheight/2), imageX/2, imageY/2);
  pg1.strokeWeight(2);
  pg3.stroke(255, 0, 0);
  pg3.noFill();
  pg3.rect(pgwidth/2 - 5, pgheight/2 - 5, 10, 10);
  pg3.endDraw();
  image(pg3, pgXorigin, pgYorigin + (pgheight*3)); 
  
}
//-------------------------------------------------------------serial communic
void serialEvent(Serial port) {

  
  //// usare il 16 come numero che (equivale a 20) per comandare spazzolata e picchio???
  
    int inByte = port.read();
//println(inByte);
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

    // If we have 2 bytes:
    // the first incoming byte is the position of the brush
    if (serialCount > 0 ) {
      brushmicro = serialInArray[0];
      brush = map(brushmicro, 0, 1000, 0, 100);
      
    if (pause == true ) {
       port.write(9);
       } else {
      // Send color:
      port.write(int(colOut));
      }
            serialCount = 0;
       
      }
      }
}

void miceupdate()
{

    // calculate the angle between mice
    ang1 = atan2((m1Y - m2Y), (m1X - m2X));

    // uncomment this if you want an automatic reset of distance between mice at every loop (since accumulatin errors lead to a wrong "virtual" distance)
    
    float errore = dist(m1X, m1Y, m2X, m2Y) - largh;
    
    if(errore > 2 || errore < -2){
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
    //
    
  // calculate again the angle between mice
  ang1 = atan2((m1Y - m2Y), (m1X - m2X));
  

  // get mice input values with correction. These changes from mouse to mouse (devices are not identical!)
  float sliderm1X = slider_m1X.getValue() * 1.0;
  float sliderm1Y = slider_m1Y.getValue() * 1.0;
  float sliderm2X = slider_m2X.getValue() * 1.00;
  float sliderm2Y = slider_m2Y.getValue() * 1.0;
  /*
       if (sliderm1X > 0 ) {
       sliderm1X *= 0.994;
       }
     if (sliderm1Y > 0 ) {
       sliderm1Y *= 0.994;
       }
     if (sliderm2X > 0 ) {
       sliderm2X *= 0.994;
       }
     if (sliderm2Y > 0 ) {
       sliderm2Y *= 0.994;
       }
  */
  // calculate position of RIGHT mouse
  float rm1 = sqrt((sliderm1X * sliderm1X) + (sliderm1Y * sliderm1Y));
  float angm1 = atan2(sliderm1Y, sliderm1X);
      //println("angm1 " + degrees(angm1));
      //println(rm1);
  angm1 += radians(-0.0); //---------------------- change if you experience not parallel device
 
  angm1 += ang1; //----------------------------------------------- comment this to set the device indipentent from the other (fot testing disparity)
  sliderm1X = cos(angm1+radians(-0.0)) * rm1;
  sliderm1Y = sin(angm1+radians(-0.0)) * rm1;
  
  
  // calculate position of LEFT mouse
  float rm2 = sqrt((sliderm2X * sliderm2X) + (sliderm2Y * sliderm2Y));
  float angm2 = atan2(sliderm2Y, sliderm2X);
      //println("angm2 " + degrees(angm2));
  angm2 += radians(-0.0); //---------------------- change if you experience not parallel device
 
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
   //println (colOut +" "+ degrees(ang1) +"° "+ (dist(m1X, m1Y, m2X, m2Y) - largh));
  //------------------------------------------------------ use sound to advise the distance error (here the limit is 4)
    vol = map(abs(dist(m1X, m1Y, m2X, m2Y) - largh), 0, 4, 0, 1);
  //vol += map(degrees(abs(ang1)), 0, 2, 0, 1);

noStroke();
 fill (255,255,255);
 rect(width - 100, 50, 100, 50);
 fill (col);
 rect(width - 150, 50, 50, 50);
 fill (0);
 text(degrees(ang1) +"° ", width - 100, 100 );
 
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
  
  //anticipo -= slow * 2;
  //println(anticipo);
  


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
   
  
   
  //anticipo = 2;

  //println(int(Pbrush) + " " + int(brush) + " " + int(Nbrush));
  
  // calculate coordinates of the pen

  float sspenX = spenX + (Rb * cos(radians( gradiinizio - Nbrush)));
  float sspenY = spenY - (Rb * sin(radians( gradiinizio - Nbrush)));
  


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
  
  // get color under mice sensors and leave a sign
  colm1 = get(int(m1X), int(m1Y));
  stroke(0, brightness(int(colm1)), 0);
  point(m1X, m1Y);
  colm2 = get(int(m2X), int(m2Y));
  stroke(0, 0, brightness(int(colm2)));
  point(m2X, m2Y);
  
}

void mousePressed() {
  if (mouseButton == LEFT) {
    
    // when left mouse button pressed set the angle to orizontal and adjust distance errors
    //ang1 = 0;

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

}

void keyPressed() {
  if (keyCode == SHIFT) {
    
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
  
      if (keyCode == BACKSPACE) {
        if (pause == true) {
        pause = false;
        } else {
        pause = true;
       }
  }
}


void stop()
{
  // always close Minim audio classes when you are done with them
  out.close();
  minim.stop();

  super.stop();
}
