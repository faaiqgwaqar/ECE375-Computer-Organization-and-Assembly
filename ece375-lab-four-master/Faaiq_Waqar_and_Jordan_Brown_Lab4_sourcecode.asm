;***********************************************************
;*
;*  Faaiq_Waqar_and_Jordan_Brown_Sourcecode.asm
;*
;*	This program will display the contents of two
;*	Strings from PM and shift them into the LCD display,
;*	With manipulations done with button 0,1 & 7 Pushes
;*
;*	Source Code file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Faaiq Waqar and Jordan Brown
;*	   Date: Enter date
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is
								; required for LCD Driver

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

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
		rcall LCDInit			; Routine call LCD initialize
		; Move strings from Program Memory to Data Memory
		ldi YL, low($0100)		; Load immediate value of $0100
								; In memory to address reg Y (low)
		ldi YH, high($0100)		; Load immediate value of $0100
								; In memory to address reg Y (high)
		; Move the location of the string definition in PM to Z (low)
		ldi ZL, low(STRING_BEG<<1)
		; Move the location of the string definition in PM to Z (high)
		ldi ZH, high(STRING_BEG<<1)
		ldi r19, 0				; Initialize r19, used for reversal 
								; Indicator flag

;***********************************************************
;*	While Loop for String One Initialization
;***********************************************************
WHILE:
		lpm r16, Z+				; Load contents of first string
								; Char into the register, post-inc
		st Y+, r16				; Store contents of register into
								; Data memory, and post-inc
		; Compare the current location of the Z pointer to string-end
		cpi ZL, low(STRING_END<<1)
		breq NICE				; If at the end of string (highadd)
								; Go to the next check
		rjmp WHILE				; Loop of not EQ
NICE:
		; Check the conents of the higher bits of Z addr
		cpi ZH, high(STRING_END<<1)
		breq NEXT				; If EQ, branch to the next section
		rjmp WHILE				; Otherwise loop again
;***********************************************************
;*	String Two Initialization (Data Memory)
;***********************************************************
NEXT:
		ldi YL, low($0110)		; Start the process again, prepare
		ldi YH, high($0110)		; Register Y sections with addr $0110
		ldi ZL, low(STRING_BEGJ<<1) ; Once again, set up Z, this time
		ldi ZH, high(STRING_BEGJ<<1) ; With the Start of the next string
;***********************************************************
;*	While Loop for String Two Initialization
;***********************************************************
WHILEB:
		lpm r16, Z+				; Store contents of Z in r16, post-inc
		st Y+, r16				; Store contents of r16 in Y, post-inc
		; Compare Z-Low bits to check for end of address string
		cpi ZL, low(STRING_ENDJ<<1)
		breq NICEB				; If equivalent, branch to next portion
		rjmp WHILEB				; Loop if not equal
NICEB:
		; Check bits for high inputs on Z (eos)
		cpi ZH, high(STRING_ENDJ<<1)
		breq NEXTB				; If equivalent, end of string, end
		rjmp WHILEB				; Loop if not equivalent
NEXTB:
		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:	
		in r20, PIND			; Take input for Buttons, store in R20
		cpi r20, 0b11111110		; Check for Button 0 Input
		breq BUTTONPD0			; if pressed, branch to function pd0
		cpi r20, 0b11111101		; Check for Button 1 Input
		breq BUTTONPD1			; If pressed, branch to function pd1
		cpi r20, 0b10111111		; Check for Button 7 Input
		breq BUTTONPD7			; If pressed, branch to function pd7
		rjmp MAIN				; If nothing is pressed, continued loop
BUTTONPD0:
		cpi r19, 1				; Check if the swap register is set to rev
		breq PD0JMP				; If it is set to rev, send to rcallpd0
		rjmp PD0WRT				; Otherwise, jump to display
PD0JMP:
		rcall FUNC				; Call to reversal of bits function
PD0WRT:
		ldi r19, 0				; Make sure status of swap re is set forw
		rcall LCDWrLn1			; Print Line 1 to LCD
		rcall LCDWrLn2			; Print Line 2 to LCD
		rjmp MAIN				; Loop back to the main
BUTTONPD1:
		cpi r19, 0				; Check if the swap reg is set to forw
		breq PD1JMP				; if it is, prepare for func jump
		rjmp PD1WRT				; Otherwise, send to display portion
PD1JMP:
		rcall FUNC				; Call to swapping bits function
PD1WRT:
		ldi r19, 1				; Make sure status of swap reg is set to rev
		rcall LCDWrLn1			; Print Line 1 to LCD
		rcall LCDWrLn2			; print Line 2 to LCD
		rjmp MAIN				; Jump back to main loop
BUTTONPD7:
		rcall LCDClrLn1			; Clear the lines in LCD 1
		rcall LCDClrLn2			; Cleat the lines in LCD 2
		rjmp INIT				; Jump to INIT to have data ready for new call
		; The Main program
		; Display the strings on the LCD Display
		; jump back to main and create an infinite
								; while loop.  Generally, every main program is an
								; infinite while loop, never let the main program
								; just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variables by pushing them to the stack
		ldi YL, low($0100)		; Prepare the Y addr with high
		ldi YH, high($0100)		; And low bits for $0100
		ldi XL, low($0110)		; Prepare the X addr with high
		ldi XH, high($0110)		; And low bits for $0110
		ldi r21, 0				; Set counter to r21 for 0
		ldi r22, 1				; Set inc to r22 for 1
WHILEC:
		ld r17, Y				; Load R17 with Y memory
		ld r18, X				; Load R18 with X memory
		st Y+, r18				; Post-Inc and store X mem to Y
		st X+, r17				; Post-Inc and store Y mem to X
		add r21, r22			; Increment the counting reg
		cpi r21, 12				; Compare the counter to max
		breq ENDFUNC			; If equivalent, end of loop
		rjmp WHILEC				; If not, loop again
		; Execute the function here

		; Restore variables by popping them from the stack,
		; in reverse order
ENDFUNC:
		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:
.DB		"Faaiq Waqar "		; Declaring data in ProgMem
STRING_END:

STRING_BEGJ:				; Declaring String 2 in ProgMem
.DB		"Jordan Brown"
STRING_ENDJ:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
