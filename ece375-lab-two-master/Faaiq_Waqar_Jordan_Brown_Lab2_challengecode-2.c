// Faaiq_Waqar_Jordan_Brown_Lab2_challengecode.c
/*
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.
PORT MAP
Port B, Pin 4 -> Output -> Right Motor Enable
Port B, Pin 5 -> Output -> Right Motor Direction
Port B, Pin 7 -> Output -> Left Motor Enable
Port B, Pin 6 -> Output -> Left Motor Direction
Port D, Pin 1 -> Input -> Left Whisker
Port D, Pin 0 -> Input -> Right Whisker
*/

/*
AUTHOR(S): Faaiq Waqar & Jordan Brown
DATE: October 11th 2019
COURSE AND LAB: ECE 375 :: Friday 4-6
VERSION: Challenge Program Code
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

int main(void)
{
	DDRB = 0b11110000; //configure port B pins for input/output
	DDRD = 0b00000000; //Configure port D pins for input/output
	PORTB = 0b11110000;
	PORTD = 0b00000011;
	
	
	while (1) // loop forever
	{
		PORTB = 0b01100000;
		
		if(PIND == 0b11111101){ //Right Whisker
			_delay_ms(500);//wait while continuing forward
			PORTB = 0b00000000;//reverse
			_delay_ms(1000); //wait 1 second
			PORTB = 0b00100000;// turn right toward object
			_delay_ms(500);//wait then exit conditional and continue forward
		}
		
		else if(PIND == 0b11111110){ //Left Whisker
			_delay_ms(500);//wait while continuing forward
			PORTB = 0b00000000;//reverse
			_delay_ms(1000);//wait 1 second
			PORTB = 0b01000000; //turn left toward the object
			_delay_ms(500);//wait then exit conditional and continue forward
		}
		
		else if(PIND == 0b11111100){ //Both Whisker
			_delay_ms(500);//wait while continuing forward
			PORTB = 0b00000000;//reverse
			_delay_ms(1000);//wait then exit the conditional and begin moving forward
			//PORTB = 0b01000000;
			//_delay_ms(500);
			
		}
		
	
		
		
	}
}
