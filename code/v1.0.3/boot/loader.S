%include "code/v1.0.3/boot/boot.inc"
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
; addr 0xc00 上面的 ards_num 为了对齐 让 mbr 可以直接跳转到此地址
loader_start:
;     ;int 0x15 eax= 0x0000E820, edx=0x534d4150 ("SMAP') 获取内存布局
;     xor ebx, ebx
;     mov edx, 0x534d4150
;     mov di,  ards_buffer
; ; 循环获取每个ARDS内存范围描述结构
; .e820_get_mem_loop:
;     mov ecx, 20
;     ; 每轮执行后会刷新 eax 寄存器的值 所以需要重新赋值
;     mov eax, 0x0000E820
;     int 0x15
;     ; jc CF = 1 则跳转
;     jc  .e820_failed_so_try_e801
;     add di,  cx
;     inc word [ards_num]
;     ; ebx 为 0 说明遍历到末尾, cmp 的比较方法就是操作数1(ebx) - 操作数2 (0)
;     cmp ebx, 0
;     ; jnz ZF为 0 (cmp 比较结果不相等) 则跳转
;     jnz .e820_get_mem_loop
;     ; 找到所有ards中最高位的内存地址
;     ; 循环 ards_num 次
;     mov cx,  [ards_num]
;     ; 初始化 ards 第一个位置
;     mov ebx, ards_buffer
;     ; 用 edx 记录最大值
;     xor edx, edx
;     ; 循环遍历所有 ARDS 结构体
;     ; base_add_low + length_low [低 32 位] 因为操作系统是 32 bit
; .find_max_mem_loop:
;     mov eax, [ebx]
;     add eax, [ebx + 8]
;     cmp edx, eax
;     ; jge 操作数1 >= 操作数2 不更新最大值
;     jge .scan_next_ards
;     mov edx, eax
; .scan_next_ards:
;     ; ards 的结构体占用 20 Bytes
;     add  ebx, 20
;     loop .find_max_mem_loop
;     jmp  .mem_get_ok
; ; int 0x15 ax=E801h 获取内存大小最大支持 4G 返回后
; ; ax 和 cx 值一样以 1 KB 为单位 
; ; bx 和 dx 值一样以 64 KB 为单位
; ; ax 和 cx 寄存器表示低 16 MB 其实是 0 - 15 MB 其中 1 MB 给 ISA 设备准备
; ; bx 和 dx 寄存器中为 16 MB 到 4 GB
; .e820_failed_so_try_e801:
;     mov eax, 0xE801
;     int 0x15
;     jc  .e801_failed_so_try_e88
;     ;1 先算出低15M的内存,ax和cx中是以KB为单位的内存数量,将其转换为以byte为单位
;     mov cx,  0x400              ;cx和ax值一样,cx用做乘数
;     mul cx
;     shl edx, 16
;     and eax, 0x0000FFFF
;     or  edx, eax
;     add edx, 0x100000           ;ax只是15MB,故要加1MB
;     mov esi, edx                ;先把低15MB的内存容量存入esi寄存器备份

;     ;2 再将16MB以上的内存转换为byte为单位,寄存器bx和dx中是以64KB为单位的内存数量
;     xor eax, eax
;     mov ax,  bx
;     mov ecx, 0x10000 ;0x10000十进制为64KB
;     mul ecx          ;32位乘法,默认的被乘数是eax,积为64位,高32位存入edx,低32位存入eax.
;     add esi, eax     ;由于此方法只能测出4G以内的内存,故32位eax足够了,edx肯定为0,只加eax便可
;     mov edx, esi     ;edx为总内存大小
;     jmp .mem_get_ok

; .e801_failed_so_try_e88:
;     mov eax, 0xE88
;     int 0x15
;     ;int 15后，ax存入的是以kb为单位的内存容量
;     jc  .error_hlt
;     and eax, 0x0000FFFF
        
;     ;16位乘法，被乘数是ax,积为32位.积的高16位在dx中，积的低16位在ax中
;     mov cx,  0x400    ;0x400等于1024,将ax中的内存容量换为以byte为单位
;     mul cx
;     shl edx, 16       ;把dx移到高16位
;     or  edx, eax      ;把积的低16位组合到edx,为32位的积
;     add edx, 0x100000 ;0x88子功能只会返回1MB以上的内存,故实际内存大小要加上1MB

; .mem_get_ok:
;     ; 存储最大值 到 0xb00 用 xp /w 0xb00
;     mov [total_mem_bytes], edx

;-----------------   准备进入保护模式   -------------------
;1 打开A20
;2 加载gdt
;3 将cr0的pe位置1
    ;-----------------  打开A20  ----------------
    in  al,   0x92
    or  al,   0000_0010B
    out 0x92, al

    ;-----------------  加载GDT  ----------------
    lgdt [gdt_ptr]

    ;-----------------  cr0第0位置1  ----------------
    mov eax, cr0
    or  eax, 0x00000001
    mov cr0, eax

    jmp dword SELECTOR_CODE:p_mode_start
    ; 刷新流水线，避免分支预测的影响,这种cpu优化策略，最怕jmp跳转，
    ; 这将导致之前做的预测失效，从而起到了刷新的作用。
.error_hlt:
    ; 出现错误时直接停止
    hlt

[bits 32]
p_mode_start:
    mov ax,  SELECTOR_DATA
    mov ds,  ax
    mov es,  ax
    mov ss,  ax
    mov esp, LOADER_STACK_TOP_ADDR
    mov ax,  SELECTOR_VIDEO
    mov gs,  ax
    
; ----------页表映射初始化------------
call prepare_page_table
; reload gdt_ptr 寄存器的结果 重新获取 gdt 从而实现更新映射
sgdt [gdt_ptr]
; 获取 GDT 表的存储位置 GDT界限在0 ~ 2 bytes处 所以要 +2 获取 addr
mov  ebx,                    [gdt_ptr + 2]
; dword 4 bytes 因为开启了分页 + 保护模式 所以需要偏移到真实的内核空间
; 视频段是第 3 个段描述符，每个描述符是 8 字节，故 0x18 = 24
; 段描述符的高 4 字节的最高位是段基址的第 31 ~ 24 位
; 0xc0000000 是 3 GB 的 start addr
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
; 重新加载 GDT
lgdt [gdt_ptr]
; 目前是 保护 + 分页 模式
mov  byte [gs:166],          'V'
mov  byte [gs:167],          0xA4

jmp  $




; -------------页表初始化例程---------------
; 主要将 768 ~ 1022 的页目录项映射对应的空间
; 768 指向第一个页表 后续递增 4KB (0x1000)
; 最后一个页目录指向自己 这样可以通过访问最后一个内存块去操作页目录本身(本身也会参与到分页中)
; 预期总计只使用 1MB
; 页目录 at PAGE_DIR_BASE_ADDR_IN_MEM=0x100000
prepare_page_table:
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
    ; 所以将页目录项 0 (0) 和 768 (0xc00) 都指向第一个页表 
    ; 768 * 4 Bytes -> 0xc00 (物理地址)
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
    ; 一个页表的地址跨度就是 4KB
    add  eax,             0x1000
    inc  esi
    loop .create_pde_for_kernal_loop
    ret