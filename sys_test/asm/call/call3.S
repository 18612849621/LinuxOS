section mbr vstart=0x7c00
call    0:far_proc
jmp     $
far_proc:
    mov ax, 4
    retf
times    510-($-$$) db 0
dw                     0xaa55