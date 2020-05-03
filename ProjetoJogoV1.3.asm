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

;----------------- DELAYS DO JOGO ----------------------------------
; ROTINA DELAY_EASY
; Gera um delay de 200ms (Dado que DJNZ consome 2us por execu��o, temos 2us * 100 = 200 ms)
DELAY_EASY:
	DJNZ R6, DELAY_EASY
	RET

; ROTINA DELAY_ARMAZENAMENTO
; Gera um delay de 200ms entre cada inser��o do usu�rio
; (Dado que DJNZ consome 2us por execu��o, temos 2us * 100 = 200 ms)
DELAY_ARMAZENAMENTO:
	DJNZ R6, DELAY_ARMAZENAMENTO
	MOV R6,#32
	RET


;----------------- FUN��ES AUXILIARES DO JOGO ----------------------

; ROTINA ROTATE
; Rotaciona a sequ�ncia de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE
	MOV P1, A
	LJMP START_GAME

; ROTINA SALVA_SEQ
; Rotina que percorre a mem�ria na qual R1 aponta e salva o c�digo
; bin�rio do acendimento dos LEDS nessa posi��o (em HEX)
SALVA_SEQ:
	MOV @R1, P1
	INC R1
	LJMP START_GAME

;ROTINA SALVA_USR
; Rotina que percorre a mem�ria na qual R0 aponta e salva o c�digo
; bin�rio inserido pelo usu�rio nos bot�es SW2 at� SW7 (em HEX)
SALVA_USR:
	MOV @R0, P2
	INC R0
	LJMP START_GAME

;------------------------------------------------------------------

;----------------- FUN��ES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar n�meros aleat�rios primeiramente � movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o m�dulo, � feita a divis�o por 6 o resto(B) � considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representar� a quantidade de vezes que a sequ�ncia de 8bits (inicial 01111111) passar� na rota��o.
RANDOM:
	MOV A, TL0
	MOV B, #6h
	DIV AB

	MOV A, #01111111b
	MOV R2,B
	
	CJNE R2,#0h,ROTATE
	RET


; ROTINA SALVA_RANDOM
; Para cada led aceso da sequ�ncia, � salvo os 8bits de P1 em uma posi��o de mem�ria.
SALVA_RANDOM:
	CJNE R1, #82, SALVA_SEQ ;Caso a sequ�ncia n�o est� completa, pula para uma rotina auxiliar.
	MOV @R1, P1
	CPL P0.0 ;Define uma FLAG, indicando que a sequ�ncia foi salva em sua totalidade,
			 ;e permitindo que o usu�rio digite a sua sequ�ncia.
	RET


; ROTINA ARMAZENA_USER
; Rotina que verifica e salva a sequ�ncia de bot�es apertados pelo usu�rio.
ARMAZENA_USER:
	MOV P1, P2 ;Mostra qual o bot�o o usu�rio apertou
	;CALL DELAY_ARMAZENAMENTO ;Delay para visualiza��o do LED pressionado
	MOV P1, #11111111b ;Apaga os LEDS

	CJNE R0, #98, SALVA_USR ;Verifica se a sequ�ncia foi escrita em sua totalidade.
	MOV @R0, P2

	CPL P0.0 ;Flag que autoriza a continua��o do c�digo, j� que o usu�rio inseriu
			 ;sua sequ�ncia.

	CPL P0.1 ;Flag que permite a compara��o entre a sequ�ncia gerada pelo microcontrolador
			 ;com a sequencia inserida pelo usu�rio.

	LJMP START_GAME

; ROTINA LOOP_INSERT
; Espera que o usu�rio pressione pelo menos um bot�o entre SW2 e SW7, para
; comparar com a sequ�ncia do jogo.
LOOP_INSERT:
	JNB P2.7, ARMAZENA_USER
	JNB P2.6, ARMAZENA_USER
	JNB P2.5, ARMAZENA_USER
	JNB P2.4, ARMAZENA_USER
	JNB P2.3, ARMAZENA_USER
	JNB P2.2, ARMAZENA_USER
	SJMP LOOP_INSERT

; ROTINA COMPARA_JOGO
; Rotina respons�vel por comparar a sequ�ncia gerada aleat�riamente com
; a sequ�ncia inserida pelo usu�rio, a fim de mostrar a vit�ria ou a derrota.
COMPARA_JOGO:
	SJMP $


;-------------------------- CONFIGURA��ES DO JOGO ----------------------------------------
CONFIG:
	MOV R7, #255

	;--------------- APONTAMENTOS INICIAIS -----------
	;Apontamento inicial para a posi��o de mem�ria onde ficar� salvo as sequencias de LEDS
	MOV R1, #80 
	MOV R0, #96 
	;-------------------------------------------------

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

; ROTINA PRE_GAME
; Assegura que o usu�rio aperte o bot�o para que o jogo comece
PRE_GAME:
	MOV R6, #32
	JB P3.2, PRE_GAME

START_GAME:
	JNB P0.0, LOOP_INSERT
	JNB P0.1, COMPARA_JOGO
	CALL RANDOM
	CALL SALVA_RANDOM
	DJNZ R7, START_GAME
