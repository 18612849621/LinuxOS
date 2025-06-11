section mbr vstart=0x7c00

mov     word[func_addr], test_func
call    [func_addr]
mov     ax,              func_addr
call    ax
jmp     $
func_addr dd 4
test_func:
    mov ax, 0x1234
ret


times 510 - ($ - $$) db 0
dw 0xaa55