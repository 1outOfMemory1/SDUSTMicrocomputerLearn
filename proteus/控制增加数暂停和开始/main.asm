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
DATA SEGMENT  ;数据段
   LED DB 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,77h,7ch,39h,5eh,79h,71h ;段码
   PORTA equ 60h
   PORTB equ 62h
   PORTC equ 64h
   CS8255 equ 66h
   REGIS equ 10010000B ; A口输入 B口输出
   ICW1 equ 70H
   ICW2 equ 72H
   ICW3 equ 72H
   ICW4 equ 72H
   
   OCW1 equ 72H
   OCW2 equ 70H
   OCW2 equ 70H
   
   CNT DB 00H
    IS_PAUSED  DB 00H
   
   ;引入8253的地址
   COUNT0 equ 68h
   COUNT1 equ 6ah
   COUNT2 equ 6ch
   CS_8253 equ 6eh

   
DATA ENDS

EXTRA SEGMENT
EXTRA ENDS

STACK SEGMENT PARA STACK 'STACK' ; 堆空间
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
		 ; 8255  初始化
		  MOV DX,CS8255
		  MOV AL,REGIS
		  OUT DX,AL
		  
		  
		   ; 8259初始化
		  ; ICW1  D3设置电平触发 (1)还是边沿触发(0)  D1设置单机 (1)使用还是级联使用 (0)   D0设置为1(需要设置ICW4)
		  
		  MOV DX,ICW1
		  MOV AL,00010011B
		  OUT DX,AL
		  
		  ;ICW2 设置中断源的中断类型号  
		  ;例如，ICW2=08H，则IR0～IR7请求对应的中断类型码分别为：08H、09H、0AH、0BH、0CH、0DH、0EH、0FH。 ICW2=70H，IR0～IR7请求对应的中断类型码分别为：70H、71H、72H、73H、74H、75H、76H、77H。
		  MOV DX,ICW2
		  MOV AL,60H
		  OUT DX,AL
		  
		  ; 未设置ICW3  主8259的ICW3：指出主8259的哪些引脚上联有从8259。如：ICW3=11110000B，则主8259的IR7、IR6、IR5、IR4上均连有从8259。
		  
		  ; ICW4  缓冲方式 等
		  MOV DX,ICW4
		  MOV AL,00000001B
		  OUT DX,AL
		  
		  ; 中断屏蔽字 0为允许中断
		  MOV DX,OCW1
		  MOV AL,11100000B
		  OUT DX,AL
		  
		  
		  ; 定义中断向量表  
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
		  ; 8253的初始化
		   MOV DX,CS_8253
		   MOV AL,00110101B    ;00 选择通道0     11 先读/写计数器低字节后再 读/写高字节  000 方式0   1 bcd码计数  
		   OUT DX,AL
		   
		   MOV DX,COUNT0
		   MOV AL,00H
		   OUT DX,AL
		   
		   MOV AL,10H
		   OUT DX,AL
		   
		   
		   MOV DX,CS_8253
		   MOV AL,01110101B    ;00 选择通道01    11 先读/写计数器低字节后再 读/写高字节  000 方式0   1 bcd码计数  
		   OUT DX,AL
		   
		   MOV DX,COUNT1
		   MOV AL,00H
		   OUT DX,AL
		   
		   MOV AL,20H
		   OUT DX,AL
		  
		  
		   MOV DX,CS_8253
		   MOV AL,10110101B    ;00 选择通道01    11 先读/写计数器低字节后再 读/写高字节  000 方式0   1 bcd码计数  
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