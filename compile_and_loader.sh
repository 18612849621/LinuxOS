#!/bin/bash
# 定义构建参数变量
OUTPUT_IMG="hd60.img"
BLOCK_SIZE=512
VERSION=v1.0.3

# mbr load 到磁盘的第 1 个扇区
nasm -o code/$VERSION/boot/mbr.bin code/$VERSION/boot/mbr.S
dd if=code/$VERSION/boot/mbr.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=1 conv=notrunc
# loader load 到磁盘的第 3 个扇区
nasm -o code/$VERSION/boot/loader.bin code/$VERSION/boot/loader.S
dd if=code/$VERSION/boot/loader.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=4 seek=2 conv=notrunc
# kernel load 到磁盘的第 10 个扇区
x86_64-elf-gcc code/$VERSION/kernel/main.c -c -o code/$VERSION/kernel/main.o -m32
# -Text 0xc0001500 指定代码初始执行的虚拟地址 [规约]
# -e main 指定 main 作为程序入口 绑定到虚拟地址 0xc0001500
x86_64-elf-ld code/$VERSION/kernel/main.o -Ttext 0xc0001500 -e main -o code/$VERSION/kernel/kernel.bin -m elf_i386

dd if=code/$VERSION/kernel/kernel.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=200 seek=9 conv=notrunc
