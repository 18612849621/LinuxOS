;主引导程序
%include "boot/boot.inc"
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

    mov  ax, LOADER_START_SECTOR_ADDR_IN_DISK
    mov  bx, LOADER_BASE_ADDR_IN_MEM
    mov  cx, LOADER_READ_SECTOR_NUM
    call rd_disk_m_16
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
    ; LBA 寄存器(28 bit) 确定扇区地址
    ; 配置 LBA 0-7位
    mov dx,  0x1f3
    out dx,  al
    ; 配置 LBA 8-15位 shr(shift right) 右移操作获取高位
    mov dx,  0x1f4
    shr eax, 8
    out dx,  al


    jmp $
    times 510-($-$$) db 0
    db                  0x55, 0xaa

