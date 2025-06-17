%include "code/v1.0.4/boot/boot.inc"
section loader vstart=LOADER_BASE_ADDR_IN_MEM
; 为什么当初设置 LOADER_STACK_TOP_ADDR 为 LOADER_BASE_ADDR_IN_MEM
; 因为在 loader.S 中，栈的使用是从高地址向低地址增长的
; 与LOADER的逻辑完全不会碰撞 他是从低地址向高地址生长
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
    cli
    ;int 0x15 eax= 0x0000E820, edx=0x534d4150 ("SMAP') 获取内存布局
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
;     ; 存储最大值 到 0xb00 用 xp /w 0xb00 应该为 0x02000000 [32 MB]
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

; ----------kernel load mem-----------
mov  eax,                    KERNEL_START_SECTOR_INDEX_IN_DISK
mov  ebx,                    KERNEL_BASE_ADDR_IN_MEM
mov  ecx,                    KERNEL_READ_SECTOR_NUM

; 从硬盘读取 kernel 到内存
call rd_disk_m_32

; ----------页表映射初始化------------
call setup_page
; reload gdt_ptr 寄存器的结果 重新获取 gdt 从而实现更新映射
sgdt [gdt_ptr]
; 获取 GDT 表的存储位置 GDT界限在0 ~ 2 bytes处 所以要 +2 获取 addr
mov  ebx,                    [gdt_ptr + 2]
; dword 4 bytes 因为开启了分页 + 保护模式 所以需要偏移到真实的内核空间
; 视频段是第 3 个段描述符，每个描述符是 8 字节，故 0x18 = 24
; 段描述符的高 32 bit 包含段基址的高 31 ~ 24 位
; 0xc0000000 是 3 GB 的 start addr
; ebx + 0x18 + 4 是修改 gdt 表中视频段描述符的高位基地址
or   dword [ebx + 0x18 + 4], 0xc0000000
; 更新 gdt 表地址 可以用高位空间存表 并且通过分页映射到对应物理地址
add  dword [gdt_ptr + 2],    0xc0000000
; 栈基地址
add  esp,                    0xc0000000
; 完成所有基础地址的偏移
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
; 原作者描述由于一直处在32位下原则上不需要强制刷新
; 经过实际测试没有以下这两句也没问题
; 但以防万一，还是加上啦，免得将来出来莫句奇妙的问题
;强制刷新流水线更新gdt
jmp  SELECTOR_CODE:enter_kernel
enter_kernel:    
   ; 根据 ELF 的信息 将内核放入到正确的线性地址中
   ; 则可以通过程序入口 0xc0001500 去执行内核代码
   call kernel_load_by_elf
   ; 栈是从高地址->低地址增长的
   ; 可用的空间最大为 0xc009fc00 根据原作者为了后续 pcb 定义 4KB(0xfff)对齐
   ; 所以定义栈底空间为 0xc009f000 方便对齐
   mov  esp, 0xc009f000
   ; kernel 逻辑进入地址 0xc0001500 通过页表映射回到 0x1500 物理地址
   jmp  KERNEL_ENTRY_POINT
sti

; -------------页表初始化例程---------------
; 主要将 768 ~ 1022 的页目录项映射对应的空间
; 768 指向第一个页表 后续递增 4KB (0x1000)
; 最后一个页目录指向自己 这样可以通过访问最后一个内存块去操作页目录本身(本身也会参与到分页中)
; 预期总计只使用 1MB
; 页目录 at PAGE_DIR_BASE_ADDR_IN_MEM=0x100000
setup_page:
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

; -------------------------------------
;   从磁盘的第 n 个扇区开始顺序读取 ecx 个扇区到内存 ebx处 [32位]
;   eax = LBA扇区号
;   ebx = 将数据写入的内存地址 
;   ecx = 读入的扇区数
; -------------------------------------
rd_disk_m_32:
    ; 选择指定通道的 set sector count 寄存器 设置读取扇区数
    mov esi, eax
    mov dx,  0x1f2
    mov al,  cl
    out dx,  al
    mov eax, esi

; LBA 寄存器(28 bit) 确定扇区地址 KERNEL_START_SECTOR_INDEX_IN_DISK 此处为 0x9
; 写入端口 0x1f3 配置 LBA 0-7位 (8 bit)
    mov dx, 0x1f3
    out dx, al
; 写入端口 0x1f4 配置 LBA 8-15位 (8 bit) shr(shift right) 右移操作获取高位
    mov dx,  0x1f4
    shr eax, 8
    out dx,  al
; 写入端口 0x1f5 配置 LBA 16-23位 (8 bit)
    mov dx,  0x1f5
    shr eax, 8
    out dx,  al
; 写入端口 0x1f6 设置 device 寄存器的状态 里面包含磁盘寻址模式、LBA的24-27位(4 bit) 地址设置
    mov dx,  0x1f6
    shr eax, 8
    ; 此处筛出 8 bit 中的后 4 位
    and al,  0x0f
; 根据 device 寄存器的设置 高 4 位的二进制码为 1110 表示 LBA 地址模式
    or  al, 0xe0
    out dx, al
    ; 读取扇区命令 写入端口 0x1f7 设置 commend 寄存器
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al
; 同步循环阻塞检测数据是否写完, 检查status寄存器(0x1f7) 
    ; dx此时端口为0x1f7 nop 跑 1 clock 的空命令
    ; status寄存器 jnz 如果cmp的条件不满足(标志寄存器为 0)则跳转
    ; 0 -> ERR  1 表示有错误发生，错误信息见error寄存器
    ; 3 -> DRQ  1 表示硬盘已经准备好数据，随时可以输出
    ; 6 -> DRDY 1 表示设备就绪，等待指令
    ; 7 -> BSY  1 表示硬盘正忙，勿扰
.not_ready:
    nop
    in  al, dx
    ; 要看第4位和第8位做mask 10001000 -> 0x88
    and al, 0x88
    ; 状态码应该是 00001000 -> 0x08
    cmp al, 0x08
    jnz .not_ready
; 开始从 data 寄存器将数据写入到内存中
    ; 磁盘的一个扇区是 512B 一次会读取一个 word (2 Bytes) (16 bit)
    ; 要读取 cx 个扇区 所以是 cx * 512B / 2B == cx * 256 次 -> 存储到di 
    mov ax, 256
    mul cx
    mov cx, ax
    ; 准备好读取次数后开始顺序读取放入到内存中
    mov dx, 0x1f0
    ; data 寄存器的端口好是0x1f0
.loop_read:
    in   ax,    dx
    mov  [ebx], ax
    add  ebx,   2
    ; 由于在实模式下偏移地址为16位,所以用bx只会访问到0~FFFFh的偏移。
    ; 这里用 32 位主要是为了防止我们写的 0x70000 越界导致的循环破坏低地址内存
    ; loader的栈指针为0x900,bx为指向的数据输出缓冲区,且为16位，
    ; 超过0xffff后,bx部分会从0开始,所以当要读取的扇区数过大,待写入的地址超过bx的范围时，
    ; 从硬盘上读出的数据会把0x0000~0xffff的覆盖，
    ; 造成栈被破坏,所以ret返回时,返回地址被破坏了,已经不是之前正确的地址,
    ; 故程序出会错,不知道会跑到哪里去。
    ; 所以改为ebx代替bx指向缓冲区,这样生成的机器码前面会有0x66和0x67来反转。
    ; 0X66用于反转默认的操作数大小! 0X67用于反转默认的寻址方式.
    ; cpu处于16位模式时,会理所当然的认为操作数和寻址都是16位,处于32位模式时,
    ; 也会认为要执行的指令是32位.
    ; 当我们在其中任意模式下用了另外模式的寻址方式或操作数大小(姑且认为16位模式用16位字节操作数，
    ; 32位模式下用32字节的操作数)时,编译器会在指令前帮我们加上0x66或0x67，
    ; 临时改变当前cpu模式到另外的模式下.
    ; 假设当前运行在16位模式,遇到0X66时,操作数大小变为32位.
    ; 假设当前运行在32位模式,遇到0X66时,操作数大小变为16位.
    ; 假设当前运行在16位模式,遇到0X67时,寻址方式变为32位寻址
    ; 假设当前运行在32位模式,遇到0X67时,寻址方式变为16位寻址.
    loop .loop_read
    ret

kernel_load_by_elf:
    ; 初始化所有通用寄存器
    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    ; 解析 elf 文件头 并做相应初始化
    ; bx -> 记录 program header 的线性地址
    ; cx -> 记录 program header 的数量
    ; dx -> 记录 program header 的大小
    ; 文件 42 字节处的属性是 e_phentsize (2 Bytes) 表示 program header 大小
    mov dx,  [KERNEL_BASE_ADDR_IN_MEM + 42]
    ; 偏移文件开始部分 28 字节的地方是 e_phoff (4 Bytes), 表示第1个 program header在文件中的偏移量
    mov ebx, [KERNEL_BASE_ADDR_IN_MEM + 28]
    add ebx, KERNEL_BASE_ADDR_IN_MEM
    ; 偏移文件开始部分 44 字节的地方是 e_phnum (2 Bytes),表示有几个 program header
    mov cx,  [KERNEL_BASE_ADDR_IN_MEM + 44]
.scan_each_program_segment:
    ; 类型不对则直接跳过
    cmp  byte [ebx + 0], PT_NULL
    ; JE 和 JZ 都是判断 ZF 是不是 1 ZF 状态由操作数1 - 操作数2的结果决定
    ; 如果 ZF = 1 则说明操作数1 == 操作数2 即计算结果为 0
    jz   .next_program_header
    ; 当 p_memsz > p_filesz 时​​：
    ; 多出的部分（p_memsz - p_filesz）在文件中​​不占用实际空间​​，但在内存中会被分配并​​初始化为0​​
    ; ​原因​​：ELF 通过此机制支持未初始化数据（.bss节）的高效存储
    ; 为函数 memcpy 压入参数, 参数是从右往左依然压入, 解决变长参数问题，这样可以解析
    ; 函数原型类似于 memcpy(dst, src, size)
    ; ELF 的 program header 信息都是根据文件本身定义的, 相当于给一段二进制定义了 meta
    ; 允许用户去解析 前两个参数确定拷贝的字节量和拷贝的地址 第三个参数决定执行程序在虚拟空间的位置 所以一个进程的虚拟空间只有一个 main 函数 
    ; 是一段逻辑唯一的执行入口 __start = 0xc0001500
    ; 具体的内存编排都是语言编译器帮忙配置
    ; program header 中偏移 16 字节的地方是 p_filesz, 压入函数 memcpy 的第三个参数: size
    push dword [ebx + 16]
    ; program header 中通过 p_offset 进行判断，只是通过 PROGRAM_BASE_ADDR + p_offset 确定基础地址，压入函数 memcpy 的第三个参数: src = PROGRAM_BASE_ADDR + p_offset
    mov  eax,            KERNEL_BASE_ADDR_IN_MEM
    add  eax,            [ebx + 4]
    push eax
    ; program header 中偏移 8 字节的地方是 p_vaddr, 压入函数 memcpy 的第三个参数: dst
    ; p_vaddr 表示程序在内存中的虚拟地址
    push dword [ebx + 8]
    call mem_cpy
     ; 清理栈空间 3 * 4 Bytes = 12 Bytes
    add esp, 12
.next_program_header:
    ; 在 ELF（Executable and Linkable Format）文件格式中，​​所有 program header 的大小是相同的​​，这是由 ELF 规范强制要求的
    add  ebx, edx
    loop .scan_each_program_segment
    ret
;----------  逐字节拷贝 mem_cpy (dst,src,size) ------------
;输入:栈中三个参数 (dst,src,size)
;输出:无
;---------------------------------------------------------
mem_cpy:
    ; cld 是指 clean direction，该指令是将 eflags 寄存器中的方向标志位DF置为0，这样rep在循环执行后面的字符串指令时，[e]si 和[e]di 根据使用的字符串搬运指令，自动加上所搬运数据的字节大小，这是 由CPU自动完成的，不用人工干预。比如执行一次 movsd, [e]si 和 [e]di 就自动加4，执行一次 movsb, [e]si 和 [e]di 就自动加 1。有清除方向标志位就会有设置方向标志位，std 是set direction，该指令是将方向标志位 DF 置为 1，每次rep循环执行后面字符串指令时，[e]si 和[e]di 自动减去所搬运数据的字节大小
    cld
    ; 函数原型 memcpy(dst, src, size)
    ; 保存栈顶地址
    push ebp
    ; 更新栈顶给 ebp 这样可以访问 新的局部变量(+) + 参数(-)
    mov  ebp, esp
    ; 外面用到了 ecx 所以我要保护一下现场
    push ecx
    ; 32 位系统中 call 一个函数会占用 4 个字节的栈空间
    ; 假设所有的参数都是 4 字节则 ebp目前在新的栈顶, 且我们保存了一个 ecx 到栈中
    ; ecx 4 Bytes 则第一个参数 dst 在栈顶 ebp + 8
    ; 所以 dst = ebp + 8 ｜ src = ebp + 12 ｜ size = ebp + 16
    mov  edi, [ebp + 8]  ; dst
    mov  esi, [ebp + 12] ; src
    mov  ecx, [ebp + 16] ; size 
    ; 根据 ecx 逐字节拷贝 ds:[e]si -> es:[e]di
    rep movsb 
    ; 恢复现场
    pop  ecx
    pop  ebp
    ret



