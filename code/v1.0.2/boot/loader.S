%include "code/v1.0.2/boot/boot.inc"
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


    ; jmp $
; -------------执行页表初始化-----------------
call init_page_table_dir_mem
; reload gdt_ptr 寄存器的结果
sgdt [gdt_ptr]
; 获取 GDT 表的存储位置 0 ~ 2 bytes 是界限所以要 +2
mov  ebx,                    [gdt_ptr + 2]
; dword 4 bytes 因为开启了分页 + 保护模式 所以需要偏移到真实的内核空间
; 视频段是第 3 个段描述符，每个描述符是 8 字节，故 0x18 = 24
; 段描述符的高 4 字节的最高位是段基址的第 31 ~ 24 位
or   dword [ebx + 0x18 + 4], 0xc0000000
; 更新栈基地址 & gdt表地址
add  dword [gdt_ptr + 2],    0xc0000000
add  esp,                    0xc0000000
; 页目录给 cr3 寄存器
mov  eax,                    PAGE_DIR_BASE_ADDR_IN_MEM
mov  cr3,                    eax
; 设置 CR0 寄存器的 PG 位 31位
mov  eax,                    cr0
or   eax,                    0x80000000
mov  cr0,                    eax
; 目前是 保护 + 分页 模式
lgdt [gdt_ptr]                                         ; 重新加载 GDT(分页模式) 
mov  byte [gs:166],          'V'
mov  byte [gs:167],          0xA4
jmp  $
; -------------页表初始化例程---------------
; 页目录 at PAGE_DIR_BASE_ADDR_IN_MEM=0x100000
init_page_table_dir_mem:
    ; 页表目录的大小占用物理页面 4KB
    mov ecx, 4096
    xor esi, esi
.reset_mem_loop_by_bytes:
    mov  byte [PAGE_DIR_BASE_ADDR_IN_MEM + esi], 0b
    inc  esi
    loop .reset_mem_loop_by_bytes

; 创建页目录项 PDE (page directory entry)
.create_pde:
    ; 用 eax 制作第一个 PDE
    mov eax,                                 PAGE_DIR_BASE_ADDR_IN_MEM
    ; 第一个页表的位置在 页目录末尾的下一个字节
    add eax,                                 0x1000
    ; 用 ebx 记录一下第一个页表的物理地址
    mov ebx,                                 eax
    ; or 0x7
    or  eax,                                 PAGE_P | PAGE_RW_W | PAGE_US_U
    ; 页表表示4MB内存, 内核较小仅使用物理地址中的低 1MB 空间
    ; 内核在进程模型中占用高 1GB 空间 (3GB, 4GB]
    ; 第 1G 所指向地址为 (01000000_00000000_00000000_00000000 - 1)
    ; 3G = 11000000_00000000_00000000_00000000 = 0xc0000000
    ; 取前 10 位为 1100000000 = 0x300 = 768 (页目录项索引)
    ; 所以将页目录项 0 (0) 和 768 (0xc00) 都指向第一个页表 
    ; 768 * 4 Bytes -> 0xc00 (物理地址)
    ; 0 ~ 4 MB 包含 1 MB 空间
    ; 由于仅使用一个页表 4MB 所以管理的空间为 [0xc0000000, 0xc03fffff]
    ; 这是为将地址映射为内核地址做准备
    mov [PAGE_DIR_BASE_ADDR_IN_MEM + 0x0],   eax
    mov [PAGE_DIR_BASE_ADDR_IN_MEM + 0xc00], eax
    ; 将目录页表项的最后一个 PDE 指向自己
    sub eax,                                 0x1000
    mov [PAGE_DIR_BASE_ADDR_IN_MEM + 4092],  eax

; 创建页表项 (PTE) 该 PTE 需要映射到物理内存的 0 ~ 1MB
    ; 1MB（所需） / 4KB（页） = 256 个
    mov ecx, 256
    ; 从 0 开始
    xor edx, edx
    xor esi, esi
    or  edx, PAGE_P | PAGE_RW_W | PAGE_US_U
.create_pte_loop:
    mov  [ebx + esi * 4], edx
    ; 4 KB 页面
    add  edx,             4096
    inc  esi
    loop .create_pte_loop

; 补充内核所需其他页表到页目录表中 769 ~ 1022 最后一个已经指向了第一个
    mov eax, PAGE_DIR_BASE_ADDR_IN_MEM
    ; 将后续内核所需的页表接在第一个页表之后(虽然可能用不到)
    add eax, 0x2000
    or  eax, PAGE_P | PAGE_RW_W | PAGE_US_U
    mov ebx, PAGE_DIR_BASE_ADDR_IN_MEM
    mov ecx, 254
    mov esi, 769
.create_pde_for_kernal_loop:
    mov  [ebx + esi * 4], eax
    ; 一个页表的地址跨度就是 4MB
    add  eax,             0x1000
    inc  esi
    loop .create_pde_for_kernal_loop
    ret



