.MACRO LEDCHER
    ldi ADRESS,@0
	ldi DATA,@1
	rcall send_data
		
.ENDM