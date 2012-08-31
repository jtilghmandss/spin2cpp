#include <propeller.h>
#include "test88.h"

#ifdef __GNUC__
#define INLINE__ static inline
#define PostEffect__(X, Y) __extension__({ int32_t tmp__ = (X); (X) = (Y); tmp__; })
#else
#define INLINE__ static
INLINE__ int32_t PostFunc__(int32_t *x, int32_t y) { int32_t t = *x; *x = y; return t; }
#define PostEffect__(X, Y) PostFunc__(&(X), (Y))
#endif

int32_t test88::Sum(void)
{
  int32_t	R, X;
  int32_t result = 0;
  R = 0;
  X = 0;
  do {
    R = (R + X);
    X = (X + 1);
  } while (X <= 4);
  return R;
}
