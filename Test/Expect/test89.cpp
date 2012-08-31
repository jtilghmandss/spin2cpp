#include <propeller.h>
#include "test89.h"

#ifdef __GNUC__
#define INLINE__ static inline
#define PostEffect__(X, Y) __extension__({ int32_t tmp__ = (X); (X) = (Y); tmp__; })
#else
#define INLINE__ static
INLINE__ int32_t PostFunc__(int32_t *x, int32_t y) { int32_t t = *x; *x = y; return t; }
#define PostEffect__(X, Y) PostFunc__(&(X), (Y))
#endif

int32_t test89::Catchlong(int32_t Longvar)
{
  int32_t _parm__0000[1];
  int32_t result = 0;
  _parm__0000[0] = Longvar;
  B0 = ((uint8_t *)(int32_t)(&_parm__0000[0]))[0];
  B1 = ((uint8_t *)(int32_t)(&_parm__0000[0]))[1];
  B2 = ((uint8_t *)(int32_t)(&_parm__0000[0]))[2];
  B3 = ((uint8_t *)(int32_t)(&_parm__0000[0]))[3];
  return result;
}
