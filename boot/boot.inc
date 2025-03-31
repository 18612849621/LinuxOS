; -------- loader & kernel --------
; loader内容从存储盘的第二个扇区开始读
LOADER_START_SECTOR_ADDR_IN_DISK equ 0x2
; loader加载到内存的基地址 mbr的启动地址是0x7c00
LOADER_BASE_ADDR_IN_MEM equ 0x900
; loader准备读入的扇区数目
LOADER_READ_SECTOR_NUM equ 1
