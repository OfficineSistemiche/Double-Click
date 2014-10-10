// doubleCLICK - by OfficineSISTEMICHE - april 2014


//occhio a: void establishContact() {
  
#include <Servo.h> 

Servo servoPen, servoRadar;  // create servo objects
// a maximum of eight servo objects can be created 

int brighRead;
int posPen = 1460;
boolean downPen = false;
boolean downPPen = false;

boolean invertRadar = false;
//int StartposRadar = 73;
int StartposRadar = 1500 + 80 - 100;
int posRadar;
int shiftRadar = 4;
int moveRadar;
int slowRadar = 0;
int ritardo = 0;

void setup() 
{ 
  Serial.begin(9600);

  servoPen.attach(10);  // attaches the servo on pin 10 to the servo object 
  servoRadar.attach(9, 1000, 2000);  // attaches the servo on pin 9 to the servo object 

  servoPen.writeMicroseconds(posPen + 100);
  servoRadar.writeMicroseconds(StartposRadar);

  establishContact();
  

} 


void loop() 
{

  if (Serial.available() > 0) {
    //read serial: it will be a number between 1 (black) and 9 (white) 
    brighRead = Serial.read();  
    

/*--------------------- only BlackandWhite value
    if (brighRead < 9){
      servoPen.write(posPen + touchPen);
      downPen = true;
      }
    if (brighRead == 9){
      servoPen.write(posPen);
      downPen = false;
      }
*/   

    if (brighRead == 9){
      servoPen.writeMicroseconds(posPen + 100);
      } else {

//--------------------- for GREY scale values
    brighRead *= -5; // per pennello
    //brighRead *= -2; // per pennello muji??
 
    servoPen.writeMicroseconds(posPen - brighRead);
        delay(ritardo);  

    }
    
        //------------------------------brush----- 20°
    if (posRadar > 200){
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
        
    //servoRadar.write(StartposRadar + posRadar);
    servoRadar.writeMicroseconds(StartposRadar + posRadar);
    //delay(ritardo + (ritardo * abs(pbrighRead - brighRead))); 
    delay(ritardo);  
 
    
   Serial.write(posRadar);
   

  }
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('A');   // send a capital A
    delay(300);
  }
}

