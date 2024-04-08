;for TM1638
; DIO - 9 pin PORTB1 ATMega328P
; CLK - 8 pin PORTB0 ATMega328P
; STB - 10 pin PORTB2 ATMega328P
.include "m328pdef.inc"
.include "macro.inc"
	.equ XTAL=16000000 
	.equ fck=XTAL/1000
	.equ c1us= (1*fck)/4000 - 1

	.def ADRESS = r22
	.def DATA = r23
	.def COUNT = r24
	.def COUNT_SEG = r21

	;Reset Vector
	.org 0x0000
		rjmp main
	.cseg
	.org 0x0100
	led: .db 0x3F,0x6,0x5B,0x4F,0x66,0x6D,0x7D,0x7,0x7F,0x6F,0x00
	Delay1us:
		ldi R25,HIGH(c1us)
		ldi R24,LOW(c1us)
		rjmp Delayloop
	Delayloop:
		sbiw R24,1
		brne Delayloop
		ret

	send_data:
				push COUNT
				push r16
				ldi r16,0x04        ;команда
				rcall send_command
				rcall Delay1us
		
				push r17
                cbi PORTB,PORTB2	;подача 0V - низкий уровень на STB
				ori ADRESS,0xC0
            	mov r16,ADRESS
			    rcall t_send
				mov r16,DATA
				rcall t_send
			    sbi PORTB,PORTB2	;подача 5V - высокий уровень на STB
				pop r17
				pop r16
				pop COUNT
				ret
    t_send:
			push r16
			push r17
			push r18
			push r19
			push r20

			ldi r17,1	;для маски побитовый сдвиг 1 т.е.(0000 0001 
						; -> 0000 0010 -> 000 0100...) завершаем как будетт равно 0
			end_send:		
			mov r18,r16
			and r18,r17	;логическое и
			cpi r18,0x0 ;сравнение 
			breq yes
			;единица
			rcall Delay1us
			ldi r20,(0<<PORTB0)|(1<<PORTB1)
			out PORTB, r20
			rjmp end
			yes: ;ноль - LOW
			rcall Delay1us
			ldi r20,(0<<PORTB0)|(0<<PORTB1)
			out PORTB, r20
			end:
			lsl r17	;сдвиг влево
			rcall Delay1us
			sbi PORTB,PORTB0
			cpi r17,0x0	;сравнение с 0
			brne end_send ;перейти если не равно 0

			pop r20
			pop r19
			pop r18
			pop r17
			pop r16
			
			ret

    send_command:           ;отправка комманд
				push r17
                cbi PORTB, PORTB2	;подача 0V - низкий уровень на STB
                rcall t_send
				sbi PORTB, PORTB2    ;подача 5V - высокий уровень на STB
				pop r17
				rcall Delay1us
                ret    
	clear_display:
				push 	COUNT
				ldi		COUNT,0xC0
				clear_loop:
				mov ADRESS,COUNT
				ldi DATA,0x00
				rcall send_data
				inc		COUNT
				cpi		COUNT,0xD6
				brne	clear_loop
				pop		COUNT
				ret
	;Main Program Start
	.org 0x200
	main:
		ldi r16,0            ;reset system status
		out SREG,r16         ;init stack pointer статусные регистр
		ldi r16,low(RAMEND)  ;0xff указатель начала стека
		out SPL,r16
		ldi r16,high(RAMEND) ;0x08
		out SPH,r16

		;инициализация порта
		ldi	r16,0b00000111	; загрузка конфигурации порта
		out	DDRB,r16		; три пина выход

		ldi r16,0b00000101    ;подача +5V
		out PORTB,r16       ;высокий уровень на CLK и STB

		rcall Delay1us
		
		; для записи данных в память дисплея в режиме
		; автоматического увеличения адреса на 1 (0x40)-
		; фиксированный 0x44
		;инициализация ТМ1638
		ldi r16,0x44        ;первая команда инициализация
		rcall send_command
		; яркость дисплея от 0x88 до 0x8F
		ldi r16,0x8F ;побитовое ИЛИ
	;	ori r16,0x20 ; яркость 2
		rcall send_command ;вторая команда
		rcall clear_display;очистка экрана и светодиодов
		
	start: 
		;реалиция секундамера
		ldi		COUNT,0xC0
		ldi		r16,0x2
		ldi		r17,0x00
		loop_adress_seg:
			;начало на массив цифр
			ldi ZH, High(led<<1)
    		ldi ZL, Low(led<<1)
			mov ADRESS,COUNT ;адрес сегмента
			loop_seg_data:
				ldi		DATA,0x00
				rcall	send_data
				lpm		DATA, Z+
				rcall	send_data
				cpi		DATA,0x00
			brne	loop_seg_data
		add		COUNT,r16
		cpi		COUNT,0xD6
		brne	loop_adress_seg
	rcall clear_display;очистка экрана и светодиодов
	rjmp start