			;		ARM Programming Assignment #3: IEEE 754 to TNS bit-level marshaller
			;		Write a program to convert a 32-bit single-precision IEEE 754 floating-point
			;		number to the Tandem Non-stop Series (TNS) format. Refer to the README for a
			;		description of the format. Convert the numbers in `floats` and write the TNS
			;		equivalents into the `tns` area, one after the other.
			;		Bonus:
			;		1. (30 extra points) Implement the reverse conversion, from TNS to IEEE.
			;		2. (50 extra points) Organize the code into two subroutines, with stack
			;		support.
			;		3. (10 extra points) In the main program, implement a round-trip conversion
			;		and prove the results match the initial values in 'floats'.  Define a
			;		`FILL` region to hold the IEEE 754 results.
			;		Your code here
			
floats		DCD		0xf0bcff0d, 0x13c0adea
tns			FILL		16
ieee			FILL		16
eqls			FILL		16
			
			ADR		R11, floats
			
			LDR		R2, [R11], #4	;load floats1 into R2
			LDR		R3, [R11]		;load floats2 into R3

			;convert both to tns
			MOV		R12, R2		;copy floats1 for input into subroutine
			BL		ie2tns			;convert to tns
			MOV		R4, R1		;copy tns format into R4
			
			MOV		R12, R3		;copy floats2 for input into subroutine
			BL		ie2tns			;convert to tns
			MOV		R5, R1		;copy tns format into R4

			;store tns numbers
			ADR		R6, tns			;prepare to store tns numbers
			STR		R4, [R6], #4		;store first tns conversion
			STR		R5, [R6]			;store second tns conversion

			;convert back to ieee
			MOV		R12, R4		;move floats1.tns into input register
			BL		tns2ie			;convert floats1.tns back to
			MOV		R6, R1		;store floats1.reconversion
			
			MOV		R12, R5		;move floats2.tns into input register
			BL		tns2ie			;convert floats2.tns back to
			MOV		R7, R1		;store floats2.reconversion

			;store reconverted ieee
			ADR		R4, ieee			;prepare to store reconverted ieee numbers
			STR		R6, [R4], #4		;store first ieee reconversion
			STR		R7, [R4]			;store second ieee reconversion
			
			;test equality of reconverted and originals
			MOV		R10, R2		;original ieee into input1
			MOV		R11, R6		;reconversion input2
			ADR		R12, eqls		;storage addr input3
			BL		tsteqlty
			
			MOV		R10, R3		;second original ieee into input1
			MOV		R11, R7		;second reconversion input2
			ADD		R12, R12, #4		;increment addr
			BL		tsteqlty

			;done
			END
			
			
			;=========================
			;		tsteqlty
			;		Tests equality between conversions. Stores [ascii] 'e' (101) for equal, 'n' (110) for notequal, and 'r' (114) for rounding error, accordingly
			;
			;		INPUTS:
			;		R10 - original single-point precision floating point number
			;		R11 - converted tns and back to ieee single-point precision floating point number
			;		R12 - address to store in
			;		OUTPUTS: none
			;		CORRUPTS: R0
			;
			;		LIMITATIONS:
			;
			;=========================
			
tsteqlty		SUBS		R0, R10, R11		;substract the two ieee's
			BEQ		eql				;zero flag set, same number
			
			CMP		R0, #0b1			;check if its 1 bit off
			BEQ		rnderr			;if it is, rounding error from mantissa bit diff
			
			MOV		R0, #110			;crap not equal
			STR		R0, [R12]
			MOV		PC, LR
			
eql			MOV		R0,	#110			;nice was equal
			STR		R0, [R12]
			MOV		PC, LR
			
rnderr		MOV		R0, #114			;rounding error
			STR		R0, [R12]
			MOV		PC, LR
			
			
			;=========================
			;		tns2ie
			;		Converts a TNS single point float into IEEE format
			;
			;		INPUTS: R12 - TNS format single-point precision floating point number
			;		OUTPUTS: R1 - Converted IEEE single-point precision floating point number
			;		CORRUPTS: R0, R1
			;
			;		LIMITATIONS: If all 9 bits of TNS exponent are used, overflow occurs and program terminates
			;
			;=========================
			
			
			
tns2ie		;MOV R1, #0x00000000 ;clear out result register
			
			;doing	the exponent first to check for overflow first thing                                                                                                                                                    ./0
			
			MOV		R0, R12, LSL #23	;clear out sign bit & mantissa
			MOV		R0, R0, lSR #23		;move back
			
			MOV		R1, #0x000000FF	;need to compare to 0b000000000000000000000000 11111111
			CMP		R0, R1	;if larger, overflow
			
			BLE		nooverflow
			END
			
nooverflow	MOV		R1, R0, LSL #23		;put 8bit exponent into result register in IEEE location
			
			MOV		R0, R12, LSR #31	;take sign bit from TNS number
			MOV		R0, R0, LSL #31	;put back into IEEE location
			
			ADD		R1, R1, R0		;add sign bit to result register
			
			MOV		R0, R12, LSL #1	;clear sign bit and retrieve mantissa
			MOV		R0, R0, LSR #9	;move mantissa to IEEE location
			
			ADD		R1, R1, R0	;add mantissa bits to result register
			
			MOV		PC, LR
			
			
			
			
			
			
			;=========================
			;		ie2tns
			;		Converts a IEEE single point float into TNS format
			;
			;		INPUTS: R12 - IEEE single-point precision floating point number
			;		OUTPUTS: R1 - Converted TNS format single-point precision floating point number
			;		CORRUPTS: R0, R1
			;
			;		LIMITATIONS: Does not currently round mantissa, potential LOA from conversion of number requiring 23rd bit of mantissa.
			;
			;=========================
			
			
ie2tns		MOV		R1, #0x00000000	;clear out result register
			
			MOVS		R0, R12, LSR #31	;check if last bit is set
			BEQ		possignbit		;skip setting sign bit if original not set
			
			ADD		R1, R1, #0x80000000
			
possignbit	MOV		R0, R12, LSR #1	;clear out the last mantissa bit (tns is 1 bit smaller) (should i round this?)
			MOV		R0, R0, LSL #10 ; clear out expo and sign bit
			MOV		R0, R0, LSR #1 ; scoot over for sign bit
			
			ADD		R1, R1, R0		;combine tns mantissa and sign bit
			
			MOV		R0, R12, LSL #1	;clear sign bit
			MOV		R0, R0, LSR #24	;move exponent to end for tns format
			
			ADD		R1, R1, R0		;add in tns exponent bit
			
			MOV		PC, LR		;escape
