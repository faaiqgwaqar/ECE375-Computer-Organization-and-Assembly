;***********************************************************
;*
;*	Faaiq_Waqar_and_Jordan_Brown_lab8_Tx_sourcecode.asm
;*
;*	This is the USART Reciever
;*
;*	This is the TRANSMIT skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Faaiq Waqar & Jordan Brown
;*	   Date: December 5th 2019
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	spr	= r17				; Secondary-Purpose Register
.def	cpr = r18				; Comparative-Purpose Register

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze =  0b11111000

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer
	ldi		mpr, high(RAMEND)
	out		SPH, mpr
	ldi		spr, low(RAMEND)
	out		SPL, spr
	;I/O Ports

	ldi		mpr, 0b11111111
	out		DDRB, mpr

	ldi		mpr, (1<<3)		; Set Port B Data Direction Register
	out		DDRD, mpr						; for output
	ldi		mpr, (1<<0|1<<1|1<<4|1<<5|1<<6|1<<7)		; Initialize Port D Data Register
	out		PORTD, mpr						; so all Port D inputs are Tri-State
	;USART1
		;Set baudrate at 2400bps
	ldi		mpr, high(832) ; Do We Round up or Down?
	sts		UBRR1H, mpr
	ldi		spr, low(832) ; Same Question applies here
	sts		UBRR1L, spr
		;Enable transmitter
	ldi		mpr, (1<<U2X1)	; Set Double Data Rate for Transmission
	sts		UCSR1A, mpr		; Load to Control Register A
	ldi		mpr, (1<<TXEN1|0<<UCSZ12)	;Enable the transmitter
	sts		UCSR1B, mpr					;Load to COntrol Register B
	ldi		mpr, (0<<UMSEL1|0<<UPM11|0<<UPM10|1<<USBS1|1<<UCSZ11|1<<UCSZ10) ; Enable8 bits and 2 stop
	sts		UCSR1C, mpr					; Load to control register C
	;Set frame format: 8 data bits, 2 stop bits

	;Other

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		in		cpr, PIND			; Use polling method and take in Buton input
		andi	cpr, 0b11110011		; And with this binary to eliminate issues with Tx/Rx Bits
		cpi		cpr, 0b01110011		; Forward Command Check
		breq	USART_FWD
		cpi		cpr, 0b10110011		; Backwars Command Check
		breq	USART_BCK
		cpi		cpr, 0b11010011		; Right Command Check
		breq	USART_RGT
		cpi		cpr, 0b11100011		; Left Command Check
		breq	USART_LFT
		cpi		cpr, 0b11110001		; Halt Command Check
		breq	USART_HLT
		cpi		cpr, 0b11110010		; Freeze Command Check
		breq	USART_FRZ
		
		rjmp	MAIN				; Jump back to main in order to create a loop

USART_FWD:
		LDI		mpr, 0b00000001		; Use the PORTB lights to check for routine call
		OUT		portB, mpr
		
		rcall	USART_ADDR			; Subroutine to send the address first
		
Check_FWD:
		lds		spr, UCSR1A			; Check for the empty flag from control reg A
		sbrs	spr, UDRE1			; Check Specific bit
		rjmp	Check_FWD			; Repeat until empty
		ldi		mpr, MovFwd			; Prepare to send mov forward command
		sts		UDR1, mpr			; Place into UDR for Tx
		rjmp	MAIN				; Jump back to main loop


USART_BCK:
		LDI		mpr, 0b00000010		;  Use PORTB lights to check for subroutine call
		OUT		portB, mpr			
		rcall	USART_ADDR			; Call to send the address

Check_BCK:
		lds		spr, UCSR1A			; Check to see if the register is empty for transmission
		sbrs	spr, UDRE1			; using the UDRE flag
		rjmp	Check_BCK
		ldi		mpr, MovBck			; Prepare move back command
		sts		UDR1, mpr			; Send
		rjmp	MAIN				; Go back to main

USART_RGT:
		LDI		mpr, 0b00000100		; use PORTB lights to check for subroutine call
		OUT		portB, mpr
		
		rcall	USART_ADDR

Check_RGT:
		lds		spr, UCSR1A			; Check that UDR is ready using the empty flag in A
		sbrs	spr, UDRE1
		rjmp	Check_RGT			; loop till objective met
		ldi		mpr, TurnR			; prepare turn right for transmission
		sts		UDR1, mpr			; Transmission send
		rjmp	MAIN				; Jump back to main

USART_LFT:
		LDI		mpr, 0b00001000		; Use PORTB lights to check for subroutine call
		OUT		portB, mpr
		
		rcall	USART_ADDR			; Send the address first

Check_LFT:
		lds		spr, UCSR1A			; Check that UDRE is set so we know that we can Tx
		sbrs	spr, UDRE1	
		rjmp	Check_LFT			; Keep looping till its empty
		ldi		mpr, TurnL			; Load Turn Left
		sts		UDR1, mpr			; Send it
		rjmp	MAIN				; Return to main loop

USART_HLT:
		LDI		mpr, 0b00010000		; Use PORTB lights to check for subroutine call
		OUT		portB, mpr
		

		rcall	USART_ADDR			; Send the address first

Check_HLT:
		lds		spr, UCSR1A			; Check to see that the UDRE flag is set so that we know to transmit
		sbrs	spr, UDRE1
		rjmp	Check_HLT			; Loop until condition is met
		ldi		mpr, Halt			; Load the halt command
		sts		UDR1, mpr			; Send it
		rjmp	MAIN				; Go back to the main loop

USART_FRZ:
		LDI		mpr, 0b10000000		; Use PORTB to show this is happening
		OUT		portB, mpr
		

		rcall	USART_ADDR			; Send that address over

Check_FRZ:
		lds		spr, UCSR1A			; Wait until the UDRE flag is set so we can send
		sbrs	spr, UDRE1
		rjmp	Check_FRZ			; Keep waiting till conditions
		ldi		mpr, Freeze			; Prepare freeze command
		sts		UDR1, mpr			; Send Freeze
		rjmp	MAIN				; Jump to main program

USART_ADDR:
		lds		spr, UCSR1A			; Wait until the UDRE flag is set so we can send
		sbrs	spr, UDRE1
		rjmp	USART_ADDR			; kEEP WAITING TILL READY
		ldi		mpr, $2F			; Send the address first
		sts		UDR1, mpr
		ret

		

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
