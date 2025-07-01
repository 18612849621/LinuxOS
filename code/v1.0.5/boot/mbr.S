;主引导程序
%include "code/v1.0.5/boot/boot.inc"
;---------------------------------
SECTION MBR vstart=0x7c00
    mov ax, cs
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov fs, ax
    mov sp, 0x7c00
    mov ax, 0xb800
    mov gs, ax

;清屏利用 0x06号功能，上卷全部行，则可清屏。
;---------------------------------
; INT 0x10
; 功能号：0x06
; 功能描述：上卷全部行
;---------------------------------
; 输入
; AH = 0x06
; AL = 上卷行数
; BH = 上卷行属性
; (CL, CH) = 窗口左上角的（X, Y）坐标
; (DL, DH) = 窗口右下角的（X, Y）坐标
; 无返回值;
    mov ax, 0x0600
    mov bx, 0x0700
    mov cx, 0      ;窗口左上角坐标(0, 0)
    mov dx, 0x184f ;窗口右下角坐标(80, 25)
                    ;VGA文本模式中，一行只能容纳80个字符, 共25行。下标从0开始,所以0x18=24 , 0x4f = 79 小端序存储
    int 0x10 ;调用BIOS中断0x10
; 输出背景色绿色，前景色红色，并且跳动的字符串 "1 MBR"
; 0xA4 A 表示绿色背景闪烁，4 表示前景色为红色
; 低 -> 高 ascii(8 bit) B G R I B G R K [小端]
; 高 -> 低 K R G B I R G B(8 bit) | ascii(8 bit) [大端]
; 0x10100100
    mov byte [gs:0x00], '1'
    mov byte [gs:0x01], 0xA4
    mov byte [gs:0x02], ' '
    mov byte [gs:0x03], 0xA4
    mov byte [gs:0x04], 'M'
    mov byte [gs:0x05], 0xA4
    mov byte [gs:0x06], 'B'
    mov byte [gs:0x07], 0xA4
    mov byte [gs:0x08], 'R'
    mov byte [gs:0x09], 0xA4

    mov  eax, LOADER_START_SECTOR_INDEX_IN_DISK
    mov  bx,  LOADER_BASE_ADDR_IN_MEM
    mov  cx,  LOADER_READ_SECTOR_NUM
    call rd_disk_m_16
    ; 程序加载好了 准备执行
    jmp  LOADER_BASE_ADDR_IN_MEM + 0x300
; -------------------------------------
;   读取磁盘的第n个扇区
;   eax = LBA扇区号
;   bx = 将数据写入的内存地址 
;   cx = 读入的扇区数
; -------------------------------------
rd_disk_m_16:
; 选择指定通道的 set sector count 寄存器 设置读取扇区数
    mov esi, eax
    mov dx,  0x1f2
    mov al,  cl
    out dx,  al
    mov eax, esi
; LBA 寄存器(28 bit) 确定扇区地址 LOADER_START_SECTOR_INDEX_IN_DISK 此处为 0x2 其实后面用不到
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
; 根据 device 寄存器的设置 高 4 位的二进制码为 1110
    or  al, 0xe0
    out dx, al
; 写入端口  0x1f7 设置 commend 寄存器 读取扇区命令
    mov dx, 0x1f7
    mov al, 0x20
    out dx, al
; 同步循环阻塞检测数据是否写完, 检查status寄存器(0x1f7) 
    ; dx此时端口为0x1f7 nop 跑 1 clock 的空命令
    ; status寄存器 jnz 如果cmp的条件不满足(标志寄存器喂0)则跳转
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
    in   ax,   dx
    mov  [bx], ax
    add  bx,   2
    loop .loop_read
; func end
    ret
   
    times 510-($-$$) db 0
    db                  0x55, 0xaa

