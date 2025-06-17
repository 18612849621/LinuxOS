TI_GDT         equ 0
RPL0           equ 0
SELECTOR_VIDEO equ (0x0003 << 3) + RPL0 +TI_GDT

;默认情况下，MiscellaneousOutput Register 奇存器的值为 0x67(0110_0111)，其他字段不管，只关注这最重要的 I/OAS 位其值为 1
;所以 CRTcontroller 寄存器组的 AddressRegister 的端口地址为 0x3D4, Data Register 的端口地址 0x3D5
[bits 32]
section .text
;------------------------   put_char   -----------------------------
;功能描述:把栈中的1个字符写入光标所在处
;-------------------------------------------------------------------   
global  put_char
put_char:
    ; pushad 保存寄存器上下文​​：
    ; pushad 将 8 个 32 位通用寄存器的值依次压入堆栈，顺序为：​​EAX、ECX、EDX、EBX、ESP、EBP、ESI、EDI​​ 堆栈指针变化​​：执行后，栈指针​​ ESP 自动减少 32 字节​​（8 个寄存器 × 4 字节）​不影响标志位​​：操作过程中​​不改变EFLAGS 标志寄存器​​的状态
    pushad
    ; 保证上下文安全每次都要让 gs 位显存选择子
    mov ax, SELECTOR_VIDEO
    mov gs, ax
    ; ==============获取当前光标位置==============
    ; 光标
    ; 高地址索引 0Eh 
    mov dx, 0x3d4
    mov al, 0x0e
    out dx, al
    mov dx, 0x3d5
    in  al, dx
    ; 保存高位到 ah 中
    mov ah, al
    ; 低地址索引 0Fh
    mov dx, 0x3d4
    mov al, 0x0f
    out dx, al
    mov dx, 0x3d5
    in  al, dx
    ; 现在 al 存储的是光标的低位，ah 存储的是光标的高位
    ; 将光标地址存在 bx 中
    mov bx, ax
