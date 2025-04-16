# LinuxOS
```shell
# NOTE(panyuchen): 在项目根目录/LinuxOS执行
# compile
nasm -o boot/mbr.bin boot/mbr.S 
# load to fd
dd if=boot/mbr.bin of=sys.img bs=512 count=1 conv=notrunc
# load to hd
## mbr
dd if=boot/mbr.bin of=hd60.img bs=512 count=1 conv=notrunc
## 程序
dd if=boot/mbr.bin of=hd60.img bs=512 count=1 seek=2 conv=notrunc

```
## 基础知识
### commend
#### dd
```shell
dd 中的 conv=notrunc 是不对整体的数据剪裁，仅处理指定扇区
dd if=boot/mbr.bin of=sys.img bs=512 count=1 seek=2 conv=notrunc
seek 是指定第几个扇区 (默认是跳过字节 加上了 bs 就是扇区)
```
#### xxd
```shell
-s 跳跃字节数 -l 当前点开始数多少字节
xxd -l 512 文件名
xxd -s 1024 -l 512 文件名
```
### 硬盘配置

| 参数         | 描述                                      |
|--------------|-------------------------------------------|
| `ata0-master` | 指定硬盘连接到 ATA0 的主端口（主设备）。         |
| `type=disk`   | 表示连接的是硬盘。                           |
| `path`        | 硬盘映像文件的路径。                        |
| `mode=flat`   | 指定硬盘映像的模式，可以是 `flat`（扁平模式）或 `dynamic`（动态模式）。 |
| `cylinders`   | 磁盘的柱面数（Cylinders）。                   |
| `heads`       | 磁盘的磁头数（Heads）。                     |
| `spt`         | 每个轨道的扇区数（Sectors per track）。       |
| 扇区数        | 扇区数 = `cylinders * heads * spt`。        |
| 设备大小      | 设备可访问的总大小: 扇区数 * 扇区大小。      |

## 汇编指南

### in/out 

in 和 out 的数据流动都是右->左 比如 in / out A, B 都是B流向A
其中 in 的时候 B 是端口，out 的时候 A 是端口

### 基础数据类型

| 指令 | 名称               | 描述                      |
|------|--------------------|---------------------------|
| `db` | Define Byte        | 定义字节，通常为 8 位      |
| `dw` | Define Word        | 定义字，通常为 16 位      |
| `dd` | Define Double Word | 定义双字，通常为 32 位    |