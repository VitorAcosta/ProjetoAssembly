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

;----------------- DELAYS DO JOGO ----------------------------------
; ROTINA DELAY_EASY
; Gera um delay de 200ms (Dado que DJNZ consome 2us por execução, temos 2us * 100 = 200 ms)
DELAY_EASY:
	DJNZ R6, DELAY_EASY
	RET

; ROTINA DELAY_ARMAZENAMENTO
; Gera um delay de 200ms entre cada inserção do usuário
; (Dado que DJNZ consome 2us por execução, temos 2us * 100 = 200 ms)
DELAY_ARMAZENAMENTO:
	DJNZ R6, DELAY_ARMAZENAMENTO
	MOV R6,#32
	RET


;----------------- FUNÇÕES AUXILIARES DO JOGO ----------------------

; ROTINA ROTATE
; Rotaciona a sequência de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE
	MOV P1, A
	LJMP START_GAME

; ROTINA SALVA_SEQ
; Rotina que percorre a memória na qual R1 aponta e salva o código
; binário do acendimento dos LEDS nessa posição (em HEX)
SALVA_SEQ:
	MOV @R1, P1
	INC R1
	LJMP START_GAME

;ROTINA SALVA_USR
; Rotina que percorre a memória na qual R0 aponta e salva o código
; binário inserido pelo usuário nos botões SW2 até SW7 (em HEX)
SALVA_USR:
	MOV @R0, P2
	INC R0
	LJMP START_GAME

;------------------------------------------------------------------

;----------------- FUNÇÕES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar números aleatórios primeiramente é movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o módulo, é feita a divisão por 6 o resto(B) é considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representará a quantidade de vezes que a sequência de 8bits (inicial 01111111) passará na rotação.
RANDOM:
	MOV A, TL0
	MOV B, #6h
	DIV AB

	MOV A, #01111111b
	MOV R2,B
	
	CJNE R2,#0h,ROTATE
	RET


; ROTINA SALVA_RANDOM
; Para cada led aceso da sequência, é salvo os 8bits de P1 em uma posição de memória.
SALVA_RANDOM:
	CJNE R1, #82, SALVA_SEQ ;Caso a sequência não está completa, pula para uma rotina auxiliar.
	MOV @R1, P1
	CPL P0.0 ;Define uma FLAG, indicando que a sequência foi salva em sua totalidade,
			 ;e permitindo que o usuário digite a sua sequência.
	RET


; ROTINA ARMAZENA_USER
; Rotina que verifica e salva a sequência de botões apertados pelo usuário.
ARMAZENA_USER:
	MOV P1, P2 ;Mostra qual o botão o usuário apertou
	;CALL DELAY_ARMAZENAMENTO ;Delay para visualização do LED pressionado
	MOV P1, #11111111b ;Apaga os LEDS

	CJNE R0, #98, SALVA_USR ;Verifica se a sequência foi escrita em sua totalidade.
	MOV @R0, P2

	CPL P0.0 ;Flag que autoriza a continuação do código, já que o usuário inseriu
			 ;sua sequência.

	CPL P0.1 ;Flag que permite a comparação entre a sequência gerada pelo microcontrolador
			 ;com a sequencia inserida pelo usuário.

	LJMP START_GAME

; ROTINA LOOP_INSERT
; Espera que o usuário pressione pelo menos um botão entre SW2 e SW7, para
; comparar com a sequência do jogo.
LOOP_INSERT:
	JNB P2.7, ARMAZENA_USER
	JNB P2.6, ARMAZENA_USER
	JNB P2.5, ARMAZENA_USER
	JNB P2.4, ARMAZENA_USER
	JNB P2.3, ARMAZENA_USER
	JNB P2.2, ARMAZENA_USER
	SJMP LOOP_INSERT

; ROTINA COMPARA_JOGO
; Rotina responsável por comparar a sequência gerada aleatóriamente com
; a sequência inserida pelo usuário, a fim de mostrar a vitória ou a derrota.
COMPARA_JOGO:
	SJMP $


;-------------------------- CONFIGURAÇÕES DO JOGO ----------------------------------------
CONFIG:
	MOV R7, #255

	;--------------- APONTAMENTOS INICIAIS -----------
	;Apontamento inicial para a posição de memória onde ficará salvo as sequencias de LEDS
	MOV R1, #80 
	MOV R0, #96 
	;-------------------------------------------------

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

; ROTINA PRE_GAME
; Assegura que o usuário aperte o botão para que o jogo comece
PRE_GAME:
	MOV R6, #32
	JB P3.2, PRE_GAME

START_GAME:
	JNB P0.0, LOOP_INSERT
	JNB P0.1, COMPARA_JOGO
	CALL RANDOM
	CALL SALVA_RANDOM
	DJNZ R7, START_GAME
