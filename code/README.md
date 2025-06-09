# 版本日志
- v1.0.0 
  - mbr + loader 
  - 保护模式开启打印字符
- v1.0.1
  - 物理内存容量检测
- v1.0.2
  - 保护模式 + 分页

# 记录内核启动脚本
工作路径为 /Users/panyuchen/Desktop/Projects/LinuxOS

## 1 complie 
```shell
# mbr
nasm -o boot/mbr.bin boot/mbr.S 
# loader
nasm -o boot/loader.bin boot/loader.S 
```
## 2 load 数据到磁盘
```shell
# mbr
dd if=boot/mbr.bin of=hd60.img bs=512 count=1 conv=notrunc
# loader
dd if=boot/loader.bin of=hd60.img bs=512 count=4 seek=2 conv=notrunc
# loader 清理无用
dd if=/dev/zero of=hd60.img bs=512 count=4 seek=2 conv=notrunc

# 查看数据是否load
# mbr
xxd -l 512 hd60.img
# loader
xxd -s 1024 -l 1024 hd60.img
```

## 3 boch 调试

```shell
# 需要配置好环境
alias bochsd="bochs -debugger"
```
### 3.1 start & prepare
```shell
bochsd -f bochsrc.conf
```

### 3.2 常用命令

```shell
q 退出
b 添加地址断电
c 持续执行直到断点
trace on 启动汇编内容的打印
单步执行
s 遇到循环，则进入该命令在单步执行向显存写数据时，显存会刷新，但屏幕显示不会刷新
n 遇到循环，则跳过该命令在单步执行向显存写数据时，显存会刷新，屏幕显示也会刷新
```