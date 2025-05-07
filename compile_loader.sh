set -x
nasm -o boot/loader.bin boot/loader.S
dd if=boot/loader.bin of=hd60.img bs=512 count=4 seek=2 conv=notrunc