#include "interrupt.h"
#include "global.h"
#include "io.h"
#include "print.h"
#include <stdint.h>

#define PIC_M_CTRL 0x20 // 这里用的可编程中断控制器是8259A,主片的控制端口是0x20
#define PIC_M_DATA 0x21 // 主片的数据端口是0x21
#define PIC_S_CTRL 0xa0 // 从片的控制端口是0xa0
#define PIC_S_DATA 0xa1 // 从片的数据端口是0xa1

#define IDT_DESC_CNT 0x21
// eflags 寄存器中的 if 位为 1 if 在第 10 位
#define EFLAGS_IF 0x00000200
// 用于将 ​​EFLAGS 寄存器​​的当前值压入堆栈
#define GET_EFLAGS(EFLAGS_VAR)                                                 \
  asm volatile("pushfl; popl %0" : "=g"(EFLAGS_VAR))

struct gate_desc {
  uint16_t func_offset_low_word;
  uint16_t selector;
  uint8_t
      dcount; // 此项为双字计数字段，是门描述符中的第4字节。此项固定值，不用考虑
  uint8_t attribute;
  uint16_t func_offset_high_word;
};
// 静态函数声明 非必需
static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr,
                          intr_handler function);
// 中断名字表
char *intr_name[IDT_DESC_CNT];
// idt是中断描述符表, 本质上就是个中断门描述符数组
static struct gate_desc idt[IDT_DESC_CNT];
// 定义中断处理程序数组.在kernel.S中定义的intrXXentry只是中断处理程序的入口,最终调用的是ide_table中的处理程序
intr_handler idt_table[IDT_DESC_CNT];
// 声明引用定义在kernel.S中的中断处理函数入口数组
extern intr_handler intr_entry_table[IDT_DESC_CNT];

static void make_idt_desc(struct gate_desc *p_gdesc, uint8_t attr,
                          intr_handler function) {
  // 32 位系统 获取指针地址就是 void* -> uint32_t
  p_gdesc->func_offset_low_word = (uint32_t)function & 0x0000FFFF;
  p_gdesc->func_offset_high_word = ((uint32_t)function & 0xFFFF0000) >> 16;
  p_gdesc->attribute = attr;
  p_gdesc->dcount = 0;
  p_gdesc->selector = SELECTOR_K_CODE;
}

void pic_init(void) {
  /* 初始化主片 */
  outb(PIC_M_CTRL, 0x11); // ICW1: 边沿触发,级联8259, 需要ICW4.
  outb(PIC_M_DATA,
       0x20); // ICW2: 起始中断向量号为0x20,也就是IR[0-7] 为 0x20 ~ 0x27.
  outb(PIC_M_DATA, 0x04); // ICW3: IR2接从片.
  outb(PIC_M_DATA, 0x01); // ICW4: 8086模式, 正常EOI

  /* 初始化从片 */
  outb(PIC_S_CTRL, 0x11); // ICW1: 边沿触发,级联8259, 需要ICW4.
  outb(PIC_S_DATA,
       0x28); // ICW2: 起始中断向量号为0x28,也就是IR[8-15] 为 0x28 ~ 0x2F.
  outb(PIC_S_DATA, 0x02); // ICW3: 设置从片连接到主片的IR2引脚
  outb(PIC_S_DATA, 0x01); // ICW4: 8086模式, 正常EOI

  /* 打开主片上IR0,也就是目前只接受时钟产生的中断 */
  outb(PIC_M_DATA, 0xfe);
  outb(PIC_S_DATA, 0xff);
  put_str("   pic_init done\n");
}

/*初始化中断描述符表*/
void idt_desc_init(void) {
  int i;
  for (i = 0; i < IDT_DESC_CNT; ++i) {
    make_idt_desc(&idt[i], IDT_DESC_ATTR_DPL0, intr_entry_table[i]);
  }
  put_str("   idt_desc_init done\n");
}

/* 通用的中断处理函数,一般用在异常出现时的处理 */
static void general_init_handler(uint8_t vec_nr) {
  // 0x2f是从片8259A上的最后一个irq引脚，保留
  // IRQ7和IRQ15会产生伪中断(spurious interrupt),无须处理。
  if (vec_nr != 0x20) {
    put_str("int vector: 0x");
    put_int(vec_nr);
    put_char('\n');
    return;
  }
  if (vec_nr == 0x27 || vec_nr == 0x2f) {
    return;
  }
}

/* 完成一般中断处理函数注册及异常名称注册 */
static void exception_init(void) {
  int i;
  for (i = 0; i < IDT_DESC_CNT; ++i) {
    /* idt_table 数组中的函数是在进入中断后根据中断向量号调用的,
     * 见 kernel/kernel.S 的 call [idt_table + %1 * 4] */
    // 这里给个默认方法
    idt_table[i] = general_init_handler;
    intr_name[i] = "unknown";
  }
  intr_name[0] = "#DE Divide Error";
  intr_name[1] = "#DB Debug Exception";
  intr_name[2] = "NMI Interrupt";
  intr_name[3] = "#BP Breakpoint Exception";
  intr_name[4] = "#OF Overflow Exception";
  intr_name[5] = "#BR BOUND Range Exceeded Exception";
  intr_name[6] = "#UD Invalid Opcode Exception";
  intr_name[7] = "#NM Device Not Available Exception";
  intr_name[8] = "#DF Double Fault Exception";
  intr_name[9] = "Coprocessor Segment Overrun";
  intr_name[10] = "#TS Invalid TSS Exception";
  intr_name[11] = "#NP Segment Not Present";
  intr_name[12] = "#SS Stack Fault Exception";
  intr_name[13] = "#GP General Protection Exception";
  intr_name[14] = "#PF Page-Fault Exception";
  // intr_name[15] 第15项是intel保留项，未使用
  intr_name[16] = "#MF x87 FPU Floating-Point Error";
  intr_name[17] = "#AC Alignment Check Exception";
  intr_name[18] = "#MC Machine-Check Exception";
  intr_name[19] = "#XF SIMD Floating-Point Exception";
}

/* 获取当前中断状态 */
enum intr_status intr_get_status(void) {
  uint32_t eflags = 0;
  GET_EFLAGS(eflags);
  return eflags & EFLAGS_IF ? INTR_ON : INTR_OFF;
}
/* 将中断状态设置为status */
enum intr_status intr_set_status(enum intr_status status) {
  return (status & INTR_ON) ? intr_enable() : intr_disable();
}
/* 开中断并返回开中断前的状态*/
enum intr_status intr_enable(void) {
  if (intr_get_status() == INTR_ON) {
    return INTR_ON;
  } else {
    asm volatile("sti" ::: "memory");
    return INTR_OFF;
  }
}
/* 关中断,并且返回关中断前的状态 */
enum intr_status intr_disable(void) {
  if (intr_get_status() == INTR_ON) {
    asm volatile("cli" ::: "memory");
    return INTR_ON;
  } else {
    return INTR_OFF;
  }
}

/*完成有关中断的所有初始化工作*/
void idt_init() {
  put_str("idt_init start\n");
  // 初始化中断描述符表
  idt_desc_init();
  // 异常名初始化并注册通常的中断处理函数
  exception_init();
  // 初始化中断控制器 8259A
  pic_init();
  // 使用内联汇编加载 idt
  // 前 16 位是 IDT 表界限，后32位是 IDT 线性基地址
  // (uint32_t) idt 先获取地址
  // (uint64_t) 再转换64位防止32位左移动溢出
  uint64_t idt_operand = ((sizeof(idt) - 1) | ((uint64_t)(uint32_t)idt << 16));
  asm volatile("lidt %0" ::"m"(idt_operand));
  put_str("idt_init done\n");
}