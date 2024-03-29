.device atmega328p

	.def	mask 	= r16		; mask register
	.def	ledR 	= r17		; led register
	.def	oLoopR 	= r18		; outer loop register
	.def	iLoopRl = r24		; inner loop register low
	.def	iLoopRh = r25		; inner loop register high

	.equ	oVal 	= 71		; outer loop value
	.equ	iVal 	= 28168		; inner loop value
	.equ RAMEND = 0x8ff   ;End of user RAM
	.equ SREG = 0x3f      ;Status Register
	.equ SPL = 0x3d       ;Stack Pointer Low
	.equ SPH = 0x3e       ;Stack Pointer High
	.equ PORTB = 0x05     ;Port B
	.equ DDRB = 0x04      ;Data Direction Register Port B

	;Reset Vector
	.org 0x0000
		rjmp main

	;Main Program Start
	.org 0x003a
	main:
		ldi r16,0            ;reset system status
		out SREG,r16         ;init stack pointer
		ldi r16,low(RAMEND)  ;0xff
		out SPL,r16
		ldi r16,high(RAMEND) ;0x08
		out SPH,r16

	ldi	mask,00000100	; load 00000001 into mask register
	out	DDRB,mask		; set PINB0 to output
	clr	ledR			; clear led register

start:	eor	ledR,mask		; toggle PINB0 in led register
	out	PORTB,ledR		; write led register to PORTB

	ldi	oLoopR,oVal		; initialize outer loop count

oLoop:	ldi	iLoopRl,LOW(iVal)	; intialize inner loop count in inner
	ldi	iLoopRh,HIGH(iVal)	; loop high and low registers

iLoop:	sbiw	iLoopRl,1		; decrement inner loop registers
	brne	iLoop			; branch to iLoop if iLoop registers != 0

	dec	oLoopR			; decrement outer loop register
	brne	oLoop			; branch to oLoop if outer loop register != 0

	rjmp	start			; jump back to start