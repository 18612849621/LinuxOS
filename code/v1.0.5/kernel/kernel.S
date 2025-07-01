[bits 32]
; 相关的异常中 cpu 已经自动压入了错误码, 为保持栈中格式统一, 这里不做操作
%define ERROR_CODE nop
; 相关的异常中 cpu 没有压入错误码, 为了统一栈中格式, 就手工压入一个 0
%define ZERO       push 0

; 声明函数
extern  put_str

section .data
; 定义字符串常量，包含中断提示信息和换行符 0xa 、终止符 0
intr_str db "interrupt occur!", 0xa, 0
global  intr_entry_table
; 全局符号，用于存储所有中断入口地址的数组（由宏生成）
intr_entry_table:

%macro VECTOR 2
section .text
; 每个中断处理程序都要压入中断向量号,所以一个中断类型一个中断处理程序，自己知道自己的中断向量号是多少
intr%1entry:
    %2
    push intr_str
    call put_str
    add  esp,  4    ; 弹出入参数
    ; EOI 中断处理结束标志 会清除状态
    ; 如果是从片上进入的中断, 除了往从片上发送 EOI 外,还要往主片上发送 EOI 
    ; 所以简化每次都发送 EOI(0x20) 手动模式 8259A 主片 0x20 从片 0xA0
    mov  al,   0x20
    out  0x20, al
    out  0xa0, al
    ; 跨过error_code -- %2
    add  esp,  4
    ; 返回, 32位下等同指令iretd 用于从中断服务程序（ISR）返回到被中断的代码
    iret
section .data
    ; 制作 intr_entry_table 数组 存储中断程序
dd intr%1entry
%endmacro

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