section mbr vstart=0x7c00
jmp short start
times 127 db 0
start:
    mov ax, 0x1234
    jmp $
times 510-($-$$) db 0
dw 0xaa55