DATA SEGMENT  ;数据段

   ; 数码管0-15(f)的断码 
   ;LED DB 3fh,06h,5bh,4fh,66h,6dh,7dh,07h,7fh,6fh,77h,7ch,39h,5eh,79h,71h ;段码
   ;              0    1    2    3    4    5     6      7   8    9    10  11  12   13   14     15 
   LED DB 66h,4fh,5bh,06h,3fh,7fh,7fh,7fh,66h,4fh,5bh,06h,3fh,7fh,7fh,7fh;段码
   
   ;  24h 南北绿东西红
   ;  44h 南北黄亮东西红
   ;  04h  南北黄灭东西红
   ;  81h 南北红东西绿
   ;  82h 南北红亮东西黄亮
   ;  80h 南北红灭东西黄灭
   LIGHT DB 24h,24h,24h,24h,44h,04h,44h,04h,81h,81h,81h,81h,82h,80h,82h,80h,24h
   
   PORTA equ 60h
   PORTB equ 62h
   PORTC equ 64h
   CONTROL8255 equ 66h
   ;  d7标志位(1)    d6d5方式0(00)     d4A口输入(1)      d3 c0-c3输出(0)  d2 B组方式0(0) d1 B口输出 (0)  d0 c4-c7输出 (0)
   REGIS_8255 equ 10010000B ; A口输入 B口输出 C口输出 
   
   
   ICW1 equ 70H
   ICW2 equ 72H
   ICW3 equ 72H
   ICW4 equ 72H
   
   OCW1 equ 72H
   OCW2 equ 70H
   OCW2 equ 70H
   CNT DB 00H    ; 用于计数当前应该将什么数据输送到8255芯片
   IS_PAUSED  DB 00H    ; 判断当前是否有救护车 如果有那么需要暂停中断 
   
   ;引入8253的地址
   COUNT0 equ 68h
   COUNT1 equ 6ah
   COUNT2 equ 6ch
   CONTROL_8253 equ 6eh
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
		;初始化代码段和栈段
		MOV AX,DATA
		MOV DS,AX
		MOV AX,STACK
		MOV SS,AX
		  
		  
		; 8255  初始化   
		MOV DX,CONTROL8255
		MOV AL,REGIS_8255
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
		; 优先级最高的是恢复按钮的按下
		MOV AX,00H
		MOV ES,AX
		MOV BX,60H*4
		MOV AX,OFFSET  INT_RESUME 
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		  
		; 第二优先级的是暂停按钮的按下
		MOV BX,61H*4
		MOV AX,OFFSET INT_PAUSE
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		 
		; 优先权最低的是8253脉冲上升沿的跳变 引发的中断
		MOV BX,62H*4
		MOV AX,OFFSET INT_INC
		MOV ES:[BX],AX
		MOV AX,CS
		MOV ES:[BX+2],AX
		
		STI  ; 开中断
		; 初始化灯和数码管  让灯与数码管都不显示东西 
		MOV DX,PORTB
		MOV AL,00H
		OUT DX,AL
		MOV DX,PORTC
		MOV AL,00H
		OUT DX,AL
		   
		   
		; 8253的初始化
	        MOV DX,CONTROL_8253
		MOV AL,00110101B    ;00 选择通道0     11 先读/写计数器低字节后再 读/写高字节  000 方式0   1 bcd码计数  
		OUT DX,AL
		MOV DX,COUNT0    ; 送入bcd码 10 00   也就是1000 如果基准脉冲是1000hz的 那么每一秒中断一次
		MOV AL,00H
		OUT DX,AL
		MOV AL,10H
		OUT DX,AL
	   
	L1: JMP L1  ; 进入死循环  等待中断
MAIN ENDP	

; 1秒一个中断  
INT_INC PROC
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		MOV AL,0FFH     ;先判断是否出现了暂停的情况 如果出现 那么此次不进行灯与数码管的变换
		CMP AL,IS_PAUSED
		JZ RETURN
		  
		 ; 拿到CNT的值 控制数码管的亮灭
		MOV AL,CNT
		INC AL 
		MOV CL,AL      ; 给cl先保存一下   后边红绿灯会用到
		AND AL,0FH     ; 相与是获取低8位   0 到 f 是16个状态 f + 1 就会溢出成 0  
		MOV CNT,AL     ; 加一完毕后写回内存  
		MOV BX,OFFSET LED  
		XLAT
		MOV DX,PORTB
		OUT DX,AL
		
		
		; 控制交通灯的亮灭
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
		STI    ; 开中断
		RET
INT_INC ENDP	

; 恢复中断 (交通恢复)
INT_RESUME PROC ; resume 中断
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		; 将暂停标志清零
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

; 暂停中断 (救护车到来)
INT_PAUSE PROC     ; pause
		PUSH AX
		PUSH BX
		PUSH CX
		PUSH DX
		; 设置暂停标志为 FF
		MOV AL,0FFH
		MOV IS_PAUSED,AL
		
		; 设置 红绿灯为 全红灯
		MOV AL,84H
		MOV DX,PORTC
		OUT DX,AL
		
		;设置数码管不显示倒计时
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