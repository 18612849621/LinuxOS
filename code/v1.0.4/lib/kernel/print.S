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
    ; 这里省略一组指令
    ; push ebp
    ; mov ebp, esp
    ; ...
    ; pop ebp
    ; 稳定性需求​​：ESP 在函数执行中频繁变化（如 push 局部变量），若直接以 ESP 为基准定位变量，需动态计算偏移量，易出错且低效
    ; 按照此中逻辑除了第一层 ebp 所指向的应该是函数的返回地址 / 入参以外，其他的 ebp 都应该指向上一层函数的 ebp, 这样 EBP 链（每个栈帧保存上一个 EBP）形成调用栈，调试器可通过 EBP 回溯函数调用路径（如 [EBP] 指向上一栈帧的 EBP）
    ; pushad(push all double) 
    ; 保存寄存器上下文，该指令压入所有双字长的奇存器
    ; 这里的 “所有” 一共是 8 * 4 Bytes 的寄存器，它们的入栈先后顺序是: EAX->ECX->EDX->EBX->ESP->EBP->ESI->EDI，EAX是最先入栈
    ; ​操作过程中​​不改变EFLAGS 标志寄存器​​的状态
    ; pushad的话需要 [EBP + 8] 指向上一栈帧的 EBP
    pushad
    ; 保证上下文安全每次都刷新 gs 位为显存选择子
    mov ax,  SELECTOR_VIDEO
    mov gs,  ax
    ; ==============获取当前光标位置==============
    ; 光标
    ; 高地址索引 0Eh 
    mov dx,  0x3d4
    mov al,  0x0e
    out dx,  al
    mov dx,  0x3d5
    in  al,  dx
    ; 保存高位到 ah 中
    mov ah,  al
    ; 低地址索引 0Fh
    mov dx,  0x3d4
    mov al,  0x0f
    out dx,  al
    mov dx,  0x3d5
    in  al,  dx
    ; 现在 al 存储的是光标的低位，ah 存储的是光标的高位
    ; 将光标地址存在 bx 中
    mov bx,  ax
    ; 入参为字符 void put_char(uint8_t char_asci);
    ; 所以 esp + 36 (esp 是栈顶指针) +32 处是返回的函数地址 +36 就是第一个入参
    mov ecx, [esp + 36]
    ; ​​CR(Carriage Return，回车) ​​​作用​​: 将光标或打印头移动到​​当前行的起始位置​​（行首），不换行 ​ASCII 编码​​: 十六进制 0x0D（十进制 13），转义字符为 \r
    ; ​LF(Line Feed，换行)​​ ​作用​​: 将光标或打印头​​垂直移动到下一行​​，但​​不改变水平位置​​（列位置不变）
    ; ​ASCII 编码​​: 十六进制 0x0A（十进制10）转义字符为 \n。
    cmp cl,  0xd
    jz  .is_carriage_return
    cmp cl,  0xa
    jz  .is_line_feed
    ; 空格 0x8
    cmp cl,  0x8
    jz  .is_backspace
    jmp .put_other
.is_carriage_return:
.is_line_feed:
.is_backspace:
.put_other:
.set_cursor:
.put_char_done: 
    popad
    ret
