section mbr vstart=0x7c00
call    far [addr]
jmp     $
addr dw far_proc, 0
far_proc:
    mov ax, 4
    retf
times 510 - ($ - $$) db 0
magic_number db 0x55, 0xaa