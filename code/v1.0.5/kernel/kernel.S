[bits 32]
; 相关的异常中 cpu 已经自动压入了错误码, 为保持栈中格式统一, 这里不做操作
%define ERROR_CODE nop
; 相关的异常中 cpu 没有压入错误码, 为了统一栈中格式, 就手工压入一个 0
%define ZERO       push 0

; ;idt_table 是 C 中注册的中断处理程序数组
extern  idt_table

section .data

global  intr_entry_table
; 全局符号，用于存储所有中断入口地址的数组（由宏生成）
intr_entry_table:
%macro VECTOR 2
section .text
; 每个中断处理程序都要压入中断向量号,所以一个中断类型一个中断处理程序，自己知道自己的中断向量号是多少
intr%1entry:
    %2
    push ds
    push es
    push fs
    push gs
    pushad
    ; 传入 8 bit 中断号
    push %1
    ; 调用idt_table中的 C 版本中断处理函数
    call [idt_table + %1 * 4]
    jmp  intr_exit

section .data
    ; 制作 intr_entry_table 数组 存储中断程序
    dd intr%1entry
%endmacro

section .text
global  intr_exit
intr_exit:
    add esp,  4    ; 弹出入参数
    ; 中段程序处理完成发送 EOI
    ; EOI 中断处理结束标志会清除状态
    ; 如果是从片上进入的中断, 除了往从片上发送 EOI 外,还要往主片上发送 EOI 
    ; 所以简化每次都发送 EOI(0x20) 手动模式 8259A 主片 0x20 从片 0xA0
    mov al,   0x20
    out 0x20, al
    out 0xa0, al
    ; 恢复现场
    popad
    pop gs
    pop fs
    pop es
    pop ds
    ; 跨过error_code 对应 %2 的数据
    add esp,  4
    iretd

VECTOR 0x00, ZERO
VECTOR 0x01, ZERO
VECTOR 0x02, ZERO
VECTOR 0x03, ZERO
VECTOR 0x04, ZERO
VECTOR 0x05, ZERO
VECTOR 0x06, ZERO
VECTOR 0x07, ZERO
VECTOR 0x08, ERROR_CODE
VECTOR 0x09, ZERO
VECTOR 0x0a, ERROR_CODE
VECTOR 0x0b, ERROR_CODE
VECTOR 0x0c, ZERO
VECTOR 0x0d, ERROR_CODE
VECTOR 0x0e, ERROR_CODE
VECTOR 0x0f, ZERO
VECTOR 0x10, ZERO
VECTOR 0x11, ERROR_CODE
VECTOR 0x12, ZERO
VECTOR 0x13, ZERO
VECTOR 0x14, ZERO
VECTOR 0x15, ZERO
VECTOR 0x16, ZERO
VECTOR 0x17, ZERO
VECTOR 0x18, ERROR_CODE
VECTOR 0x19, ZERO
VECTOR 0x1a, ERROR_CODE
VECTOR 0x1b, ERROR_CODE
VECTOR 0x1c, ZERO
VECTOR 0x1d, ERROR_CODE
VECTOR 0x1e, ERROR_CODE
VECTOR 0x1f, ZERO
VECTOR 0x20, ZERO