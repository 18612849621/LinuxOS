#include "kernel/print.h"
int main(void) {
  //   put_char(0x08);
  put_char('k');
  put_char('e');
  put_char('r');
  put_char('n');
  put_char('e');
  put_char('l');
  int i = 0;
  for (i = 0; i < 10; i++) {
    put_char('\n');
  }
  put_char('k');
  put_char('e');
  put_char('r');
  put_char('n');
  put_char('e');
  put_char('l');

  while (1)
    ;
  return 0;
}