ROOT_PATH := ../..
BUILD_DIR = $(ROOT_PATH)/build
IMAGE_OUTPUT_DIR = $(ROOT_PATH)/resources/hd60.img
ENTRY_POINT := 0xc0001500
# SECTOR 的大小就是 512 Bytes
BLOCK_SIZE := 512
AS := nasm
CC := x86_64-elf-gcc
LD := x86_64-elf-ld
LIB := -I lib/ -I kernel/ -I device/ -I lib/kernel/
ASFLAGS := -f elf32 # 编译成 x86 架构 32 位 elf
# debug
CFLAGS := -O0 -fno-builtin -c -Wall -m32 -W -Wstrict-prototypes -Wmissing-prototypes -DDEBUG
# online
# CFLAGS := -fno-builtin -c -Wall -m32 -W -Wstrict-prototypes -Wmissing-prototypes
LDFLAGS = -m elf_i386 -Ttext $(ENTRY_POINT) -e main
# 启动所需对象
STARTUP = $(BUILD_DIR)/mbr.bin $(BUILD_DIR)/loader.bin
# Kernel
OBJS = $(BUILD_DIR)/main.o $(BUILD_DIR)/print.o $(BUILD_DIR)/kernel.o $(BUILD_DIR)/interrupt.o $(BUILD_DIR)/init.o $(BUILD_DIR)/timer.o $(BUILD_DIR)/debug.o $(BUILD_DIR)/string.o
# 伪目标声明
.PHONY: build_dir_init clean send_program_to_disk build
# ======================== FUNC ========================
# 初始化 build 目录
build_dir_init:
	@if [ ! -d "$(BUILD_DIR)" ]; then \
	  echo "📁 目录 $(BUILD_DIR) 不存在，正在创建..."; \
	  mkdir -p "$(BUILD_DIR)"; \
	  echo "📁 目录 $(BUILD_DIR) 创建成功！"; \
	else \
	  echo "📁 目录 $(BUILD_DIR) 已存在，跳过创建"; \
	fi
# 清理 build 目录
clean:
	@echo 😴
# 拷贝程序到磁盘
# MBR 到磁盘的第 1 个扇区
# LOADER 到磁盘的第 3 个扇区
# KERNEL 到磁盘的第 10 个扇区
send_program_to_disk:
	@dd if=$(BUILD_DIR)/mbr.bin of=$(IMAGE_OUTPUT_DIR) bs=$(BLOCK_SIZE) count=1 conv=notrunc && \
  dd if=$(BUILD_DIR)/loader.bin of=$(IMAGE_OUTPUT_DIR) bs=$(BLOCK_SIZE) count=4 seek=2 conv=notrunc && \
  dd if=$(BUILD_DIR)/kernel.bin of=$(IMAGE_OUTPUT_DIR) bs=$(BLOCK_SIZE) count=200 seek=9 conv=notrunc
build: $(BUILD_DIR)/kernel.bin
# ======================== 汇编 =========================
# start
$(BUILD_DIR)/mbr.bin: boot/mbr.S
	$(AS) $< -o $@
$(BUILD_DIR)/loader.bin: boot/loader.S
	$(AS) $< -o $@
# kernel
$(BUILD_DIR)/print.o: lib/kernel/print.S
	$(AS) $(ASFLAGS) $< -o $@
$(BUILD_DIR)/kernel.o: kernel/kernel.S
	$(AS) $(ASFLAGS) $< -o $@
# ======================== C =========================
# lib
$(BUILD_DIR)/string.o: lib/string.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@
# device
$(BUILD_DIR)/timer.o: device/timer.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@
# kernel
$(BUILD_DIR)/interrupt.o: kernel/interrupt.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@
$(BUILD_DIR)/init.o: kernel/init.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@
$(BUILD_DIR)/debug.o: kernel/debug.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@
$(BUILD_DIR)/main.o: kernel/main.c
	$(CC) $(LIB) $(CFLAGS) $< -o $@

# ======================== LINK =========================
$(BUILD_DIR)/kernel.bin: $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@
# ======================== MAIN =========================
all: build_dir_init build $(STARTUP) send_program_to_disk
	@echo "✅ Compile done."
