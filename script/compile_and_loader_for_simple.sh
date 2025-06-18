#!/bin/bash
# 导入
COMMON_FUNC_FOLDER=$(dirname $(realpath "$0"))/common
echo $COMMON_FUNC_FOLDER
source $COMMON_FUNC_FOLDER/system.sh
source $COMMON_FUNC_FOLDER/global_config.sh
# 定义构建参数变量
VERSION=v1.0.2

CheckIfExistsAndCreateDir "$BUILD_DIR" # 检查目录是否存在并创建

# =================mbr=================
nasm -o $BUILD_DIR/mbr.bin code/$VERSION/boot/mbr.S
# =================loader=================
nasm -o $BUILD_DIR/loader.bin code/$VERSION/boot/loader.S

if [ "$WRITE_BIN_TO_DISK" = true ]; then
    # ================写入磁盘===============
    # load MBR 到磁盘的第 1 个扇区
    dd if=$BUILD_DIR/mbr.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=1 conv=notrunc
    # load LOADER 到磁盘的第 3 个扇区
    dd if=$BUILD_DIR/loader.bin of=resources/$OUTPUT_IMG bs=$BLOCK_SIZE count=4 seek=2 conv=notrunc
else
    echo "⚠️ 不写入磁盘💿"
fi
