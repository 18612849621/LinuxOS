#ifndef __KERNEL_DEBUG_H
#define __KERNEL_DEBUG_H
void panic_spin(char *filename, int line, const char *func,
                const char *condition);
/***************************  __VA_ARGS__  *******************************
 * __VA_ARGS__ 是预处理器所支持的专用标识符。
 * 代表所有与省略号相对应的参数.
 * "..."表示定义的宏其参数可变.
 参数的还有__FILE__，__LINE__,
 __func__，这三个是预定义的宏，分别表示被编译的文件名、被编译文件中的行号、被编译的函数名
 */
#define PANIC(...) panic_spin(__FILE__, __LINE__, __func__, __VA_ARGS__)
/***********************************************************************/
#ifdef DEBUG
#define ASSERT(CONDITION)                                                      \
  if (CONDITION) {                                                             \
  } else {                                                                     \
    /* 符号#让编译器将宏的参数转化为字符串字面量 */        \
    PANIC(#CONDITION);                                                         \
  }
#else
#define ASSERT(CONDITION) ((void)0)
#endif /*__DEBUG */
#endif /*__KERNEL_DEBUG_H*/