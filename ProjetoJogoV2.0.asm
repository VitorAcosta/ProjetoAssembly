; AUTHORS: VITOR ACOSTA DA ROSA
;		 : ANDY SILVA BARBOSA

; Frequencia utilizada: 8
; R7 -> Marcador para o tempo de execu��o do jogo (Loop).
; R6 -> Marcador para DELAYS.
; R5 -> N�o usado.
; R4 -> N�o usado.
; R3 -> Delay para o LCD
; R2 -> Marcador para rotacionar os bits da sequ�ncia gerada pelo 8051.
; R1 -> Ponteiro para mem�ria, serve para salvar a sequ�ncia gerada pelo 8051.
; R0 -> Ponteiro para mem�ria, serve para salvar a sequ�ncia inserida pelo usu�rio.

ORG 0000h ;RESET

;----------------- CONFIGURA��O DO LCD -----------------------------
; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3    ;Reg Select ligado em P1.3
    EN      equ     P1.2    ;Enable ligado em P1.2

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
;----------------- FUN��ES AUXILIARES DO JOGO ----------------------
ESCREVE_LOSE:
	acall lcd_init
	mov A, #04h ;Posiciona o cursor
	ACALL posicionaCursor 
	MOV A, #'L'
	ACALL sendCharacter
	MOV A, #'O'
	ACALL sendCharacter
	MOV A, #'S'
	ACALL sendCharacter
	MOV A, #'E'
	ACALL sendCharacter
	MOV A, #'R'
	ACALL sendCharacter
	ACALL retornaCursor
	JNB P3.2, $
	LJMP PRE_GAME

ESCREVE_WIN:
	acall lcd_init
	mov A, #03h ;Posiciona o cursor
	ACALL posicionaCursor 
	MOV A, #'W'
	ACALL sendCharacter
	MOV A, #'I'
	ACALL sendCharacter
	MOV A, #'N'
	ACALL sendCharacter
	MOV A, #'N'
	ACALL sendCharacter
	MOV A, #'E'
	ACALL sendCharacter
	MOV A, #'R'
	ACALL sendCharacter
	ACALL retornaCursor
	JNB P3.2, $
	LJMP PRE_GAME


; ROTINA DELAY_ARMAZENAMENTO
; Gera um delay de 200ms entre cada inser��o do usu�rio
; (Dado que DJNZ consome 2us por execu��o, temos 2us * 100 = 200 ms)
DELAY_ARMAZENAMENTO:
	DJNZ R6, DELAY_ARMAZENAMENTO
	MOV R6,#60
	RET

; ROTINA ROTATE
; Rotaciona a sequ�ncia de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE
	MOV P1, A
	RET

; ROTINA SALVA_SEQ
; Rotina que percorre a mem�ria na qual R1 aponta e salva o c�digo
; bin�rio do acendimento dos LEDS nessa posi��o (em HEX)
SALVA_SEQ:
	MOV @R1, P1
	INC R1
	RET

;ROTINA SALVA_USR
; Rotina que percorre a mem�ria na qual R0 aponta e salva o c�digo
; bin�rio inserido pelo usu�rio nos bot�es SW2 at� SW7 (em HEX)
SALVA_USR:
	MOV @R0, P2
	INC R0
	CALL DELAY_ARMAZENAMENTO ;Delay para visualiza��o do LED pressionado
	MOV P1, #11111111b ;Apaga os LEDS
	LJMP START_GAME

GERA_SEED:
	MOV A, TL0
	MOV B, #17
	MUL AB
	RLC A
	ADD A, B
	MOV TL0, A
	RET

;------------------------------------------------------------------

;----------------- FUN��ES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar n�meros aleat�rios primeiramente � movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o m�dulo, � feita a divis�o por 6 o resto(B) � considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representar� a quantidade de vezes que a sequ�ncia de 8bits (inicial 01111111) passar� na rota��o.
RANDOM:
    CALL GERA_SEED
	MOV P1, #11111111b
	MOV A, TL0
	MOV B, #6h
	DIV AB

	MOV A, #01111111b
	MOV R2,B
	
	CJNE R2,#0h,ROTATE
	LJMP START_GAME


; ROTINA SALVA_RANDOM
; Para cada led aceso da sequ�ncia, � salvo os 8bits de P1 em uma posi��o de mem�ria.
SALVA_RANDOM:
	CJNE R1, #84, SALVA_SEQ ;Caso a sequ�ncia n�o est� completa, pula para uma rotina auxiliar.
	MOV @R1, P1
	CPL P0.0 ;Define uma FLAG, indicando que a sequ�ncia foi salva em sua totalidade,
			 ;e permitindo que o usu�rio digite a sua sequ�ncia.
	RET


; ROTINA ARMAZENA_USER
; Rotina que verifica e salva a sequ�ncia de bot�es apertados pelo usu�rio.
ARMAZENA_USER:
	MOV P1, P2 ;Mostra qual o bot�o o usu�rio apertou
	
	CJNE R0, #100, SALVA_USR
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
	MOV P1, #01111111b
	MOV P1, #11111111b
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
	MOV P1, #11111111b
	
	MOV A, 80
	CJNE A, 96, ERRO
	MOV A, 81
	CJNE A, 97, ERRO
	MOV A, 82
	CJNE A, 98, ERRO
	MOV A, 83
	CJNE A, 99, ERRO
	MOV A, 84
	CJNE A, 100, ERRO
	LJMP ESCREVE_WIN

ERRO:
	LJMP ESCREVE_LOSE

;-------------------------- CONFIGURA��ES DO JOGO ----------------------------------------
CONFIG:

	MOV R7, #255
	MOV R6, #60

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
	JB P3.2, PRE_GAME

START_GAME:
	JNB P0.0, LOOP_INSERT
	JNB P0.1, COMPARA_JOGO
	CALL RANDOM
	CALL SALVA_RANDOM
	DJNZ R7, START_GAME

; initialise the display
; see instruction set for details
lcd_init:

	CLR RS		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB EN		; |
	CLR EN		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB EN		; |
	CLR EN		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear


; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear


; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


sendCharacter:
	SETB RS  		; setb RS - indicates that data is being sent to module
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	RET

;Posiciona o cursor na linha e coluna desejada.
;Escreva no Acumulador o valor de endere�o da linha e coluna.
;|--------------------------------------------------------------------------------------|
;|linha 1 | 00 | 01 | 02 | 03 | 04 |05 | 06 | 07 | 08 | 09 |0A | 0B | 0C | 0D | 0E | 0F |
;|linha 2 | 40 | 41 | 42 | 43 | 44 |45 | 46 | 47 | 48 | 49 |4A | 4B | 4C | 4D | 4E | 4F |
;|--------------------------------------------------------------------------------------|
posicionaCursor:
	CLR RS	         ; clear RS - indicates that instruction is being sent to module
	SETB P1.7		    ; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	RET


;Retorna o cursor para primeira posi��o sem limpar o display
retornaCursor:
	CLR RS	      ; clear RS - indicates that instruction is being sent to module
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


;Limpa o display
clearDisplay:
	CLR RS	      ; clear RS - indicates that instruction is being sent to module
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


delay:
	MOV R3, #50
	DJNZ R3, $
	RET