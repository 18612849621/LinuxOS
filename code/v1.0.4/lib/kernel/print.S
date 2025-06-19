TI_GDT         equ 0
RPL0           equ 0
SELECTOR_VIDEO equ (0x0003 << 3) + RPL0 +TI_GDT

;默认情况下，MiscellaneousOutput Register 奇存器的值为 0x67(0110_0111)，其他字段不管，只关注这最重要的 I/OAS 位其值为 1
;所以 CRTcontroller 寄存器组的 AddressRegister 的端口地址为 0x3D4, Data Register 的端口地址 0x3D5
; put_char 和 put_str 函数都是用 ecx 传递字符内容
[bits 32]
section .text
;------------------------   put_str   ------------------------------
; 通过 put_char 来打印以0字符结尾的字符串
; 输入：栈中参数为打印的字符串
; 输出：无
; 背景：'\0' 的ASCII码为 0，所以很多字符串函数内部都通过把各个字符与 '\0' 比较来判断字符串是否结束
;-------------------------------------------------------------------  
global  put_str
put_str:
    ; 用到了 ebx 和 ecx 保护现场
    push ebx
    push ecx
    xor  ecx, ecx
    ; 字符串在栈中指针所指向的地址 
    ; [esp + 12] 跳过 ecx -> ebx -> 函数返回地址 -> str
    mov  ebx, [esp + 12]
.next_char:
    mov  cl,  [ebx]
    cmp  cl,  0
    jz   .str_end
    push ecx
    call put_char
    ; 帮忙弹出入参字符串
    add  esp, 4
    ; 下一个字符
    inc  ebx
    jmp  .next_char
.str_end:
    ; 恢复现场
    pop ecx
    pop ebx
    ret

;------------------------   put_char   -----------------------------
; 功能描述:把栈中的1个字符写入光标所在处
; 采用 80 x 25 的文本模式
; 一行 80 个字符, 共 25 行
;-------------------------------------------------------------------   
global put_char
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
    ; CR 和 LF 都统一处理成换到下一行的行首
    ; ​​CR(Carriage Return，回车) ​​ ​ASCII 编码​​: 十六进制 0x0D（十进制 13），转义字符为 \r
    cmp cl,  0xd
    jz  .is_carriage_return
    ; ​LF(Line Feed，换行)​​ 
    ; ​ASCII 编码​​: 十六进制 0x0A（十进制10）转义字符为 \n。
    cmp cl,  0xa
    jz  .is_line_feed
    ; BS(backspace)的 ascii 码是8
    cmp cl,  0x8
    jz  .is_backspace
    jmp .put_other
.is_backspace:
    ;====================backspace的说明=================
    ; 当为 backspace 时, 本质上只要将光标移向前一个显存位置即可 后面再输入的字符自然会覆盖此处的字符
    ; 但有可能在键入 backspace 后并不再键入新的字符,这时在光标已经向前移动到待删除的字符位置, 但字符还在原处
    ; 这就显得好怪异, 所以此处添加了空格
    ; 边界检查需要判断 bx 是否为 0 若是直接退出
    cmp bx,           0
    jz  .put_char_done
    ; 将 bx [光标索引] 减 1, 使光标向前移动一个字符位置
    dec bx
    ; 现在 bx 存储的是光标的索引, 需要将其转换为显存地址
    ; 显存地址 = 光标索引 * 2 (因为每个字符占用 2 Bytes)
    shl bx,           1
    mov byte [gs:bx], 0x20
    inc bx
    mov byte [gs:bx], 0x07
    ; 还原 bx 为回退一格字符的索引
    shr bx,           1
    jmp .set_cursor
.put_other:
    ; 将读取到的字符放入 gs:bx 光标出
    ; 因为 bx 存的是光标的索引 光标大小为 2 Bytes 所以需要 * 2 (bx << 1)
    shl bx,           1
    mov [gs:bx],      cl
    ; 字符为 0x07 (0000_0111) 白字 黑底 不闪烁 不高亮
    inc bx
    mov byte [gs:bx], 0x07
    ; 获取下一个光标的位置索引 只需要 (cursor + 1) / 2 就行 
    inc bx
    shr bx,           1
    ; bx 现在存的是下一个光标位置的索引 需要判断是否 < 2000
    ; >= 2000 的话就需要回到最初
    cmp bx,           2000
    jl  .set_cursor
.is_line_feed:
.is_carriage_return:
    ; 这里用 16 位除法就行
    ; ax 存商 dx 存余数
    xor dx, dx
    mov ax, bx
    mov si, 80
    div si
    ; 上面算出目前在第几行存在 ax 中
    ; 余数就是在当前行的第几列存在 bx 中 因为是行存所以需要 bx - dx 就是我们当前行的起始位置
    sub bx, dx
    ; 现在 bx 存储的是当前行的起始位置
    ; 只需要将 bx + 80 就是下一行的起始位置
    add bx, 80
    cmp bx, 2000
    jl  .set_cursor
; ================统一处理越界后的逻辑==============
; 因为越界一定会走 CR 和 LF 的逻辑
; 屏幕行范围是 0~24
; 若超出屏幕大小，开始滚屏
.roll_screen: 
; 滚屏的原理是将屏幕的 1~24 行搬运到 0~23 行, 再将第 24 行用空格填充
; 1~24 行一共需要搬运 1920 (24 * 80) 字符 一共 3840 Bytes
; rep movsd 一次 4 Bytes 所以循环 3840 / 4 = 960
    mov ecx, 960
    ; 第 0 行
    mov edi, 0xb8000
    ; 第 1 行 80 * 2 = 160 Bytes
    mov esi, 0xb80a0
    rep movsd
    ; 最后一行的开始字节 offset 是 3840 Bytes
    ; 填充整行为空白
    mov ebx, 3840
    mov ecx, 80
.cls:
    ; 0x0720是黑底白字的空格键
    mov  word [gs:ebx], 0x0720
    add  bx,            2
    loop .cls
    ; reset 到最后一行的行首
    mov  bx,            1920
.set_cursor:
    ; ==============设置光标位置==============
    ; bx 是光标需要设置的索引
    ; 高地址索引 0Eh 填充到索引寄存器 0x3d4
    mov dx, 0x3d4
    mov al, 0x0e
    out dx, al
    ; 将 bx 中存储的高 8 位写入到数据寄存器 0x3d5
    mov dx, 0x3d5
    mov al, bh
    out dx, al
    ; 低地址索引 0Fh 填充到索引寄存器 0x3d4
    mov dx, 0x3d4
    mov al, 0x0f
    out dx, al
    ; 将 bx 中存储的低 8 位写入到数据寄存器 0x3d5
    mov dx, 0x3d5
    mov al, bl
    out dx, al
.put_char_done:
    popad
    ret
