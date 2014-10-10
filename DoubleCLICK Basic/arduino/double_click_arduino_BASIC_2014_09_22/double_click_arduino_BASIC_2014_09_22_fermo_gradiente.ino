// doubleCLICK - by OfficineSISTEMICHE - april 2014


//occhio a: void establishContact() {
  
#include <Servo.h> 

Servo servoPen, servoRadar;  // create servo objects
// a maximum of eight servo objects can be created 

int brighRead;
//int posPen = 1405; //muj
int posPen = 1500; // 1500 centro

boolean downPen = false;
boolean downPPen = false;

boolean invertRadar = false;
int StartposRadar = 1500 + 0 - 100;

int posRadar = 0;
int shiftRadar = 3;
int moveRadar;
int slowRadar = 0;
int ritardo = 0;

void setup() 
{ 
  Serial.begin(9600);
   // while the serial stream is not open, do nothing:
   while (!Serial) ;

  servoPen.attach(10);  // attaches the servo on pin 10 to the servo object 
  //servoRadar.attach(9, 1000, 2000);  // attaches the servo on pin 9 to the servo object 

  servoPen.writeMicroseconds(posPen + 200);
  //servoRadar.writeMicroseconds(StartposRadar);

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
      servoPen.writeMicroseconds(posPen + 200);
      } else {


//--------------------- for GREY scale values
   // brighRead *= -4; // per pennello muji gradiente
        brighRead *= -5; // per pennello
    //brighRead *= 0.2; // per punta piccola
    //servoPen.write(posPen - (sqrt(brighRead)*3));
    //servoPen.write(posPen - sqrt(brighRead));
    servoPen.writeMicroseconds(posPen - brighRead);
    }
    
       Serial.write(posRadar);

  }
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('A');   // send a capital A
    delay(300);
  }
}

