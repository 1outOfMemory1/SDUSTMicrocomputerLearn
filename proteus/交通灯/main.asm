DATA SEGMENT  ;���ݶ�

   ; �����0-15(f)�Ķ��� 
   ;LED DB 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,77h,7ch,39h,5eh,79h,71h ;����
   ;              0    1    2    3    4    5     6      7   8    9    10  11  12   13   14     15 
   LED DB 66h,4fh,5bh,06h,3fh,7fh,7fh,7fh,66h,4fh,5bh,06h,3fh,7fh,7fh,7fh;����
   
   ;  24h �ϱ��̶�����
   ;  44h �ϱ�����������
   ;  04h  �ϱ���������
   ;  81h �ϱ��춫����
   ;  82h �ϱ�������������
   ;  80h �ϱ�����������
   LIGHT DB 24h,24h,24h,24h,44h,04h,44h,04h,81h,81h,81h,81h,82h,80h,82h,80h,24h
   
   PORTA equ 60h
   PORTB equ 62h
   PORTC equ 64h
   CONTROL8255 equ 66h
   ;  d7��־λ(1)    d6d5��ʽ0(00)     d4A������(1)      d3 c0-c3���(0)  d2 B�鷽ʽ0(0) d1 B����� (0)  d0 c4-c7��� (0)
   REGIS_8255 equ 10010000B ; A������ B����� C����� 
   
   
   ICW1 equ 70H
   ICW2 equ 72H
   ICW3 equ 72H
   ICW4 equ 72H
   
   OCW1 equ 72H
   OCW2 equ 70H
   OCW2 equ 70H
   CNT DB 00H    ; ���ڼ�����ǰӦ�ý�ʲô�������͵�8255оƬ
   IS_PAUSED  DB 00H    ; �жϵ�ǰ�Ƿ��оȻ��� �������ô��Ҫ��ͣ�ж� 
   
   ;����8253�ĵ�ַ
   COUNT0 equ 68h
   COUNT1 equ 6ah
   COUNT2 equ 6ch
   CONTROL_8253 equ 6eh
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
		;��ʼ������κ�ջ��
		MOV AX,DATA
		MOV DS,AX
		MOV AX,STACK
		MOV SS,AX
		  
		  
		; 8255  ��ʼ��   
		MOV DX,CONTROL8255
		MOV AL,REGIS_8255
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
		; ���ȼ���ߵ��ǻָ���ť�İ���
		MOV AX,00H
		MOV ES,AX
		MOV BX,60H*4
		MOV AX,OFFSET  INT_RESUME 
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		  
		; �ڶ����ȼ�������ͣ��ť�İ���
		MOV BX,61H*4
		MOV AX,OFFSET INT_PAUSE
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		 
		; ����Ȩ��͵���8253���������ص����� �������ж�
		MOV BX,62H*4
		MOV AX,OFFSET INT_INC
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		
		STI  ; ���ж�
		; ��ʼ���ƺ������  �õ�������ܶ�����ʾ���� 
		MOV DX,PORTB
		MOV AL,00H
		OUT DX,AL
		MOV DX,PORTC
		MOV AL,00H
		OUT DX,AL
		   
		   
		; 8253�ĳ�ʼ��
	        MOV DX,CONTROL_8253
		MOV AL,00110101B    ;00 ѡ��ͨ��0     11 �ȶ�/д���������ֽں��� ��/д���ֽ�  000 ��ʽ0   1 bcd�����  
		OUT DX,AL
		MOV DX,COUNT0    ; ����bcd�� 10 00   Ҳ����1000 �����׼������1000hz�� ��ôÿһ���ж�һ��
		MOV AL,00H
		OUT DX,AL
		MOV AL,10H
		OUT DX,AL
	   
	L1: JMP L1  ; ������ѭ��  �ȴ��ж�
MAIN ENDP	

; 1��һ���ж�  
INT_INC PROC
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		MOV AL,0FFH     ;���ж��Ƿ��������ͣ����� ������� ��ô�˴β����е�������ܵı任
		CMP AL,IS_PAUSED
		JZ RETURN
		  
		 ; �õ�CNT��ֵ ��������ܵ�����
		MOV AL,CNT
		INC AL 
		MOV CL,AL      ; ��cl�ȱ���һ��   ��ߺ��̵ƻ��õ�
		AND AL,0FH     ; �����ǻ�ȡ��8λ   0 �� f ��16��״̬ f + 1 �ͻ������ 0  
		MOV CNT,AL     ; ��һ��Ϻ�д���ڴ�  
		MOV BX,OFFSET LED  
		XLAT
		MOV DX,PORTB
		OUT DX,AL
		
		
		; ���ƽ�ͨ�Ƶ�����
		MOV AL,CL
		MOV DX,PORTC
		MOV BX,OFFSET LIGHT
		XLAT
		OUT DX,AL
RETURN: MOV DX,OCW2
		MOV AL,20H
		OUT DX,AL
		POP AX
		POP BX
		POP CX
		POP DX
		STI    ; ���ж�
		RET
INT_INC ENDP	

; �ָ��ж� (��ͨ�ָ�)
INT_RESUME PROC ; resume �ж�
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		; ����ͣ��־����
		MOV AL,00H
		MOV IS_PAUSED,AL  
		MOV AL,CNT
		MOV BX,OFFSET LIGHT
		XLAT
		MOV DX,PORTC
		OUT DX,AL
		MOV DX,OCW2
		MOV AL,20H
		OUT DX,AL
		
		POP AX
		POP BX
		POP CX
		POP DX
		STI
		RET
INT_RESUME ENDP

; ��ͣ�ж� (�Ȼ�������)
INT_PAUSE PROC     ; pause
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		; ������ͣ��־Ϊ FF
		MOV AL,0FFH
		MOV IS_PAUSED,AL
		
		; ���� ���̵�Ϊ ȫ���
		MOV AL,84H
		MOV DX,PORTC
		OUT DX,AL
		
		;��������ܲ���ʾ����ʱ
		MOV AL,00H
		MOV DX,PORTB
		OUT DX,AL
		
		MOV DX,OCW2
		MOV AL,20H
		OUT DX,AL
		POP AX
		POP BX
		POP CX
		POP DX
		STI
		RET
INT_PAUSE ENDP

CODE ENDS

END MAIN