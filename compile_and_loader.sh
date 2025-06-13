#!/bin/bash
# 定义构建参数变量
OUTPUT_IMG="hd60.img"
BLOCK_SIZE=512
VERSION=v1.0.3

# mbr load 到磁盘的第1个扇区
nasm -o code/$VERSION/boot/mbr.bin code/$VERSION/boot/mbr.S
dd if=code/$VERSION/boot/mbr.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=1 conv=notrunc
# loader load 到磁盘的第3个扇区
nasm -o code/$VERSION/boot/loader.bin code/$VERSION/boot/loader.S
dd if=code/$VERSION/boot/loader.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=4 seek=2 conv=notrunc
# loader load 到磁盘的第10个扇区
nasm -o code/$VERSION/boot/test.bin code/$VERSION/boot/test.S
dd if=code/$VERSION/boot/test.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=200 seek=9 conv=notrunc
