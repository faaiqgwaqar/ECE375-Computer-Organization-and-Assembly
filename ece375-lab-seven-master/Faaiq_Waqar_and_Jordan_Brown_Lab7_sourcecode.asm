;***********************************************************
;*
;*	Faaiq_Waqar_and_Jordan_Brown_Lab7_sourcecode.asm
;*
;*	We use big timer
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Faaiq Waqar
;*	   Date: November 15th, 2019
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	str = r17

.equ	WskrR = 0				; Right Whisker Input Bit
.equ	WskrL = 1				; Left Whisker Input Bit

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00				; Move Backward Command
.equ	TurnR = (1<<EngDirL)			; Turn Right Command
.equ	TurnL = (1<<EngDirR)			; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command
.equ	Step = 17;

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000
		rjmp	INIT			; reset interrupt

		; place instructions in interrupt vectors here, if needed

.org	$0046					; end of interrupt vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi r16, high(RAMEND)	; Prepare lower stack addr
		out SPH, r16			; Store lower stack addr
		ldi r17, low(RAMEND)	; Prepare upper stack addr
		out SPL, r17			; Store upper stack addr
		; Initialize the equidistant speed levels

		; Configure I/O ports
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		ldi		mpr, (1<<4|1<<5|1<<6|1<<7)		; Set Port B Data Direction Register
		out		DDRD, mpr		; for output
		ldi		mpr, (1<<0|1<<1|1<<2|1<<3)		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; Configure External Interrupts, if needed

		; Configure 8-bit Timer/Counters
		ldi mpr, (1<<WGM01|1<<WGM00|1<<COM01|1<<CS00)
		out TCCR0, mpr

		ldi mpr, (1<<WGM21|1<<WGM20|1<<COM21|1<<CS20)
		out TCCR2, mpr
		; no prescaling

		ldi		r23, 0
		ldi		mpr, MovFwd		; Move the robot forward infiniely
		out		PORTB, mpr

		ldi		mpr, 0b00000100		; Set up wait timer
		out		TCCR1B, mpr
		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL)
		; Enable global interrupts (if any are used)
	
		; Configure the External Interrupt Mask

		; Enable Interrupts to be used in program
		sei


;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		in		r20, PIND	
		cpi		r20, 0b00000111		; Check for Button 0 Input
		breq	SPEED_MIN_CALL		; if pressed, branch to function minimum
		cpi		r20, 0b00001011		; Check for Button 1 Input
		breq	SPEED_MAX_CALL		; If pressed, branch to function ma
		cpi		r20, 0b00001110		; Check for Button 2 Input
		breq	SPEED_UP_CALL		; if pressed, branch to function pd0
		cpi		r20, 0b00001101		; Check for Button 3 Input
		breq	SPEED_DOWN_CALL		; If pressed, branch to function pd1
		rjmp	MAIN			; Create an infinite while loop to signify the 
		; poll Port D pushbuttons (if needed)
SPEED_MIN_CALL:
		ldi		r23, 0				; utilize thr counter we use and set to 0
		mov		mpr, r23			; copy the contents of the copy reg to mpr
		ori		mpr, 0b01100000		; Use or functionality to combine the two for port
		out		PORTB, mpr			; place the contentsin portb for leds
		rcall	SPEED_MIN
SPEED_MIN_WAIT:
		in		r20, PIND	
		cpi		r20, 0b00001111		; Check for button up Input, wait
		breq	JUMP_MAIN
		rjmp	SPEED_MIN_WAIT
SPEED_MAX_CALL:
		ldi		r23, 15				; utilize thr counter we use and set to 15
		mov		mpr, r23			; copy the contents of the copy reg to mpr
		ori		mpr, 0b01100000		; Use or functionality to combine the two for port
		out		PORTB, mpr			; place the contentsin portb for leds
		rcall	SPEED_MAX			; Jump to function to modify PWM
SPEED_MAX_WAIT:
		in		r20, PIND	
		cpi		r20, 0b00001111		; Check for button up Input, wait
		breq	JUMP_MAIN
		rjmp	SPEED_MAX_WAIT
SPEED_UP_CALL:
		nop
		rcall	WAIT_2
		ldi		mpr, 15				; load multipurpose resiter to max 15
		cp		mpr, r23			; Compare to check if counter is at a max
		breq	JUMP_MAIN			; branch off if the counter will overflow

		inc		r23					; Increment the counter
		mov		mpr, r23			; Copy the counter into mpr
		ori		mpr, 0b01100000		; Use the OR command function to combine
		out		PORTB, mpr			; output onto port B
		rcall	SPEED_DOWN			
SPEED_UP_WAIT:
		in		r20, PIND	
		cpi		r20, 0b00001111		; Check for button up Input, wait
		breq	JUMP_MAIN
		rjmp	SPEED_UP_WAIT
SPEED_DOWN_CALL:
		nop
		rcall	WAIT_2
		ldi		mpr, 0				; load multipurpose resiter to min 0
		cp		mpr, r23			; Compare to check if counter is at a min
		breq	JUMP_MAIN			; branch off if the counter will overflow

		dec		r23					; decrement the counter
		mov		mpr, r23			; Copy the counter into mpr
		ori		mpr, 0b01100000		; Use the OR command function to combine
		out		PORTB, mpr			; output onto port B
		rcall	SPEED_UP
SPEED_DOWN_WAIT:
		in		r20, PIND	
		cpi		r20, 0b00001111		; Check for Button 0 Input
		breq	JUMP_MAIN
		rjmp	SPEED_DOWN_WAIT
JUMP_MAIN:
		rjmp	MAIN	
								; if pressed, adjust speed
								; also, adjust speed indication

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	Template function header
; Desc:	Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
SPEED_DOWN:	; Begin a function with a label

		in		mpr, OCR0		; take the value currently stores in output compare red
		ldi		str, 17			; Load to prepare a timer counter increment
		add		mpr, str		; add to the loaded value

		out		OCR0, mpr		; Place for timer 0
		out		OCR2, mpr		; Place for timer 2


		ret


SPEED_UP:

		in		mpr, OCR0		; take the value currently stores in output compare red
		ldi		str, 17			; Load to prepare a timer counter increment
		sub		mpr, str		; subtract to the loaded value

		out		OCR0, mpr		; Place for timer 0
		out		OCR2, mpr		; Place for timer 2


		ret

SPEED_MIN:
		ldi		mpr, $00		; Loaded minimum value into mpr
		out		OCR0, mpr		; Output into Output compares
		out		OCR2, mpr


		ret

SPEED_MAX:
		ldi		mpr, $FF		; Loaded maximum value into mpr
		out		OCR0, mpr		; Output into Output compares
		out		OCR2, mpr
		

		ret

WAIT:
		push	r18			; Save wait register
		push	r19			; Save ilcnt register
		push	r20			; Save olcnt register

		ldi		r18, 200
Loop:	ldi		r20, 224		; load olcnt register
OLoop:	ldi		r19, 237		; load ilcnt register
ILoop:	dec		r19			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		r20		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		r18		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		r20		; Restore olcnt register
		pop		r19		; Restore ilcnt register
		pop		r18		; Restore wait register
		ret

WAIT_2:
		ldi		mpr, high(52000)	; Load equation value 	
		out		TCNT1H, mpr
		ldi		mpr, low(52000)		; to set time for wait
		out		TCNT1L, mpr
LOOPY:
		in		mpr, TIFR			; Check TOV1 for overflow
		sbrs	mpr, TOV1
		rjmp	LOOPY
		ldi		mpr, 0b00000100		; restore flags
		out		TIFR, mpr
		ret

;***********************************************************
;*	Stored Program Data
;***********************************************************
		; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
		; There are no additional file includes for this program