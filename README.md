# LinuxOS
```shell
# NOTE(panyuchen): 在项目根目录/LinuxOS执行
# compile
nasm -o boot/mbr.bin boot/mbr.S 
# load to fd
dd if=boot/mbr.bin of=sys.img bs=512 count=1 conv=notrunc
```
## dd
dd 中的 conv=notrunc 是不对整体的数据剪裁，仅处理指定扇区

## 汇编指南

### in/out 

in 和 out 的数据流动都是右->左 比如 in / out A, B 都是B流向A
其中 in 的时候 B 是端口，out 的时候 A 是端口