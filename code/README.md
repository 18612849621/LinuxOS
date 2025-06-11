# 版本日志
- v1.0.0 
  - mbr + loader 
  - 保护模式开启打印字符
- v1.0.1
  - 物理内存容量检测
- v1.0.2
  - 保护模式 + 分页
- v1.0.3
  - 内核加载

# 记录内核启动脚本
hd60.img 磁盘使用(按照最新版本说明)

(512 Bytes per sector)

loader 预留 2 KB 的空间

kernel 预留 100 KB 的空间 

| 磁盘扇区索引 |  内容  |
| :----------: | :----: |
|      0       |  mbr   |
|      1       |        |
|      2       | loader |
|      3       | loader |
|      4       | loader |
|      5       | loader |
|      6       |        |
|      7       |        |
|      8       |        |
|      9       | kernel |
|     ...      |        |
|     208      | kernel |
## boch 调试

```shell
# 需要配置好环境
alias bochsd="bochs -debugger"
```
### 1.1 start & prepare
```shell
bochsd -f bochsrc.conf
```

### 1.2 常用命令

```shell
q 退出
b 添加地址断电
c 持续执行直到断点
trace on 启动汇编内容的打印
单步执行
s 遇到循环，则进入该命令在单步执行向显存写数据时，显存会刷新，但屏幕显示不会刷新
n 遇到循环，则跳过该命令在单步执行向显存写数据时，显存会刷新，屏幕显示也会刷新
```