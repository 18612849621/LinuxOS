#!/bin/bash
function CheckIfExistsAndCreateDir() {
    # shell 默认都是 global 的参数 除非主动加 local
    local FOLDER_NAME="$1" # 接收目录名作为参数
    if [ ! -d "$FOLDER_NAME" ]; then
        echo "📁目录 $FOLDER_NAME 不存在，正在创建..."
        mkdir -p "$FOLDER_NAME" # 递归创建目录（即使父目录不存在）
        echo "📁目录 $FOLDER_NAME 创建成功！"
    else
        echo "📁目录 $FOLDER_NAME 已存在，无需创建"
    fi
}
