; AUTHORS: VITOR ACOSTA DA ROSA
;		 : ANDY SILVA BARBOSA

ORG 0000h ;RESET
LJMP CONFIG ;PULA PARA A ROTINA CONFIG

;-------------------INTERRUP��O EXTERNA 0---------------------------
ORG 0003h
INT_EXT0:
	INC P1
	RETI

;-------------------INTERRUP��O DO TEMPORIZADOR 0-------------------
ORG 000Bh
INT_TEMP0:	
	MOV TH0, #0 ;Move para o valor de recarga do contador o valor 0.
	MOV TL0, #0 ;Move para o contador o valor 0.
	RETI

;-------------------INTERRUP��O EXTERNA 1---------------------------
ORG 0013h 
INT_EXT1:
	DEC P1
	RETI



;----------------- C�DIGO PRINCIPAL --------------------------------
ORG 0080h
RANDOM:
	MOV A, TL0
	MOV B, #6h
	DIV AB

	MOV A, #01111111b
	MOV R0,B
	CJNE R0,#0h,ROTATE
	RET

ROTATE:
	RR A ;Consegue mover o zero
	DJNZ B, ROTATE

FIM_ROTACAO:
	MOV P1, A
	RET

CONFIG:
	
	MOV R7, #255
	;----------------------- CONFIGURA��ES DAS INTERRUP��ES EXTERNAS ------------------------------
	SETB IT0 ;Define o tipo de interrup��o externa sendo
			 ;executada toda vez que ocorre uma borda de descida
			 ;no pino P3.2.
	SETB EX0 ;Habilita a interrup��o externa 0 do registrador
	SETB IT1 ;Define o tipo de interrup��o externa sendo
			 ;executada toda vez que ocorre uma borda de descida
			 ;no pino P3.3.
	SETB EX1 ;Habilita a interrup��o externa 1 do registrador    
    SETB EA ;Habilita as interrup��es
	;---------------------------------------------------------------------------------------------
	
	;------------------------ INTERRUP��ES DO TEMPORIZADOR ---------------------------------------
	MOV TMOD,#2 ;Modo 2 - Temporizador/Contador de 8 bits com recarga autom�tica.
	MOV TH0, #0 ;Move para o valor de recarga do contador o valor 0.
	MOV TL0, #0 ;Move para o contador o valor 0.
	SETB ET0 ;Habilita a interrup��o do contador 0.
	SETB TR0 ;LIGA O CONTADOR 0
	;---------------------------------------------------------------------------------------------

START_GAME:
	CALL RANDOM
	DJNZ R7, START_GAME
