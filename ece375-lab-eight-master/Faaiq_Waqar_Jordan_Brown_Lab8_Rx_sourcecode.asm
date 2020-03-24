;***********************************************************
;*
;*	Faaiq_Waqar_and_Jordan_Brown_lab8_Rx_sourcecode.asm
;*
;*	This is the USART reciever
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
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
.def	o2lcnt = r24
.def	i2lcnt = r23
.def	ilcnt = r22
.def	olcnt = r21
.def	waitcnt = r20
.def	dpr = r19				; DeadBot-Purpose Register
.def	cpr = r18				; Comparison-Purpose Register
.def	spr = r17				; Secondary-Purpose Register
.def	mpr = r16				; Multi-Purpose Register

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit
.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	BotAddress = $2F;(Enter your robot's address here (8 bits))

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  (1<<EngDirR|1<<EngDirL)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR =   (1<<EngDirL)				;0b01000000 Turn Right Action Code
.equ	TurnL =   (1<<EngDirR)				;0b00100000 Turn Left Action Code
.equ	Halt =    (1<<EngEnR|1<<EngEnL)		;0b10010000 Halt Action Code
.equ	Freeze =  0b01010101

.equ	MovFwdCmd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBckCmd =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnRCmd =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnLCmd =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	HaltCmd =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	FreezeCmd =  0b11111000

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rcall 	INIT			; Reset interrupt
.org	$0002					
		rcall	BUMP_RIGHT
		reti
.org	$0004
		rcall	BUMP_LEFT
		reti
.org	$003C
		rcall	USART_FUNC
		reti

;Should have Interrupt vectors for:
;- Left whisker
;- Right whisker
;- USART receive

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
	ldi		mpr, high(RAMEND)
	out		SPH, mpr
	ldi		mpr, low(RAMEND)
	out		SPL, mpr
	;I/O Ports
	ldi		mpr, $FF
	out		DDRB, mpr
	ldi		mpr, $00
	out		PORTB, mpr

	ldi		mpr, (0<<0|0<<1|0<<2|0<<3|1<<4|0<<5|0<<6|0<<7)
	out		DDRD, mpr
	ldi		mpr, (1<<0|1<<1)
	out		PORTD, mpr
	;USART1
	ldi		mpr, high(832) ; Do We Round up or Down?
	sts		UBRR1H, mpr
	ldi		mpr, low(832) ; Same Question applies here
	sts		UBRR1L, mpr
		;Enable transmitter
	ldi		mpr, (1<<U2X1)
	sts		UCSR1A, mpr
	ldi		mpr, (1<<RXEN1|0<<TXEN1|1<<RXCIE1)
	sts		UCSR1B, mpr
	ldi		mpr, (0<<UPM11|1<<USBS1|1<<UCSZ11|1<<UCSZ10)
	sts		UCSR1C, mpr
	;External Interrupts
	ldi		mpr, (1<<ISC01|0<<ISC00|1<<ISC11|0<<ISC20||1<<ISC21)
	sts		EICRA, mpr
	ldi		mpr, (1<<INT0|1<<INT1)
	out		EIMSK, mpr
		;Set the External Interrupt Mask
		;Set the Interrupt Sense Control to falling edge detection

	;Other
	;Set Timer Ready for Wait Usage

	ldi		cpr, MovFwd
	ldi		dpr, MovBck
	ldi		waitcnt, 100

sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;TODO: ???
	out		PORTB, cpr
	rjmp	MAIN

DEAD_MAIN:
	ldi		cpr, Halt
	out		PORTB, cpr
	rjmp	DEAD_MAIN

KILL_SWITCH:
	ldi		mpr, (0<<TXC1|0<<U2X1|0<<MPCM1) ; Set Everything to 0
	sts		UCSR1A, mpr						; Send to control reg A
	ldi		mpr, (0<<RXEN1|0<<TXEN1|0<<RXCIE1|0<<UCSZ11)	; Continue to do this for the rest
	sts		UCSR1B, mpr
	ldi		mpr, (0<<UMSEL1|0<<UPM11|0<<UPM10|0<<USBS1|0<<UCSZ11|0<<UCSZ10|0<<UCPOL1)
	;External Interrupts
	ldi		mpr, (0<<ISC01|0<<ISC00|0<<ISC11|0<<ISC10)
	sts		EICRA, mpr
	ldi		mpr, (0<<INT0|0<<INT1)
	out		EIMSK, mpr						;
	rjmp DEAD_MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
BUMP_RIGHT:
		push	mpr			; Save mpr register
		in		mpr, SREG	; Save program state
		push	mpr			;

		ldi		mpr, (0<<TXEN1|0<<UCSZ12)
		sts		UCSR1B, mpr

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi		mpr, (1<<RXEN1|0<<TXEN1|1<<RXCIE1)
		sts		UCSR1B, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		mpr		; Restore mpr
		
		ldi		mpr,$FF
		out		EIFR, mpr
		
		ret				; Return from subroutine

BUMP_LEFT:
		push	mpr			; Save mpr register
		in		mpr, SREG	; Save program state
		push	mpr			;

		ldi		mpr, (0<<TXEN1|0<<UCSZ12)
		sts		UCSR1B, mpr

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		rcall	Wait			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi		mpr, (1<<RXEN1|0<<TXEN1|1<<RXCIE1)
		sts		UCSR1B, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		mpr		; Restore mpr

		ldi		mpr,$FF
		out		EIFR, mpr

		ret				; Return from subroutine

Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt			; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret	

USART_FUNC:
		lds		mpr, UDR1		; Load Contents from Reciever
		cpi		mpr, Freeze		; Compare to the freeze
		breq	FROZEN			; Freeze the robot
		cpi		mpr, $2F		; Compare to robot address
		breq	USART_CONT		; If equivalent, check for the command
		brne	RETURN_U_BAD	; Finih program if wrong address

USART_CONT:
		lds		mpr, UDR1		; Load new contents
		cpi		mpr, MovFwdCmd	; Check for MovFwd Command
		breq	COM_FWD		
		cpi		mpr, MovBckCmd	; Check for MovBck Command
		breq	COM_BCK
		cpi		mpr, TurnRCmd	; Check for TurnR Command
		breq	COM_RGT
		cpi		mpr, TurnLCmd	; Check for TurnL Command
		breq	COM_LFT
		cpi		mpr, HaltCmd	; Check for Halt Command
		breq	COM_HLT 
		cpi		mpr, FreezeCmd	; Check for Freeze Command
		breq	COM_FRZ 

RETURN_U_BAD:
		ldi		mpr,$FF			; Make sure to eliminate Queued interupts
		out		EIFR, mpr		; Clear by setting to the flag register
		ret

COM_FWD:
		ldi		cpr, MovFwd		; Load Forward Instruction to cpr
		rjmp	RETURN_U_BAD
COM_BCK:
		ldi		cpr, MovBck		; Load Backwards Instruction to cpr
		rjmp	RETURN_U_BAD
COM_RGT:
		ldi		cpr, TurnR		; Load Turn Right to cpr
		rjmp	RETURN_U_BAD
COM_LFT:
		ldi		cpr, TurnL		; Load Turn Left to cpr
		rjmp	RETURN_U_BAD
COM_HLT:
		ldi		cpr, Halt		; Load Halt to cpr
		rjmp	RETURN_U_BAD
COM_FRZ:
		ldi		mpr, (1<<TXEN1|0<<UCSZ12|0<<RXEN1|0<<RXCIE1) ; Disable recieve
		sts		UCSR1B, mpr									; Use UCSR1B to make Tx

		lds		spr, UCSR1A		; Wait until the bit is free
		sbrs	spr, UDRE1
		rjmp	COM_FRZ
		ldi		mpr, Freeze		; Send over to the Data Reg
		sts		UDR1, mpr
		rcall	Wait			; Wait so we dont freeze ourself

		ldi		mpr, (1<<RXEN1|0<<TXEN1|1<<RXCIE1)	; Set back to normal
		sts		UCSR1B, mpr							; Place in UCSR1B

		rjmp	RETURN_U_BAD	; Return
		 
FROZEN:
		ldi		mpr, (0<<INT0|0<<INT1)	; Disable Bumpbot
		out		EIMSK, mpr
	
		inc		dpr						; Increment number of fatalities
		cpi		dpr, 3
		breq	DEAD_JUMP				; Go finish bot if 3 freezes
		ldi		mpr, Halt				; Use halt
		out		PORTB, mpr				; Place to PORTB
		rcall	WAIT_5					; Wait for 5 sec
	
		ldi		mpr, (1<<INT0|1<<INT1)	; Renable Bumpbot
		out		EIMSK, mpr

		rjmp	RETURN_U_BAD

DEAD_JUMP:
		rjmp	KILL_SWITCH		; Go to the end of robot life

Wait_5:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

		ldi		i2lcnt, 2
		ldi		olcnt, 150		; load olcnt register
		ldi		ilcnt, 216		; load ilcnt register
		ldi		o2lcnt, 9
Loop_5:	
		dec		o2lcnt			; decrement ilcnt
		brne	Loop_5			; Continue Inner Loop
		dec		ilcnt			; decrement ilcnt
		brne	Loop_5			; Continue Inner Loop
		dec		olcnt			; decrement olcnt
		brne	Loop_5			; Continue Outer Loop
		dec		i2lcnt			; Decrement wait 
		brne	Loop_5			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret	
;***********************************************************
;*	Stored Program Data
;***********************************************************

;***********************************************************
;*	Additional Program Includes
;***********************************************************
