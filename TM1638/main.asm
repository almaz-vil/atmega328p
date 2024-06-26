;Дмитрий Поляков
;18.04.2024 года
;for TM1638
;DIO - 9 pin PORTB1 ATMega328P
;CLK - 8 pin PORTB0 ATMega328P
;STB - 10 pin PORTB2 ATMega328P
.include "m328pdef.inc"
.include "macro.inc"

	.EQU	BUTTON1			= 0b10000000
	.EQU	BUTTON2			= 0b01000000
	.EQU	BUTTON3			= 0b00100000
	.EQU	BUTTON4			= 0b00010000
	.EQU	BUTTON5			= 0b00001000
	.EQU	BUTTON6			= 0b00000100
	.EQU	BUTTON7			= 0b00000010
	.EQU	BUTTON8			= 0b00000001
	.equ XTAL=16000000 
	.equ fck=XTAL/1000
	.equ c1us= (1*fck)/4000 - 1
	.equ BAUND=9600
	.equ UBRR_value = (fck/(BAUND*8))-1    
	.equ	STB=PORTB2
	.def BUTTONS = r1
	.def PROPUSK = r2
	.def ADRESS = r22
	.def DATA = r23
	.def COUNT = r24
	.def COUNT_SEG = r21
	.def temp = r17
	.def esek = r18
	.def dsek = r19
	.def emin = r20
	.def dmin = r26
	.def ehas = r27
	.def dhas = r28
	.def DATA_T = r16
	
	;Reset Vector
	.org 0x0000
		rjmp main
	;Timer 1
	.org 0x001A
		rjmp Timer1
	.cseg
	.org 0x0100
	led: .db 0x3F,0x6,0x5B,0x4F,0x66,0x6D,0x7D,0x7,0x7F,0x6F
	Timer1:
		
		cli
		rcall poll_keypad
		mov	temp,BUTTONS
		;cpi temp,0
		;breq q_r_f
		cpi	temp,BUTTON1 ;кнопка №1 сброс минут 00 и секунд 00
		brne	q_r
		clr BUTTONS
		ldi	esek,0
		ldi dsek,0 
		ldi emin,0
		ldi dmin,0
		q_r:
		cpi	temp,BUTTON2	;кнопка №2 плюс 1 час
		brne	q_r_d
		clr BUTTONS
		inc ehas	;еденицы часов
		cpi ehas,10
		brne q_r_d
		ldi ehas,0
		inc dhas
		cpi dhas,2
		brne q_r_d
		cpi ehas,4
		brne q_r_d
		ldi ehas,0
		ldi dhas,0		
		q_r_d:
		cpi	temp,BUTTON3	;кнопка №3 сброс часов в 00
		brne	q_r_f4
		clr BUTTONS
		ldi ehas,0
		ldi dhas,0
		q_r_f4:
		cpi temp,BUTTON4	;кнопка №4 добавлнение минут
		brne	q_r_f5
		clr	BUTTONS
		inc emin
		cpi emin,10
		brne q_r_f5
		ldi emin,0
		inc dmin
		cpi dmin,6
		brne q_r_f5
		ldi dmin,0
		ldi emin,0
		q_r_f5:
		cpi	temp,BUTTON5	;кнопка №5 сброс сукунд в 00
		brne	q_r_f6
		clr BUTTONS
		ldi esek,0
		ldi dsek,0	
		q_r_f6:
		cpi	temp,BUTTON6	;кнопка №6 показ 18 12 86 на 5 сек
		brne	q_r_f
		clr BUTTONS	
		ldi DATA_T,0x7D
		DATASEG 0xCE
		ldi DATA_T,0x7F		
		DATASEG 0xCC
		ldi DATA_T,0x5B
		DATASEG 0xC8
		ldi DATA_T,0x6
		DATASEG 0xC6
		ldi DATA_T,0x7F
		DATASEG 0xC2
		ldi DATA_T,0x6		
		DATASEG 0xC0
		ldi temp, 0x5
		mov PROPUSK,temp		
		q_r_f:
		clr BUTTONS
		inc esek
		cpi esek,10
		brne tend
		ldi esek,0
		inc dsek
		cpi dsek,6
		brne tend
		ldi dsek,0
		inc emin
		cpi emin,10
		brne tend
		ldi emin,0
		inc dmin
		cpi dmin,6
		brne tend
		ldi dmin,0
		inc ehas
		rcall CPM_LCS
		cpi ehas,10
		brne tend
		ldi ehas,0
		inc dhas
		tend:
		ldi temp,0x00
		cp PROPUSK,temp
		brne end_prorusk
		breq propuskl
		propuskl:
		ldi ZH, High(led<<1)
    	ldi ZL, Low(led<<1)
		ldi temp,-1
		loop_seg_data_esek:
				lpm		DATA_T, Z+
				inc 	temp
				cp		temp, esek
				brne	seg_esek_ne
				DATASEG 0xCE
				seg_esek_ne:
				cp		temp, dsek
				brne	seg_dsek_ne
				DATASEG 0xCC
				seg_dsek_ne:
				cp		temp, emin
				brne	seg_emin_ne
				DATASEG 0xC8
				seg_emin_ne:
				cp		temp, dmin
				brne	seg_dmin_ne
				DATASEG 0xC6
				seg_dmin_ne:
				cp		temp, ehas
				brne	seg_ehas_ne
				DATASEG 0xC2
				seg_ehas_ne:
				cp		temp, dhas
				brne	seg_dhas_ne
				DATASEG 0xC0
				seg_dhas_ne:
				cpi		temp,0xA
				brne loop_seg_data_esek
				
		sei		
		reti
		end_prorusk:
		dec PROPUSK
		sei
		reti
	CPM_LCS:;если 24 часа то 00
		cpi dhas,2
		brne tend
		cpi ehas,4
		brne tend
		ldi ehas,0
		ldi dhas,0
		ret
	Despley_esek:
		ldi COUNT,0xC0
		rcall send_data
		ret
	Delay1us:
		ldi R25,HIGH(c1us)
		ldi R24,LOW(c1us)
		rjmp Delayloop
	Delayloop:
		sbiw R24,1
		brne Delayloop
		ret
	Delay1sec:
		push r21
		push r22
		push r23
		ldi	r21,100
		loop3:	ldi r22,100
		loop2:	ldi r23,100
		loop1:	nop
				nop
				nop
				nop
				nop
				dec	r23
				brne loop1
				dec	r22
				brne loop2
				dec r21
				brne loop3
		pop r23
		pop r22
		pop r21
		ret

	send_data:
				push COUNT
				push r16
				push r17
		        cbi PORTB,STB	;подача 0V - низкий уровень на STB
				ori ADRESS,0xC0
            	mov r16,ADRESS
			    rcall t_send
				mov r16,DATA
				rcall t_send
			    sbi PORTB,STB	;подача 5V - высокий уровень на STB
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
                cbi PORTB,STB	;подача 0V - низкий уровень на STB
                rcall t_send
				sbi PORTB,STB    ;подача 5V - высокий уровень на STB
				rcall Delay1us
				pop r17
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
	poll_keypad:	;состояние кнопок
				push	dsek
				push	esek ;AKKU2
				push	emin	;AKKU
				push	r16		;AKKU3
				cbi		PORTB, STB	;подача 0V - низкий уровень на STB
				ldi		r16,0x42
				rcall	t_send
				rcall	Delay1us
				rcall	Delay1us
				ldi		r16,(1<<PB2)|(1<<PB0)|(0<<PB1)
				out		DDRB,r16
				sbi		PORTB,PORTB1
				clr		emin	;AKKU
				ldi		r16,4	;AKKU3
			_A1:
				clr		esek	;AKKU2
				ldi		dsek,8
			_A4:
				cbi		PORTB,PORTB0
				rcall	Delay1us
				sbis	PINB,PB1
				rjmp	_A7
			_A8:
				sbr		esek,0b10000000
			_A9:
			_A7:
				cpi		dsek,1
				breq	_A11
				lsr		esek	;AKKU2
			_A13:
			_A11:
				sbi		PORTB,PORTB0
				rcall	Delay1us
				dec		dsek
				brne	_A4
				
				andi	esek,0b00010001
				mov		dsek,r16
				dec		dsek
			_A14:
				cpi		dsek,0
				brlo	_A16
				breq	_A16
				lsl		esek
				dec		dsek
				rjmp	_A14
			_A16:
				or		BUTTONS,esek
				dec		r16
				brne	_A1
				swap	BUTTONS	
				sbi		PORTB, STB	;подача 5V -STB
				ldi		r16,(1<<PB2)|(1<<PB0)|(1<<PB1)
				out		DDRB,r16
				
				pop		r16
				pop		emin
				pop		esek
				pop		dsek
				ret

	;Main Program Start
	.org 0x300
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
		ldi r16,0x88 ;побитовое ИЛИ
		rcall send_command ;вторая команда
		rcall clear_display;очистка экрана и светодиодов
		;счётчик реального времяни //T2
		 ;TCCR2A = 0x00; //обычный режим работы таймера
		 ;TCCR2B = 0x05; //предделитель на 128
		 ;TIMSK2 = 0x01; //прерывание по переполнению
		 ;ASSR = 0x20; //использование внешнего кварцевого резонатора 32кГц
		 ldi r16,0x00
		 sts TCCR1A,r16
		 ldi r16,0b00001100;0xE
		 sts TCCR1B,r16
		 ldi r16,0x02
		 sts TIMSK1,r16
		 ;62500 быстрее чем 1 секунда
		 ldi r16,High(62480);62500
		 sts OCR1AH,r16
		 ldi r16,Low(62480)
		 sts OCR1AL,r16
		 ldi r16,0x00
		 sts TIFR1,r16
		 
		ldi esek,0x00
		ldi dsek,0x00
		ldi emin,0
		ldi dmin,0
		ldi ehas,0
		ldi dhas,0
		clr PROPUSK
		sei
	start: 
	
	rjmp start