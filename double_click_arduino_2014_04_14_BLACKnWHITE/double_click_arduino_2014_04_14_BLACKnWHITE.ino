// Sweep
// by BARRAGAN <http://barraganstudio.com> 
// This example code is in the public domain.


#include <Servo.h> 

Servo servoPen, servoRadar;  // create servo object to control a servo 
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
  // occhio a quando lo apri e chiudi:
  if (Serial.available() > 0) {
    //leggi dal serial: sarà un numero tra 1 (nero) e 9 (bianco) 
    brighRead = Serial.read();  
    

//--------------------- BianoNero
    if (brighRead < 9){
      servoPen.write(posPen + touchPen);
      downPen = true;
      }
    if (brighRead == 9){
      servoPen.write(posPen);
      downPen = false;
      }
    
    if (downPen != downPPen){
      slowRadar = 30;
      downPPen = downPen;
      } else {
        slowRadar = 0;
        }

      
//--------------------- chiaroscuro
    //brighRead *= 0.5;
    //servoPen.write(posPen + (sqrt(brighRead)*3));



    //------------------------------spazzola----- 20° di giro
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

