; 8   1000
; 9   1001
; a   1010
; b   1011

; 8   1000
; 9   1001
; a   1010
; b   1011



; 0   0000
; 2   0010
; 4   0100
; 6  0110


; 0   0000
; 4   0100
; 8   1000
; c   1100
DATA SEGMENT  ;���ݶ�
   LED DB 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,77h,7ch,39h,5eh,79h,71h ;����
   PORTA equ 60h
   PORTB equ 62h
   PORTC equ 64h
   CS8255 equ 66h
   REGIS equ 10010000B ; A������ B�����
   ICW1 equ 70H
   ICW2 equ 72H
   ICW3 equ 72H
   ICW4 equ 72H
   
   OCW1 equ 72H
   OCW2 equ 70H
   OCW2 equ 70H
   
   CNT DB 00H
    IS_PAUSED  DB 00H
   
   ;����8253�ĵ�ַ
   COUNT0 equ 68h
   COUNT1 equ 6ah
   COUNT2 equ 6ch
   CS_8253 equ 6eh

   
DATA ENDS

EXTRA SEGMENT
EXTRA ENDS

STACK SEGMENT PARA STACK 'STACK' ; �ѿռ�
STAPN DB 100 DUP (00H)
TOP equ LENGTH STAPN
STACK ENDS



CODE    SEGMENT PUBLIC 'CODE'
MAIN PROC FAR 
        ASSUME CS:CODE,DS:DATA,ES:EXTRA,SS:STACK

START:
		  MOV AX,DATA
		  MOV DS,AX
		  
		  MOV AX,EXTRA
		  MOV ES,AX
		  
		  MOV AX,STACK
		  MOV SS,AX
		 ; 8255  ��ʼ��
		  MOV DX,CS8255
		  MOV AL,REGIS
		  OUT DX,AL
		  
		  
		   ; 8259��ʼ��
		  ; ICW1  D3���õ�ƽ���� (1)���Ǳ��ش���(0)  D1���õ��� (1)ʹ�û��Ǽ���ʹ�� (0)   D0����Ϊ1(��Ҫ����ICW4)
		  
		  MOV DX,ICW1
		  MOV AL,00010011B
		  OUT DX,AL
		  
		  ;ICW2 �����ж�Դ���ж����ͺ�  
		  ;���磬ICW2=08H����IR0��IR7�����Ӧ���ж�������ֱ�Ϊ��08H��09H��0AH��0BH��0CH��0DH��0EH��0FH�� ICW2=70H��IR0��IR7�����Ӧ���ж�������ֱ�Ϊ��70H��71H��72H��73H��74H��75H��76H��77H��
		  MOV DX,ICW2
		  MOV AL,60H
		  OUT DX,AL
		  
		  ; δ����ICW3  ��8259��ICW3��ָ����8259����Щ���������д�8259���磺ICW3=11110000B������8259��IR7��IR6��IR5��IR4�Ͼ����д�8259��
		  
		  ; ICW4  ���巽ʽ ��
		  MOV DX,ICW4
		  MOV AL,00000001B
		  OUT DX,AL
		  
		  ; �ж������� 0Ϊ�����ж�
		  MOV DX,OCW1
		  MOV AL,11100000B
		  OUT DX,AL
		  
		  
		  ; �����ж�������  
		  MOV AX,00H
		  MOV ES,AX
		  
		  
		  MOV BX,60H*4
		  MOV AX,OFFSET  INT1 
		  MOV ES:[BX],AX
		  
		  MOV AX,CS
		  MOV ES:[BX+2],AX
		  
		  
		   MOV BX,61H*4
		  MOV AX,OFFSET INT2
		  MOV ES:[BX],AX
		  
		  MOV AX,CS
		  MOV ES:[BX+2],AX
		  
		  
		  MOV BX,62H*4
		  MOV AX,OFFSET INT_INC
		  MOV ES:[BX],AX
		  
		  MOV AX,CS
		  MOV ES:[BX+2],AX
		  
		  
		  
		  MOV BX,63H*4
		  MOV AX,OFFSET INT_INC
		  MOV ES:[BX],AX
		  
		  MOV AX,CS
		  MOV ES:[BX+2],AX
		  
		  MOV BX,64H*4
		  MOV AX,OFFSET INT_INC
		  MOV ES:[BX],AX
		  
		  MOV AX,CS
		  MOV ES:[BX+2],AX
		  

		   STI
		  ; 8253�ĳ�ʼ��
		   MOV DX,CS_8253
		   MOV AL,00110101B    ;00 ѡ��ͨ��0     11 �ȶ�/д���������ֽں��� ��/д���ֽ�  000 ��ʽ0   1 bcd�����  
		   OUT DX,AL
		   
		   MOV DX,COUNT0
		   MOV AL,00H
		   OUT DX,AL
		   
		   MOV AL,10H
		   OUT DX,AL
		   
		   
		   MOV DX,CS_8253
		   MOV AL,01110101B    ;00 ѡ��ͨ��01    11 �ȶ�/д���������ֽں��� ��/д���ֽ�  000 ��ʽ0   1 bcd�����  
		   OUT DX,AL
		   
		   MOV DX,COUNT1
		   MOV AL,00H
		   OUT DX,AL
		   
		   MOV AL,20H
		   OUT DX,AL
		  
		  
		   MOV DX,CS_8253
		   MOV AL,10110101B    ;00 ѡ��ͨ��01    11 �ȶ�/д���������ֽں��� ��/д���ֽ�  000 ��ʽ0   1 bcd�����  
		   OUT DX,AL
		   
		   MOV DX,COUNT2
		   MOV AL,00H
		   OUT DX,AL
		   
		   MOV AL,40H
		   OUT DX,AL
		

		   
	 L1:     JMP L1
	 
MAIN ENDP	

INT_INC PROC


		  PUSH AX
		  MOV AL,0FFH
		  CMP AL,IS_PAUSED
		  JZ RETURN
		  
		 
		 
		  
		  MOV AL,CNT
		  INC AL 
		  AND AL,0FH
		  MOV CNT,AL
		  
		  MOV BX,OFFSET LED
		  XLAT
		  
		  MOV DX,PORTB
		  OUT DX,AL
RETURN:     STI
		  MOV DX,OCW2
		  MOV AL,20H
		  OUT DX,AL
		  POP AX
		  
		  RET
INT_INC ENDP	


INT1 PROC ; resume

		  PUSH AX
		  MOV AL,00H
		  MOV IS_PAUSED,AL
		  
		  
		  MOV AL,21H
		  MOV DX,PORTC
		  OUT DX,AL
		  MOV DX,OCW2
		  MOV AL,20H
		  OUT DX,AL
		  POP AX
		  STI
		  RET

INT1 ENDP


INT2 PROC     ; pause
		  
		  PUSH AX
		  MOV AL,0FFH
		  MOV IS_PAUSED,AL
		  
		  MOV AL,84H
		  MOV DX,PORTC
		  OUT DX,AL
		  MOV DX,OCW2
		  MOV AL,20H
		  OUT DX,AL
		  POP AX
		  STI
		  RET
INT2 ENDP




DELAY PROC
	 PUSH CX
	 LOOP $
	 POP CX
	 RET
DELAY ENDP	
CODE ENDS

END MAIN