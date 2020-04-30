; AUTHORS: VITOR ACOSTA DA ROSA
;		 : ANDY SILVA BARBOSA

ORG 0000h ;RESET
LJMP CONFIG ;PULA PARA A ROTINA CONFIG

;-------------------INTERRUPÇÃO EXTERNA 0---------------------------
ORG 0003h
; Rotina INT_EXT0:
; Através da interrupção externa 0, ativada pelo P3.2 o usuário poderá
; começar o jogo. Se pressionar novamente, o jogo pausa.
INT_EXT0:
	AJMP START_GAME
	RETI

;-------------------INTERRUPÇÃO DO TEMPORIZADOR 0-------------------
ORG 000Bh
INT_TEMP0:	
	MOV TH0, #0 ;Move para o valor de recarga do contador o valor 0.
	MOV TL0, #0 ;Move para o contador o valor 0.
	RETI

;-------------------INTERRUPÇÃO EXTERNA 1---------------------------
ORG 0013h 
; Rotina INT_EXT1:
; Através da interrupção externa 1, ativada pelo P3.3 o usuário poderá
; resetar o jogo. (Por enquanto, a função não está disponível)
INT_EXT1:
	RETI



;----------------- CÓDIGO PRINCIPAL --------------------------------
ORG 0080h

;----------------- FUNÇÕES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar números aleatórios primeiramente é movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o módulo, é feita a divisão por 6 o resto(B) é considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representará a quantidade de vezes que a sequência de 8bits (inicial 01111111) passará na rotação.
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
; Rotaciona a sequência de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE

; ROTINA ACENDE_LED
; Após rotacionar a sequência de 8 bits, acende o LED onde o bit tem nível lógico 0.
ACENDE_LED:
	MOV P1, A
	RET

; ROTINA DELAY_EASY
; Gera um delay de 200ms (Dado que DJNZ consome 2us por execução, temos 2us * 100 = 200 ms)
DELAY_EASY:
	DJNZ R6, DELAY_EASY
	RET


;-------------------------- CONFIGURAÇÕES DO JOGO ----------------------------------------
CONFIG:
	MOV R7, #255
	;----------------------- CONFIGURAÇÕES DAS INTERRUPÇÕES EXTERNAS ------------------------------
	SETB IT0 ;Define o tipo de interrupção externa sendo
			 ;executada toda vez que ocorre uma borda de descida
			 ;no pino P3.2.
	SETB EX0 ;Habilita a interrupção externa 0 do registrador
	SETB IT1 ;Define o tipo de interrupção externa sendo
			 ;executada toda vez que ocorre uma borda de descida
			 ;no pino P3.3.
	SETB EX1 ;Habilita a interrupção externa 1 do registrador    
    SETB EA ;Habilita as interrupções
	;---------------------------------------------------------------------------------------------
	
	;------------------------ INTERRUPÇÕES DO TEMPORIZADOR ---------------------------------------
	MOV TMOD,#2 ;Modo 2 - Temporizador/Contador de 8 bits com recarga automática.
	MOV TH0, #0 ;Move para o valor de recarga do contador o valor 0.
	MOV TL0, #0 ;Move para o contador o valor 0.
	SETB ET0 ;Habilita a interrupção do contador 0.
	SETB TR0 ;LIGA O CONTADOR 0
	;---------------------------------------------------------------------------------------------

START_GAME:
	MOV R6, #50
	JB P3.2, START_GAME
	CALL RANDOM
	DJNZ R7, START_GAME
