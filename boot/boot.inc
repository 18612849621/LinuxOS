; -------- loader & kernel --------
; loader内容从存储盘的第二个扇区开始读
LOADER_START_SECTOR_ADDR_IN_DISK equ 0x2
; loader加载到内存的基地址 mbr的启动地址是0x7c00
LOADER_BASE_ADDR_IN_MEM          equ 0x900
; loader准备读入的扇区数目
LOADER_READ_SECTOR_NUM           equ 4
; -------- gdt 描述符属性 --------
    ; 位的索引是从 0 开始 即第 1 位是 0
    ; 高23位(G) 两种模式 字节 / 4KB 此处设置为4KB
    DESC_G_4K equ 00_0000001000_0000000000_0000000000b