section mbr vstart=0x7c00

call    near test_func
jmp     $
var dd 0xffffffff
test_func:
    mov ax, 0x1234
ret


times 510 - ($ - $$) db 0
dw 0xaa55