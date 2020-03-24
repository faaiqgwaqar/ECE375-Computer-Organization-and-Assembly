;***********************************************************
;*
;*	Faaiq_Waqar_and_Jordan_Brown_Lab6_sourcecode.asm
;*
;*	Work with external interupts to create TekBot Movement,
;*  According to correlated whisker hits as interrupts
;*
;*	This is the skeleton file for Lab 6 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Faaiq Waqar & Jordan Brown
;*	   Date: November 15th 2019
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rghtcntr = r23
.def	leftcntr = r24
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter
.def	type = r20				; LCD data type: Command or Text
.def	q = r21					; Quotient for div10
.def	r = r22					; Remander for div10

.equ	WTime = 100				; Time to wait in wait loop

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



;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org	$0002
		rcall HitRight			; Use interrupt 0 in data space to call
		reti					; Hitright
.org	$0004
		rcall HitLeft			; Use interrupt 1 in data space to call
		reti					; HitLeft
.org	$0006
		rcall CLEARRIGHT		; Use interrupt 2 in data space to call
		reti					; ClearRight
.org	$0008
		rcall CLEARLEFT			; Use interrupt 3 in data space to call
		reti					; Clearleft
		; This is just an example:
;.org	$002E					; Analog Comparator IV
;		rcall	HandleAC		; Call function to handle interrupt
;		reti					; Return from interrupt

.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi r16, low(RAMEND)	; Prepare lower stack addr
		out SPL, r16			; Store lower stack addr
		ldi r17, high(RAMEND)	; Prepare upper stack addr
		out SPH, r17			; Store upper stack addr
		; Initialize LCD Display
		rcall	LCDInit
		rcall	CLEARRIGHT
		rcall	CLEARLEFT
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; Initialize external interrupts
			; Set the Interrupt Sense Control to falling edge 
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC21)|(0<<ISC20)|(1<<ISC31)|(0<<ISC30)
		sts		EICRA, mpr
		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT2)|(1<<INT3)
		out		EIMSK, mpr
		; Turn on interrupts
			; NOTE: This must be the last thing to do in the INIT function
			sei
;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program

		; TODO: ???
		ldi		mpr, MovFwd		; Move the robot forward infiniely
		out		PORTB, mpr		; Output to the display port
		rjmp	MAIN			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the 
;	left whisker interrupt, one to handle the right whisker 
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the 
;		beginning of your functions
;-----------------------------------------------------------
HITRIGHT:							; Begin a function with a label
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		inc		rghtcntr
		rcall	WRITERIGHT
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	WAITSEC			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	WAITSEC			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi		mpr, $FF
		out		EIFR, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine
		; Save variable by pushing them to the stack

HITLEFT:							; Begin a function with a label
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;

		; Move Backwards for a second
		inc		leftcntr
		rcall	WRITELEFT
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	WAITSEC			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	WAITSEC			; Call wait function

		; Move Forward again	
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port

		ldi		mpr, $FF
		out		EIFR, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine

		; Save variable by pushing them to the stack

		; Execute the function here
		
		; Restore variable by popping them from the stack in reverse order

WAITSEC:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait 
		brne	Loop			; Continue Wait loop	

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

WRITERIGHT:
		push	mpr				; Save MPR state

		ldi		YL, low($0100)	; Load LCD Read Location
		ldi		YH, high($0100)	; In data mem to Y
		ld		mpr, Y			; Load value form Y into MPR
		inc		mpr				; Increment MPR
		st		Y, mpr			; Store MPR in data mem at Y
		rcall	LCDWrLn1		; Write to screen

		pop		mpr				; Restore the value in MPR
		ret

WRITELEFT:
		push	mpr				; Save the multi purpose reg

		ldi		YL, low($0110)	; Load address 0110 to Y
		ldi		YH, high($0110)
		ld		mpr, Y			; Save the data from the data loc
		inc		mpr				; Increment by One
		st		Y, mpr			; Store in data mem
		rcall	LCDWrLn2		; Display

		pop		mpr				; Restore Value in MPR
		ret

CLEARRIGHT:
		
		push	mpr
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				; Save program state to stak

		ldi		YL, low($0100)	; Load data mem location for lcdr
		ldi		YH, high($0100)
		ldi		mpr, $30		; Load MPR with ASCII 0
		st		Y, mpr			; Store into data memory
		rcall	LCDWrLn1		; Display

		ldi		mpr, $FF		; Terminate Queued Interrupts
		out		EIFR, mpr		; Output onto the flag reg for int

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr
		ret

CLEARLEFT:
		push	mpr
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				; Save program state to the stack

		ldi		YL, low($0110)	; Pair location in data mem to Y
		ldi		YH, high($0110)	
		ldi		mpr, $30		; Load with ASCII value 0
		st		Y, mpr			; store intodata location 
		rcall	LCDWrLn2		; Display

		ldi		mpr, $FF		; Eliminate Queues
		out		EIFR, mpr

		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr
		ret
;***********************************************************
;*	Stored Program Data
;***********************************************************

; Enter any stored data you might need here

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"

