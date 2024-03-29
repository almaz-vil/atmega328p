.include "m328pdef.inc"
.equ BAUND=9600
.equ fCK=16000000 ;??????? ? ??????
.equ UBRR_value = (fCK/(BAUND*8))-1    

.cseg
.org 0x0000    
    rjmp start
    
out_str:    .db	"KAMCHATKA",0

out_not_str:    .db	"NOT",0

out_yes_str:    .db	"YES",0

init_USART: ldi	r16, high(UBRR_value)
	    sts UBRR0H, r16
	    ldi r16, low(UBRR_value)
	    sts UBRR0L, r16
	    
	    
	    ldi	r16, (1<<TXEN0)
	    sts UCSR0B, r16
	    ldi r16, (1<<USBS0)|(3<<UCSZ00)
	    sts UCSR0C, r16
	    
USART_send:
		lds	R19, UCSR0A 
		sbrs R19, UDRE0	    
	    rjmp USART_send
	    sts	UDR0, R16
	    ret
    ; Replace with your application code
.org 0x003a
start:
    ;;????????? ?????
    ldi	R16, low(RAMEND)
    out SPL, R16
    ldi R16, high(RAMEND)
    out SPH, R16
    ;;?????????? USART
    rcall init_USART
    ;;???????? ?????? ??????
    
    ldi R30, low(out_str)
    ldi R31, high(out_str)
    add R30, R30
    adc R31, R31
    
lab_c:
	lpm R16, Z+
	cpi R16, $00
	breq disp_end
	rcall USART_send
	rjmp lab_c
	
disp_end:   

		
	rjmp disp_end