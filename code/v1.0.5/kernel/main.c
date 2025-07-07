#include "debug.h"
#include "init.h"
#include "interrupt.h"
#include "kernel/print.h"
int main(void) {
  put_str("I am kernel\n");
  init_all();
  // 之前因为刚进入保护模式没有 idt table 无法处理中断关闭，初始化后可以支持
  // 通过 sti 打开所有中断
  intr_set_status(INTR_ON);
    ASSERT(1 == 2);
  while (1)
    ;
  return 0;
}