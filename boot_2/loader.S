%include "boot_2/boot.inc"
section loader vstart=LOADER_BASE_ADDR_IN_MEM
LOADER_STACK_TOP_ADDR equ LOADER_BASE_ADDR_IN_MEM
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
    GDT_SIZE        equ $ - GDT_BASE
    ; GDT 表总共大小为 32 字节, 这里 -1 是因为索引为 1
    GDT_LIMIT       equ GDT_SIZE - 1
    ; 预留 60 个描述符的空间
    times 60        dq  0x0
    ; 此处为开头偏移 256[0x200] Bytes 0x900 + 0x200 = 0xb00
    ; 用 32 位数据 debug 所申请内存的大小
    total_mem_bytes dd  0
    ; GDT 表的结束地址
    gdt_ptr         dw  GDT_LIMIT
        dd GDT_BASE
    ; total_mem_bytes_4 + gdt_ptr_6 + ards_buffer_244 
    ards_buffer times 244 db 0
    placeholder_padding dw  0
    ; 选择子 (16 bit) 定义 左移 3 位就是选择子的索引
    SELECTOR_CODE       equ (0x0001 << 3) + TI_GDT + RPL0
    SELECTOR_DATA       equ (0x0002 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO      equ (0x0003 << 3) + TI_GDT + RPL0
; addr 0xc00 上面的 placeholder 为了对齐 让 mbr 可以直接跳转到此地址
loader_start:
    ;int 0x15 eax= 0x0000E820, edx=0x534d4150 ("SMAP') 获取内存布局
    xor ebx, ebx
    mov edx, 0x534d4150
    mov di,  ards_buffer
.e820_get_mem_loop:
    mov ecx, 20
    mov eax, 0x0000E820