#!/bin/bash
# 导入
COMMON_FUNC_FOLDER=$(dirname $(realpath "$0"))/common
echo $COMMON_FUNC_FOLDER
source $COMMON_FUNC_FOLDER/system.sh
source $COMMON_FUNC_FOLDER/global_config.sh
# 定义构建参数变量
VERSION=v1.0.4

CheckIfExistsAndCreateDir "$BUILD_DIR" # 检查目录是否存在并创建

# =================mbr=================
nasm -o $BUILD_DIR/mbr.bin code/$VERSION/boot/mbr.S
# =================loader=================
nasm -o $BUILD_DIR/loader.bin code/$VERSION/boot/loader.S
# =================kernel================
## lib 编译
nasm -f elf32 -o $BUILD_DIR/print.o code/$VERSION/lib/kernel/print.S
## main.c 编译
x86_64-elf-gcc code/$VERSION/kernel/main.c -c -o $BUILD_DIR/main.o -m32
## link
### -Text 0xc0001500 指定代码初始执行的虚拟地址 [规约]
### -e main 指定 main 作为程序入口 绑定到虚拟地址 0xc0001500
x86_64-elf-ld $BUILD_DIR/main.o -Ttext 0xc0001500 -e main -o $BUILD_DIR/kernel.bin -m elf_i386

if [ "$WRITE_BIN_TO_DISK" = true ]; then
    # ================写入磁盘===============
    # load MBR 到磁盘的第 1 个扇区
    dd if=$BUILD_DIR/mbr.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=1 conv=notrunc
    # load LOADER 到磁盘的第 3 个扇区
    dd if=$BUILD_DIR/loader.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=4 seek=2 conv=notrunc
    # load KERNEL 到磁盘的第 10 个扇区
    dd if=$BUILD_DIR/kernel.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=200 seek=9 conv=notrunc
else
    echo "⚠️ 不写入磁盘💿"
fi
