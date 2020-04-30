; AUTHORS: VITOR ACOSTA DA ROSA
;		 : ANDY SILVA BARBOSA

ORG 0000h ;RESET
LJMP CONFIG ;PULA PARA A ROTINA CONFIG

;-------------------INTERRUP��O EXTERNA 0---------------------------
ORG 0003h
; Rotina INT_EXT0:
; Atrav�s da interrup��o externa 0, ativada pelo P3.2 o usu�rio poder�
; come�ar o jogo. Se pressionar novamente, o jogo pausa.
INT_EXT0:
	AJMP START_GAME
	RETI

;-------------------INTERRUP��O DO TEMPORIZADOR 0-------------------
ORG 000Bh
INT_TEMP0:	
	MOV TH0, #0 ;Move para o valor de recarga do contador o valor 0.
	MOV TL0, #0 ;Move para o contador o valor 0.
	RETI

;-------------------INTERRUP��O EXTERNA 1---------------------------
ORG 0013h 
; Rotina INT_EXT1:
; Atrav�s da interrup��o externa 1, ativada pelo P3.3 o usu�rio poder�
; resetar o jogo. (Por enquanto, a fun��o n�o est� dispon�vel)
INT_EXT1:
	RETI



;----------------- C�DIGO PRINCIPAL --------------------------------
ORG 0080h

;----------------- FUN��ES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar n�meros aleat�rios primeiramente � movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o m�dulo, � feita a divis�o por 6 o resto(B) � considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representar� a quantidade de vezes que a sequ�ncia de 8bits (inicial 01111111) passar� na rota��o.
RANDOM:
	MOV A, TL0
	MOV B, R7
	DIV AB
	MOV A,B

	MOV B, #6h
	DIV AB

	MOV A, #01111111b
	MOV R0,B
	
	CJNE R0,#0h,ROTATE
	RET

; ROTINA ROTATE
; Rotaciona a sequ�ncia de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE

; ROTINA ACENDE_LED
; Ap�s rotacionar a sequ�ncia de 8 bits, acende o LED onde o bit tem n�vel l�gico 0.
ACENDE_LED:
	MOV P1, A
	RET

; ROTINA DELAY_EASY
; Gera um delay de 200ms (Dado que DJNZ consome 2us por execu��o, temos 2us * 100 = 200 ms)
DELAY_EASY:
	DJNZ R6, DELAY_EASY
	RET


;-------------------------- CONFIGURA��ES DO JOGO ----------------------------------------
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
	MOV R6, #50
	JB P3.2, START_GAME
	CALL RANDOM
	DJNZ R7, START_GAME
