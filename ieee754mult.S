		;		ARM Programming Assignment #3: 32 bit IEEE 754 single-precision multiplier
		;
		;		Write a 32-bit floating point multiplier. The numbers will be represented
		;		in the single-precision IEEE 754 floating-point standard. The result should
		;		also be in IEEE 754 binary32. Assume you only have normalized numbers, i.e.
		;		the exponent is never 0b00000000.
		;		Write the result in the provided "fill" word.
		
floats	DCD		0xa0bcff0d, 0x13c0adea
result	FILL		8
		
		
		ADR		R0, floats
		LDR		R11, [R0]		;oper1
		LDR		R12, [R0, #4]	;oper2
		
		;sign	checking
		CMP		R11, #0		;check if oper1 is neg
		MOV		R1, #0			;set this up
		BPL		positive		;skip adding 1 if pos
		ADD		R1, R1, #1		;add 1
		
positive	CMP		R12, #0			;check if oper2 is neg
		BPL		positive2		;skip adding 1 if pos
		ADD		R1, R1, #1			;add 1
		
		MOV		R2, #0			;0 out sign bit
positive2	SUBS		R1, R1, #1		;subtract 1 for neg counter
		
		BEQ		nonneg			;branch if not 0
		ADD		R2, R2, #1			;else is neg, add 1 to sign bit
		
nonneg	STR		R2, [sp, #4]	;k now the sign bit is stored here
		
		
		MOV		R3, #0x7F000000 ;preparing to get exponents
		ADD		R3, R3, #0x00800000	;too big for literal zzzz
		
		AND		R0, R11, R3	;get oper1s exponent
		AND		R1, R12, R3	; get oper2s exponent
		
		
		MOV		R0, R0, LSR #23	;shift over the expo1
		ADD		R10, R0, R1, LSR #23	;shift oevr expo2 and add expos
		;i		guess these arern't biased cos that doesn't
		;SUB		R0, R0, #127		;remove the second bias
		
		;k		now leave r10 alone cos its where the answers gonna live
		
		MOV		R3, #0x007F0000		;preparing to get mantissas
		ADD		R3, R3, #0x0000FF00	;too big zz
		ADD		R3, R3, #0x000000FF	;too big zz
		
		AND		R1, R11, R3	;get oper1 mantissa
		AND		R2, R12, R3	;get oper2 mantissa
		
		ADD		R0, R1, #0x00400000  ;add preceding 1. to oper1
		ADD		R1, R2, #0x00400000  ;add preceding 1. to oper2
		
		BL		mult32		;multiply these mantissas
		
tworeg	CMP		R2, #0  ;check if bits stil in msb reg
		BEQ		onereg
		
		ANDS		R4, R2, #1	;see if lsb in msb reg is 0/1
		MOV		R3, R3, LSR #1	;shift over lsb reg
		MOV		R2, R2, LSR #1
		BEQ		tworeg		;if 0 keep going nothing to do here
		
		ADD		R3, R3, #0x80000000	;if 1 shift it over to the lsb reg
		ADD		R10, R10, #1	;increment exponent
		B		tworeg				;keep going
		
		
		
onereg	MOVS		R4, R3, LSR #23
		BEQ		small
		MOVS		R4, R4, LSR #1
		
		BEQ		ovflcheck
		
		;otherwise	is positive need shift right
		ADD		R10, R10, #1 ;increment exponent
		MOV		R3, R3, LSR #1		;shift right
		B		onereg
		
small	SUB		R10, R10, #1	;decrement exponent
		MOV		R3, R3, LSL #1		;shift left
		B		onereg
		
		;check	for overflow
ovflcheck	CMP		R10, #-126
		BLT		overflow
		
		CMP		R10, #127
		BGT		overflow
		
		
		;combine	bits
		;first	remove the 1. bit from mantissa
		MOV		R0, #0x7F0000
		ADD		R0, R0, #0x00FF00
		ADD		R0, R0, #0x0000FF	;wow this is lame
		
		AND		R3, R3, R0		;remove 1.
		;R3		is the mantissa, [sp, #4] is my sign bit, and my exponent
		
		
		MOV		R10, R10, LSL #23 ;shift exponent where it belongs
		LDR		R1, 	[sp, #4]		;bring the sign bit back
		ADD		R1, R1, R3		;add mantissa and sign bit back together
		ADD		R1, R1, R10			;add those back to the exponent
		ADR		R3, result		;storing
		STR		R1, [R3]		;stored
		
		END
		
		
		
overflow	MOV		R0, #0
		ADR		R1, result
		STR		R0, [R1]
		END
		
		
		
		
		;		========================================
		;		mult32 subroutine: multiplies two 32bit numbers using the 16bit multiplier and booths algorithm
		;		INPUTS:
		;		R0: first 32bit multiplier
		;		R1: second 32bit multiplier
		;		OUTPUTS:
		;		R2: first half of product (MSB)
		;		R3: second half of product (LSB)
		;		CORRUPTS (dependencies):
		;		(R0, R1, R2, R3, R4), R5, R6, R7, R8, R9
		;		(not R10, R11, R12)
		;		========================================
mult32	STR		LR, [sp]			;save your escape from this subroutine!
		MOV		R5, R0, LSR #16	; Top half of R0
		MOV		R6, R1, LSR #16	; Top half of R1
		
		BIC		R7, R0, R5, LSL #16	; Bottom half of R0
		BIC		R8, R1, R6, LSL #16	; Bottom half of R1
		
		;		Put Bottom R0 (R7)* Bottom R1 (R8) into R9
		MOV		R0, R7
		MOV		R1, R8
		BL		mult
		MOV		R9, R2
		
		;		Put Bottom R0 (R7) * Top R1 (R6) into R10
		MOV		R0, R7
		MOV		R1, R6
		BL		mult
		MOV		R7, R2
		
		;		Put Top R0 (R5) * Bottom R1 (R8) into R11
		MOV		R0, R5
		MOV		R1, R8
		BL		mult
		MOV		R8, R2
		
		;		Put Top R0 (R5) * Top R1 (R6) into R12
		MOV		R0, R5
		MOV		R1, R6
		BL		mult
		MOV		R6, R2
		
		LDR		LR, [sp]			;retrieve your escape from this subroutine
		;		Add partials
		ADDS		R0, R8,R7
		
		ADDCS	R1, R6, #0x10000
		ADDS		R3, R9, R0, LSL #16 ;R3 not used til here
		MOV		R0, R0, LSR #16
		ADC		R2, R2, R0 ; , LSR #15
		
		;ADR		R8, result		; Load mem address of result into R11
		;ADR		R7, carry		; Load mem address of carry into R10
		
		;STR		R2, [R8], #4
		;STR		R3, [R8]
		
		BCC		stop
		;MOV		R4, #1
		;STR		R4, [R7]
		
stop		MOV		PC, LR ;END
		;		========================================
		;		mult subroutine: multiplies two 16bit numbers (R2 <- R0 * R1 )
		;		INPUTS:
		;		R0 : first 16bit multiplier
		;		R1 : second 16bit multiplier
		;		OUTPUTS:
		;		R2 : product (R0*R1)
		;		CORRUPTS:
		;		R0, R1, R2, R3, R4
		;		========================================
mult		MOV		R2, #0 			; (A) initialize to 0
		MOV		R3, #16			; (N) bit-counter, 16 for 16bit numbers (N)
		MOV		R4, #0			; Set carry-counter 0
		
checkQ	TST		R1, #0b1			; test if LSB in R1 is 1
		BEQ		skipadd			; Skip adding if LSB in R1 = 0
		
		ADDS		R2, R2, R0		; A = A + B
		BCC		skipadd			; skip tracking carry if no carry
		ADD		R4, R4, #1		; add 1 carry to R4
		
		
skipadd	MOV		R0, R0, LSL #1		; Shift B left
		MOV		R1, R1, LSR #1		; shift Q right
		
		SUBS		R3, R3, #1		; N = N - 1
		
		BNE		checkQ			; if N != 0, go back to check LSB of Q
		
		MOV		PC, LR
