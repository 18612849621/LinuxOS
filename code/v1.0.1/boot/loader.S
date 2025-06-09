%include "code/v1.0.1/boot/boot.inc"
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
    ; 用于记录 ARDS 结构体数量 xp /h 0xbfe
    ards_num       dw  0
    ; 选择子 (16 bit) 定义 左移 3 位就是选择子的索引
    SELECTOR_CODE  equ (0x0001 << 3) + TI_GDT + RPL0
    SELECTOR_DATA  equ (0x0002 << 3) + TI_GDT + RPL0
    SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0
; addr 0xc00 上面的 placeholder 为了对齐 让 mbr 可以直接跳转到此地址
loader_start:
    ;int 0x15 eax= 0x0000E820, edx=0x534d4150 ("SMAP') 获取内存布局
    xor ebx, ebx
    mov edx, 0x534d4150
    mov di,  ards_buffer
; 循环获取每个ARDS内存范围描述结构
.e820_get_mem_loop:
    mov ecx, 20
    ; 每轮执行后会刷新 eax 寄存器的值 所以需要重新赋值
    mov eax, 0x0000E820
    int 0x15
    ; jc CF = 1 则跳转
    jc  .e820_failed_so_try_e801
    add di,  cx
    inc word [ards_num]
    ; ebx 为 0 说明遍历到末尾, cmp 的比较方法就是操作数1(ebx) - 操作数2 (0)
    cmp ebx, 0
    ; jnz ZF为 0 (cmp 比较结果不相等) 则跳转
    jnz .e820_get_mem_loop
    ; 找到所有ards中最高位的内存地址
    ; 循环 ards_num 次
    mov cx,  [ards_num]
    ; 初始化 ards 第一个位置
    mov ebx, ards_buffer
    ; 用 edx 记录最大值
    xor edx, edx
    ; 循环遍历所有 ARDS 结构体
    ; base_add_low + length_low [低 32 位] 因为操作系统是 32 bit
.find_max_mem_loop:
    mov eax, [ebx]
    add eax, [ebx + 8]
    cmp edx, eax
    ; jge 操作数1 >= 操作数2 不更新最大值
    jge .scan_next_ards
    mov edx, eax
.scan_next_ards:
    ; ards 的结构体占用 20 Bytes
    add  ebx, 20
    loop .find_max_mem_loop
    jmp  .mark_max_mem_addr
; int 0x15 ax=E801h 获取内存大小最大支持 4G 返回后
; ax 和 cx 值一样以 1 KB 为单位 
; bx 和 dx 值一样以 64 KB 为单位
; ax 和 cx 寄存器表示低 16 MB 其实是 0 - 15 MB 其中 1 MB 给 ISA 设备准备
; bx 和 dx 寄存器中为 16 MB 到 4 GB
.e820_failed_so_try_e801:
    mov eax, 0xE801
    int 0x15
    jc  .e801_failed_so_try_e88

.e801_failed_so_try_e88:
    mov eax, 0xE88
    int 0x15
    jc  .complete_failed

.complete_failed:
    jmp $

.mark_max_mem_addr:
    ; 存储最大值 到 0xb00 用 xp /g 0xb00
    mov [total_mem_bytes], edx
    jmp $

