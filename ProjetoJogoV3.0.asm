; AUTHORS: VITOR ACOSTA DA ROSA
;		 : ANDY SILVA BARBOSA

; Frequencia utilizada: 8
; R7 -> Não usado.
; R6 -> Marcador para DELAYS.
; R5 -> Não usado.
; R4 -> Não usado.
; R3 -> Delay para o LCD
; R2 -> Marcador para rotacionar os bits da sequência gerada pelo 8051.
; R1 -> Ponteiro para memória, serve para salvar a sequência gerada pelo 8051.
; R0 -> Ponteiro para memória, serve para salvar a sequência inserida pelo usuário.

ORG 0000h ;RESET

;----------------- CONFIGURAÇÃO DO LCD -----------------------------
; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3    ;Reg Select ligado em P1.3
    EN      equ     P1.2    ;Enable ligado em P1.2

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


;----------------- CÓDIGO PRINCIPAL --------------------------------
ORG 0080h
;----------------- FUNÇÕES AUXILIARES DO JOGO ----------------------
ESCREVE_LOSE:
	acall lcd_init
	MOV A, #0
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
	MOV A, #'!'
	ACALL sendCharacter
	ACALL retornaCursor
	MOV P1, #11111111b
	
	;-------- RESET DO JOGO ---------
	CPL P0.1 ;Limpa a FLAG
	MOV R1, #80 ;Redefine o apontamento
	MOV R0, #96 ;Redefine o apontamento

	JNB P3.2, $ ;Enquanto o usuário não apertar SW0, o jogo não reinicia.
	LJMP PRE_GAME

ESCREVE_WIN:
	acall lcd_init
	MOV A, #0
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
	MOV P1, #11111111b

	;-------- RESET DO JOGO ---------
	CPL P0.1 ;Limpa a FLAG
	MOV R1, #80 ;Redefine o apontamento
	MOV R0, #96 ;Redefine o apontamento

	JNB P3.2, $ ;Enquanto o usuário não apertar SW0, o jogo não reinicia.
	LJMP PRE_GAME


; ROTINA DELAY_ARMAZENAMENTO
; Gera um delay de 192ms entre cada inserção do usuário
; (Dado que DJNZ consome 2us por execução, e que 0x60 = 96decimal temos 2us * 96 = 192 ms)
DELAY_ARMAZENAMENTO:
	DJNZ R6, DELAY_ARMAZENAMENTO
	MOV R6,#60
	RET

; ROTINA ROTATE
; Rotaciona a sequência de 8bits inserida no acumulador A, B vezes.
ROTATE:
	RR A 
	DJNZ B, ROTATE
	MOV P1, A
	RET

; ROTINA SALVA_SEQ
; Rotina que percorre a memória na qual R1 aponta e salva o código
; binário do acendimento dos LEDS nessa posição (em HEX)
SALVA_SEQ:
	MOV @R1, P1
	INC R1
	RET

;ROTINA SALVA_USR
; Rotina que percorre a memória na qual R0 aponta e salva o código
; binário inserido pelo usuário nos botões SW2 até SW7 (em HEX)
SALVA_USR:
	MOV @R0, P2
	INC R0
	CALL DELAY_ARMAZENAMENTO ;Delay para visualização do LED pressionado
	MOV P1, #11111111b ;Apaga os LEDS
	LJMP START_GAME

;ROTINA GERA_SEED
; Rotina que gera um número aleatório a partir do número disposto no Timer.
; Essa rotina, serve para manter a aleatoriedade entre os LEDS acendidos.
; Como o RANDOM trabalha com valores fixos, essa rotina serve para quebrar
; o ciclo.
GERA_SEED:
	MOV A, TL0
	MOV B, #17
	MUL AB
	RLC A ;Rotaciona os bits calculados para a esquerda
		  ;considerando o Carry.
	ADD A, B
	MOV TL0, A
	RET

;------------------------------------------------------------------

;----------------- FUNÇÕES DO JOGO ---------------------------------
; ROTINA RANDOM:
; Para gerar números aleatórios primeiramente é movido o valor do contador para o acumulador A
; em seguida, como deseja-se adquirir o módulo, é feita a divisão por 6 o resto(B) é considerado e
; o quociente(A) descartado. 
; Dessa forma, o resto representará a quantidade de vezes que a sequência de 8bits (inicial 01111111) passará na rotação.
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
; Para cada led aceso da sequência, é salvo os 8bits de P1 em uma posição de memória.
SALVA_RANDOM:
	CJNE R1, #84, SALVA_SEQ ;Caso a sequência não está completa, pula para uma rotina auxiliar.
	MOV @R1, P1
	CPL P0.0 ;Define uma FLAG, indicando que a sequência foi salva em sua totalidade,
			 ;e permitindo que o usuário digite a sua sequência.
	RET


; ROTINA ARMAZENA_USER
; Rotina que verifica e salva a sequência de botões apertados pelo usuário.
ARMAZENA_USER:
	MOV P1, P2 ;Mostra qual o botão o usuário apertou
	
	CJNE R0, #100, SALVA_USR
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
; Rotina responsável por comparar a sequência gerada aleatóriamente com
; a sequência inserida pelo usuário, a fim de mostrar a vitória ou a derrota.
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

;-------------------------- CONFIGURAÇÕES DO JOGO ----------------------------------------
CONFIG:
	MOV R6, #60

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
	JB P3.2, PRE_GAME

START_GAME:
	JNB P0.0, LOOP_INSERT
	JNB P0.1, COMPARA_JOGO
	CALL RANDOM
	CALL SALVA_RANDOM
	SJMP START_GAME

;--------------------------- ROTINAS PARA LCD ---------------------
lcd_init:

	CLR RS	

	CLR P1.7		
	CLR P1.6		
	SETB P1.5		
	CLR P1.4	

	SETB EN	
	CLR EN	

	CALL delay		

	SETB EN		
	CLR EN		

	SETB P1.7	

	SETB EN	
	CLR EN		
				
	CALL delay		

	CLR P1.7	
	CLR P1.6	
	CLR P1.5	
	CLR P1.4	

	SETB EN	
	CLR EN	

	SETB P1.6	
	SETB P1.5		

	SETB EN	
	CLR EN	

	CALL delay		

	CLR P1.7		
	CLR P1.6	
	CLR P1.5		
	CLR P1.4		

	SETB EN		
	CLR EN		

	SETB P1.7		
	SETB P1.6		
	SETB P1.5	
	SETB P1.4		

	SETB EN	
	CLR EN	

	CALL delay		
	RET


sendCharacter:
	SETB RS  		
	MOV C, ACC.7		
	MOV P1.7, C			
	MOV C, ACC.6	
	MOV P1.6, C			
	MOV C, ACC.5		
	MOV P1.5, C		
	MOV C, ACC.4		
	MOV P1.4, C			

	SETB EN			
	CLR EN			

	MOV C, ACC.3		
	MOV P1.7, C			
	MOV C, ACC.2	
	MOV P1.6, C			
	MOV C, ACC.1	
	MOV P1.5, C			
	MOV C, ACC.0		
	MOV P1.4, C			

	SETB EN			
	CLR EN			

	CALL delay		
	RET

;Posiciona o cursor na linha e coluna desejada.
;Escreva no Acumulador o valor de endereço da linha e coluna.
;|--------------------------------------------------------------------------------------|
;|linha 1 | 00 | 01 | 02 | 03 | 04 |05 | 06 | 07 | 08 | 09 |0A | 0B | 0C | 0D | 0E | 0F |
;|linha 2 | 40 | 41 | 42 | 43 | 44 |45 | 46 | 47 | 48 | 49 |4A | 4B | 4C | 4D | 4E | 4F |
;|--------------------------------------------------------------------------------------|
posicionaCursor:
	CLR RS	         
	SETB P1.7		    
	MOV C, ACC.6		
	MOV P1.6, C			
	MOV C, ACC.5	
	MOV P1.5, C		
	MOV C, ACC.4	
	MOV P1.4, C			

	SETB EN			
	CLR EN			

	MOV C, ACC.3		
	MOV P1.7, C			
	MOV C, ACC.2	
	MOV P1.6, C			
	MOV C, ACC.1		
	MOV P1.5, C		
	MOV C, ACC.0	
	MOV P1.4, C		

	SETB EN		
	CLR EN			

	CALL delay		
	RET


;Retorna o cursor para primeira posição sem limpar o display
retornaCursor:
	CLR RS	      
	CLR P1.7		
	CLR P1.6		
	CLR P1.5	
	CLR P1.4	

	SETB EN		
	CLR EN	

	CLR P1.7	
	CLR P1.6	
	SETB P1.5		
	SETB P1.4		

	SETB EN	
	CLR EN		

	CALL delay	
	RET

;Limpa o display
clearDisplay:
	CLR RS	     
	CLR P1.7		
	CLR P1.6		
	CLR P1.5		
	CLR P1.4		

	SETB EN		
	CLR EN	

	CLR P1.7	
	CLR P1.6	
	CLR P1.5	
	SETB P1.4	

	SETB EN	
	CLR EN		

	CALL delay
	RET


delay:
	MOV R3, #50
	DJNZ R3, $
	RET
