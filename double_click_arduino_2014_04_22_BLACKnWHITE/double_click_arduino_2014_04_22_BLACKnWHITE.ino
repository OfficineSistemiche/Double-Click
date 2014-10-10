// doubleCLICK - by OfficineSISTEMICHE - april 2014

#include <Servo.h> 

Servo servoPen, servoRadar;  // create servo objects
// a maximum of eight servo objects can be created 

int brighRead;
int posPen = 171;
int touchPen = 3;
boolean downPen = false;
boolean downPPen = false;

boolean invertRadar = false;
int posRadar = 0;
int shiftRadar = 1;
int moveRadar;
int slowRadar = 0;

void setup() 
{ 
  Serial.begin(9600);

  servoPen.attach(10);  // attaches the servo on pin 10 to the servo object 
  servoRadar.attach(9);  // attaches the servo on pin 9 to the servo object 

  servoPen.write(160);
  servoRadar.write(0);

  establishContact();
} 


void loop() 
{ 

  if (Serial.available() > 0) {
    //read serial: it will be a number between 1 (black) and 9 (white) 
    brighRead = Serial.read();  
    

//--------------------- only BlackandWhite value
    if (brighRead < 9){
      servoPen.write(posPen + touchPen);
      downPen = true;
      }
    if (brighRead == 9){
      servoPen.write(posPen);
      downPen = false;
      }
      
    // when pen has to draw, slow a little the brush servo
    if (downPen != downPPen){
      slowRadar = 30;
      downPPen = downPen;
      } else {
        slowRadar = 0;
        }

      
//--------------------- for GREY scale values
    //brighRead *= 0.5;
    //servoPen.write(posPen + (sqrt(brighRead)*3));



    //------------------------------brush----- 20°
    if (posRadar > 19){
      invertRadar = true;
    } 
    if (posRadar < 1){
      invertRadar = false;
    }
    if (invertRadar == true){
      moveRadar = - shiftRadar;
    } 
    if (invertRadar == false){
      moveRadar = + shiftRadar;
    } 

    posRadar += moveRadar;

    servoRadar.write(posRadar);
    delay(15 + slowRadar);   
    Serial.write(posRadar);

  }
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('A');   // send a capital A
    delay(300);
  }
}

