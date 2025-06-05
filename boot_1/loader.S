%include "boot_1/boot.inc"
section loader vstart=LOADER_BASE_ADDR_IN_MEM
LOADER_STACK_TOP_ADDR equ LOADER_BASE_ADDR_IN_MEM
; 函数执行需要恢复的地址为 LOADER_BASE_ADDR_IN_MEM 给 sp 寄存器赋值
jmp loader_start
; --------------------GDT------------------------
    ; GDT表的起始地址 0x00000000 段界限为 0 其实就是空段 纯占位置
    ; 本身GDT模式下 第一个选择子是空
    GDT_BASE dd 0x00000000
        dd 0x00000000
    CODE_DESC dd 0x0000FFFF
        dd DESC_CODE_HIGH_4
    DATA_STACK_DESC dd 0x0000FFFF
        dd DESC_DATA_HIGH_4
    ; (0xbffff - 0xb8000) = 0x7fff = 32767
    ; limit = 32767 / 4096[4K] ~= 7.99 所以段限制最高索引为7
    VIDEO_DESC dd 0x80000007
        dd DESC_VIDEO_HIGH_4
    ; ------------------一些宏定义------------------
    ; GDT 表大小 = 当前地址($) - GDT 表的起始地址
    GDT_SIZE  equ $ - GDT_BASE
    ; GDT 表总共大小为 32 字节, 这里 -1 是因为索引为 1
    GDT_LIMIT equ GDT_SIZE - 1
    ; 预留 60 个描述符的空间
    ; times 60       dq  0x0
    ; GDT 表的结束地址
    gdt_ptr   dw  GDT_LIMIT
        dd GDT_BASE
    ; 选择子 (16 bit) 定义 左移 3 位就是选择子的索引
    SELECTOR_CODE  equ (0x0001 << 3) + TI_GDT + RPL0
    SELECTOR_DATA  equ (0x0002 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0
    LODER_CONTENT  db  '2 loader design by pan'
; ------------------loader start--------------------
loader_start:
    ;---------------------------------
    ; INT 0x10
    ; 功能号：0x13
    ; 功能描述：打印字符串
    ; wiki: https://blog.csdn.net/judyge/article/details/52289231
    ;---------------------------------
    ; 输入
    ; AH = 0x13
    ; AL=显示输出方式
        ; 0——字符串中只含显示字符，其显示屬性在 BL 中 | 显示后，光标位置不变
        ; 1——字符串中只含显示字符，其显示屬性在 BL 中 | 显示后，光标位置改变
        ; 2——字符串中含显示字符和显示属性             | 显示后，光标位置不变
        ; 3——字符串中含显示字符和显示属性             | 显示后，光标位置改变
    ; BH = 页号
    ; BL = 页属性
    ; CX = 字符串长度
    ; (DH, DL) = 坐标(行、列)
    ; ES:BP = 字符串地址
    ; 无返回值;
    mov  sp,   LOADER_BASE_ADDR_IN_MEM
    mov  bp,   LODER_CONTENT
    mov  cx,   22
    mov  ax,   0x1301
    ; 页号为 (BH = 0) | 蓝底粉红字 (BL = 1fh)
    mov  bx,   0x001f
    ; 由于在文本模式下的行数是25(0x18) 第 25 行 第 0 列, 文本模式下一共就 25 行
    mov  dx,   0x1800
    int  0x10                          ;调用BIOS中断0x10
    ; ------------------准备进入保护模式------------------------
    ; 1. 打开A20 Gate 将端口 0x92 的第 1 位置 1
    in   al,   0x92
    or   al,   0000_0010b
    out  0x92, al
    ; 2. 保护模式的开关，CRO 寄存器的 PE 位置 0
    mov  eax,  cr0
    or   eax,  0x00000001
    mov  cr0,  eax
    ; 3. 加载 GDT 地址 后续使用选择子进行访存
    lgdt [gdt_ptr]

    jmp dword SELECTOR_CODE:p_mode_start ; 远跳转到保护模式, 刷新流水线


; ------------------loader start--------------------
[bits 32]
p_mode_start:
    mov ax,            SELECTOR_DATA
    mov ds,            ax
    mov es,            ax
    mov ss,            ax
    mov esp,           LOADER_STACK_TOP_ADDR
    mov ax,            SELECTOR_VIDEO
    mov gs,            ax
    mov byte [gs:160], 'P'
    mov byte [gs:161], 0xA4
    mov byte [gs:162], 'P'
    mov byte [gs:163], 0xA4
    mov byte [gs:164], 'P'
    mov byte [gs:165], 0xA4
    jmp $
