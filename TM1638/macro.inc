.MACRO LEDCHER
    ldi ADRESS,@0
	ldi DATA,@1
	rcall send_data	
.ENDM

.MACRO DATASEG
	ldi		ADRESS,@0 
	ldi		DATA,0x00
	rcall	send_data	
	mov		DATA, DATA_T
	rcall	send_data
.ENDM
				