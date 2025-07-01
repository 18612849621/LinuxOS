#!/bin/bash
# 导入
COMMON_FUNC_FOLDER=$(dirname $(realpath "$0"))/common
echo $COMMON_FUNC_FOLDER
source $COMMON_FUNC_FOLDER/system.sh
source $COMMON_FUNC_FOLDER/global_config.sh
# 定义构建参数变量
VERSION=v1.0.5

CheckIfExistsAndCreateDir "$BUILD_DIR" # 检查目录是否存在并创建

# =================mbr=================
nasm -o $BUILD_DIR/mbr.bin code/$VERSION/boot/mbr.S
# =================loader=================
nasm -o $BUILD_DIR/loader.bin code/$VERSION/boot/loader.S
# =================kernel================
## nasm -> o
### print
nasm code/$VERSION/lib/kernel/print.S -f elf32 -o $BUILD_DIR/print.o
### kernel
nasm code/$VERSION/kernel/kernel.S -f elf32 -o $BUILD_DIR/kernel.o
## gcc -> o
### main
x86_64-elf-gcc code/$VERSION/kernel/main.c -I code/$VERSION/lib -I code/$VERSION/kernel -I code/$VERSION/lib/kernel -c -fno-builtin -o $BUILD_DIR/main.o -m32
### interrupt
x86_64-elf-gcc code/$VERSION/kernel/interrupt.c -I code/$VERSION/lib -I code/$VERSION/kernel -I code/$VERSION/lib/kernel -c -fno-builtin -o $BUILD_DIR/interrupt.o -m32
### init
x86_64-elf-gcc code/$VERSION/kernel/init.c -I code/$VERSION/lib -I code/$VERSION/kernel -I code/$VERSION/lib/kernel -c -fno-builtin -o $BUILD_DIR/init.o -m32
## link
x86_64-elf-ld $BUILD_DIR/main.o $BUILD_DIR/print.o $BUILD_DIR/kernel.o $BUILD_DIR/interrupt.o $BUILD_DIR/init.o -Ttext 0xc0001500 -e main -o $BUILD_DIR/kernel.bin -m elf_i386

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
