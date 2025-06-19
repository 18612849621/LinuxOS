#include "kernel/print.h"
int main(void) {
  //   put_char('k');
  //   put_char('e');
  //   put_char('r');
  //   put_char('n');
  //   put_char('e');
  //   put_char('l');
  //   put_char('\n');
  //   put_char('1');
  //   put_char('2');
  //   put_char('\b');
  //   put_char('3');
  //   put_str("hello, world!\n");
  //   put_str("kenrel v1.0.4\n");
  put_int(0x000000010);
  put_char('\n');
  put_int(10);
  put_char('\n');
  put_int(0x12345678);
  while (1)
    ;
  return 0;
}