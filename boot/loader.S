%include "boot/boot.inc"
section loader vstart=LOADER_BASE_ADDR_IN_MEM
; --------------------GDT------------------------
    ; GDT表的起始地址 0x00000000 段界限为 0 其实就是空段 纯占位置
    ; 本身GDT模式下 第一个选择子是空
    GDT_BASE: 
        dd 0x00000000
        dd 0x00000000
    CODE_DESC:
        dd 0x0000ffff
        
; ------------------准备进入保护模式------------------------
    ; 1. 打开A20 Gate 将端口 0x92 的第 1 位置 1
    in  al,   0x92
    or  al,   0000_0010b
    out 0x92, al
    ; 2.保护模式的开关，CRO 寄存器的 PE 位置 0
    mov eax,  cr0
    or  eax,  0x00000001
    mov cr0,  eax
    ; 3. 加载 GDT 地址