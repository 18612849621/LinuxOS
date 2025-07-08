#include "bitmap.h"
#include "debug.h"
#include "interrupt.h"
#include "print.h"
#include "stdint.h"
#include "string.h"

/* 将位图btmp初始化 */
void bitmap_init(struct bitmap *btmp) {
  memset(btmp->bits, 0, btmp->btmp_bytes_len);
}

/* 判断 bit_idx 位是否为 1,若为 1 则返回 true，否则返回 false */
bool bitmap_scan_test(struct bitmap *btmp, uint32_t bit_idx) {
  uint32_t byte_idx = bit_idx / 8; // 向下取整用于索引数组下标
  uint32_t bit_odd = bit_idx % 8;  // 取余用于索引数组内的位
  return (btmp->bits[byte_idx] & (BITMAP_MASK << bit_odd));
}

/* 在位图中申请连续 cnt 个位, 成功则返回其起始位下标，失败返回 -1 */
int bitmap_scan(struct bitmap *btmp, uint32_t cnt) {
  // 用于记录空闲位所在的字节
  uint32_t idx_byte = 0;
  while ((btmp->bits[idx_byte] == 0xff) && (idx_byte < btmp->btmp_bytes_len)) {
    /* 0xff 代表完全满只要不满足就说明有空间*/
    idx_byte++;
  }
  if (idx_byte == btmp->btmp_bytes_len) { // 若该内存池找不到可用空间
    return -1;
  }
  ASSERT(idx_byte < btmp->btmp_bytes_len);
  /* 到此 idx_byte 就是第一个空闲块索引
   * 在该字节内逐位比对,返回空闲位的索引。*/
  // 块内 bit 索引
  int idx_bit = 0;
  /* 和btmp->bits[idx_byte]这个字节逐位对比 */
  // (uint8_t) 这里强转为了防止溢出
  while (btmp->bits[idx_byte] & (uint8_t)(BITMAP_MASK << idx_bit)) {
    idx_bit++;
  }
  // 空闲位在位图内的下标
  int bit_idx_start = idx_byte * 8 + idx_bit;
  if (cnt == 1) {
    return bit_idx_start;
  }

  // 记录还有多少位可以判断
  uint32_t bit_left = (btmp->btmp_bytes_len * 8 - bit_idx_start);
  uint32_t next_bit = bit_idx_start + 1;
  // 记录找到的空闲块个数
  uint32_t count = 1;
  bit_idx_start = -1;
  while (bit_left-- > 0) {
    if (!bitmap_scan_test(btmp, next_bit)) {
      // 如果为 false 返回 0 说明此位空闲可以继续寻找连续 cnt - count 个
      count++;
    } else {
      // 不连续就重新找
      count = 0;
    }
    // 已满足
    if (count == cnt) {
      bit_idx_start = next_bit - cnt + 1;
      break;
    }
    // next_bit 如果满足后就是记录的最后一个块索引
    next_bit++;
  }
  return bit_idx_start;
}
/* 将位图btmp的bit_idx位设置为value */
void bitmap_set(struct bitmap *btmp, uint32_t bit_idx, int8_t value) {
  ASSERT((value == 0) || (value == 1));
  uint32_t byte_idx = bit_idx / 8; // 向下取整用于索引数组下标
  uint32_t bit_odd = bit_idx % 8;  // 取余用于索引数组内的位

  /* 一般都会用个 0x1 这样的数对字节中的位操作,
   * 将 1 任意移动后再取反,或者先取反再移位,可用来对位置 0 操作。*/
  if (value) {
    // value 为 1 用 or 可以置 1
    btmp->bits[byte_idx] |= (BITMAP_MASK << bit_odd);
  } else {
    // value 为 0 用 and 可以置 0
    btmp->bits[byte_idx] &= ~(BITMAP_MASK << bit_odd);
  }
}