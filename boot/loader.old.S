%include "boot/boot.inc"
section loader vstart=LOADER_BASE_ADDR_IN_MEM

mov     byte [gs:0x00], '2'
mov     byte [gs:0x01], 0xA4
mov     byte [gs:0x02], ' '
mov     byte [gs:0x03], 0xA4
mov     byte [gs:0x04], 'P'
mov     byte [gs:0x05], 0xA4
mov     byte [gs:0x06], 'Y'
mov     byte [gs:0x07], 0xA4
mov     byte [gs:0x08], 'C'
mov     byte [gs:0x09], 0xA4

jmp     $