/**************	 机器模式   ***************
         b -- 输出寄存器QImode名称,即寄存器中的最低8位:[a-d]l。
         w -- 输出寄存器HImode名称,即寄存器中2个字节的部分,如[a-d]x。

         HImode
             “Half-Integer”模式，表示一个两字节的整数。
         QImode
             “Quarter-Integer”模式，表示一个一字节的整数。
*******************************************/
#ifndef __LIB_KERNEL_IO_H
#define __LIB_KERNEL_IO_H
#include "stdint.h"
/* 向端口port写入一个字节*/
static inline void outb(uint16_t port, uint8_t data) {
  /*********************************************************a表示用寄存器 al 或
  ax 或 eax,对端口指定 N 表示 0~255, d 表示用 dx 存储端口号, %b0 表示对应 al,
  %w1 表示对应 dx */
  asm volatile("outb %b0, %w1" : : "a"(data), "Nd"(port));
  /*********************************************************/
}

/* 将addr处起始的word_cnt个字写入端口port */
static inline void outsw(uint16_t port, const void *addr, uint32_t word_cnt) {
  /*********************************************************
    + 表示此限制即做输入又做输出.
    outsw 是把 ds:esi 处的16位的内容写入 port 端口, 我们在设置段描述符时,
    已经将 ds, es, ss段的选择子都设置为相同的值了,此时不用担心数据错乱。*/
  asm volatile("cld; rep outsw" : "+S"(addr), "+c"(word_cnt) : "d"(port));
}

/* 将从端口port读入的一个字节(8 bit)返回 */
static inline uint8_t inb(uint16_t port) {
  uint8_t data;
  asm volatile("inb %w1, %b0" : "=a"(data) : "Nd"(port));
  return data;
}

/* 将从端口port读入的word_cnt个字写入addr */
static inline void insw(uint16_t port, const void *addr, uint32_t word_cnt) {
  /*********************************************************
   insw 是将从端口 port 处读入的16位内容写入 es:edi 指向的内存,
   我们在设置段描述符时, 已经将 ds, es, ss 段的选择子都设置为相同的值了,
   此时不用担心数据错乱。D 是 di S 是 si*/
  asm volatile("cld; rep insw"
               : "+D"(addr), "+c"(word_cnt)
               : "d"(port)
               : "memory");
}
#endif