section mbr vstart=0x7c00
jmp near start
times 128 db 0
start:
    mov ax, 0x1234
    jmp $
times 510-($-$$) db 0
dw 0xaa55