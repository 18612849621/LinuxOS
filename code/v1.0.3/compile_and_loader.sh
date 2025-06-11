#!/bin/bash
# 定义构建参数变量
OUTPUT_IMG="hd60.img"
BLOCK_SIZE=512
SECTOR_COUNT=4
SEEK_VALUE=2

# mbr load 到磁盘的第一个扇区
nasm -o code/v1.0.3/boot/mbr.bin code/v1.0.3/boot/mbr.S
dd if=code/v1.0.3/boot/mbr.bin of=$OUTPUT_IMG bs=$BLOCK_SIZE count=1 conv=notrunc
# loader load 到磁盘的第3个扇区
nasm -o code/v1.0.3/boot/loader.bin code/v1.0.3/boot/loader.S
dd if=code/v1.0.3/boot/loader.bin of=$OUTPUT_IMG bs=$BLOCK_SIZE count=$SECTOR_COUNT seek=$SEEK_VALUE conv=notrunc

