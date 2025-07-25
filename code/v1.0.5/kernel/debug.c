#include "debug.h"
#include "interrupt.h"
#include "print.h"
void panic_spin(char *filename, int line, const char *func,
                const char *condition) {
  // 因为有时候会单独调用 panic_spin, 所以在此处关中断
  // 防止一直弹中断信息
  intr_set_status(INTR_OFF);
  put_str("\n\n\n!!!!! error !!!!!\n");
  put_str("filename:");
  put_str(filename);
  put_str("\n");
  put_str("line:0x");
  put_int(line);
  put_str("\n");
  put_str("function:");
  put_str((char *)func);
  put_str("\n");
  put_str("condition:");
  put_str((char *)condition);
  put_str("\n");
  while (1)
    ;
}