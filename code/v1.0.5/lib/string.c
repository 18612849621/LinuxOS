#include "string.h"
#include "debug.h"
#include "global.h"

/* 将dst_起始的size个字节置为value */
void memset(void *dst_, uint8_t value, uint32_t size) {
  ASSERT(dst_ != NULL);
  uint8_t *dst = (uint8_t *)dst_;
  while (size-- > 0) {
    *dst++ = value;
  }
}

/* 将 src_ 起始的 size 个字节复制到 dst_ */
void memcpy(void *dst_, const void *src_, uint32_t size) {
  ASSERT(dst_ != NULL && src_ != NULL);
  uint8_t *dst = (uint8_t *)dst_;
  // 记住 const 小妙招 const 看左边
  const uint8_t *src = (const uint8_t *)src_;
  while (size-- > 0) {
    *dst++ = *src++;
  }
}

/* 连续比较以地址a_和地址b_开头的size个字节,若相等则返回0,若a_大于b_返回+1,否则返回-1
 */
int memcmp(const void *a_, const void *b_, uint32_t size) {
  const char *a = a_;
  const char *b = b_;
  ASSERT(a != NULL || b != NULL);
  while (size-- > 0) {
    if (*a != *b) {
      return *a > *b ? 1 : -1;
    }
    a++;
    b++;
  }
  return 0;
}
/* 将字符串从 src_ 复制到 dst_, 并返回 dst_ 的开头地址*/
char *strcpy(char *dst_, const char *src_) {
  ASSERT(dst_ != NULL && src_ != NULL);
  char *r = dst_;
  while ((*dst_++ = *src_++))
    ;
  return r;
}

/* 返回字符串长度 */
uint32_t strlen(const char *str) {
  ASSERT(str != NULL);
  const char *p = str;
  while (*p++)
    ;
  return p - str - 1;
}

/* 比较两个字符串,若 a_ 中的字符大于 b_ 中的字符返回 1,相等时返回 0,否则返回 -1.
 */
int8_t strcmp(const char *a, const char *b) {
  ASSERT(a != NULL && b != NULL);
  while (*a != 0 && *a == *b) {
    a++;
    b++;
  }
  /* 如果*a小于*b就返回-1,否则就属于*a大于等于*b的情况。在后面的布尔表达式"*a >
   * *b"中,
   * 若*a大于*b,表达式就等于1,否则就表达式不成立,也就是布尔值为0,恰恰表示*a等于*b
   */
  return *a < *b ? -1 : *a > *b;
}

/* 从左到右查找字符串 str 中首次出现字符 ch 的地址(不是下标, 是地址) */
char *strchr(const char *str, const uint8_t ch) {
  ASSERT(str != NULL);
  while (*str != 0) {
    if (*str == ch) {
      return (char *)str;
    }
    str++;
  }
  return NULL;
}

/* 从后往前查找字符串 str 中首次出现字符 ch 的地址(不是下标, 是地址) */
char *strrchr(const char *str, const uint8_t ch) {
  ASSERT(str != NULL);
  const char *last_char = NULL;
  while (*str != 0) {
    if (*str == ch) {
      last_char = str;
    }
    str++;
  }
  return (char *)last_char;
}

/* 将字符串 src_ 拼接到 dst_ 后,将回拼接的串地址 */
char *strcat(char *dst_, const char *src_) {
  ASSERT(dst_ != NULL && src_ != NULL);
  char *str = dst_;
  while (*str++)
    ;
  str--;
  while ((*str++ = *src_++))
    ;
  return dst_;
}

/* 在字符串 str 中查找指定字符 ch 出现的次数 */
uint32_t strchrs(const char *str, uint8_t ch) {
  ASSERT(str != NULL);
  uint32_t ch_cnt = 0;
  const char *p = str;
  while (*p != 0) {
    if (*p == ch) {
      ch_cnt++;
    }
    p++;
  }
  return ch_cnt;
}