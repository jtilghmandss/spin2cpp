''
'' common code for both P1 and P2
''

pri longfill(ptr, val, count)
  repeat count
    long[ptr] := val
    ptr += 4
pri longmove(dst, src, count)
  repeat count
    long[dst] := long[src]
    dst += 4
    src += 4
pri wordfill(ptr, val, count)
  repeat count
    word[ptr] := val
    ptr += 2
pri wordmove(dst, src, count)
  repeat count
    word[dst] := word[src]
    dst += 2
    src += 2
pri bytefill(ptr, val, count)
  repeat count
    byte[ptr] := val
    ptr += 1
pri bytemove(dst, src, count)
  repeat count
    byte[dst] := byte[src]
    dst += 1
    src += 1
pri strsize(str) : r
  r := 0
  repeat while byte[str] <> 0
    r++
    str++
pri strcomp(s1, s2) | c1, c2
  repeat
    c1 := byte[s1++]
    c2 := byte[s2++]
    if (c1 <> c2)
      return 0
  until (c1 == 0)
  return -1
pri _lookup(x, b, arr, n) | i
  i := x - b
  if (i => 0 and i < n)
    return long[arr][i]
  return 0
pri _lookdown(x, b, arr, n) | i
  repeat i from 0 to n-1
    if (long[arr] == x)
      return i+b
    arr += 4
  return 0
pri _lfsr_forward(x) | a
  if (x == 0)
    x := 1
  a := $8000000b
  repeat 32
    asm
      test x, a wc
      rcl  x, #1
    endasm
  return x
pri _lfsr_backward(x) | a
  if (x == 0)
    x := 1
  a := $17
  repeat 32
    asm
      test x, a wc
      rcr  x, #1
    endasm
  return x

dat
rx_method
tx_method
   long 0	'  objptr does not matter
   long 0	' special tag for _tx/_rx function

  '' 8 possible open files
  '' each one has 3 method pointers
  '' sendchar, recvchar, close
  ''
bas_tx_handles
   long @@@tx_method
   long 0[7]
bas_rx_handles
   long @@@rx_method
   long 0[7]
bas_close_handles
   long 0[8]

pri _basic_open(h, sendf, recvf, closef)
  if (h +> 7)
    return
  bas_tx_handles[h] := sendf
  bas_rx_handles[h] := recvf
  bas_close_handles[h] := closef

  
pri _basic_close(h) | ptr, t, f, o
  if (h +> 7)
    return
  t := bas_close_handles[h]
  _basic_open(h,0,0,0)
  if t == 0
    return
  o := long[t]
  f := long[t+4]
  _call_method(o, f, 0)
  
pri _basic_print_char(h, c) | saveobj, t, f, o
  t := bas_tx_handles[h]
  if t == 0
    return
  o := long[t]
  f := long[t+4]
  if f == 0
    _tx(c)
  else
    _call_method(o, f, c)

pri _basic_get_char(h) | t, o, f, saveobj
  t := bas_rx_handles[h]
  if t == 0
    return -1
  o := long[t]
  f := long[t+4]
  if f == 0
    return _rx
  return _call_method(o, f, 0)

pri _basic_print_string(h, ptr, fmt = 0) | c, len, w, justify, wright, wleft
  w := fmt & $ff
  justify := (fmt >> 8) & 3
  len := strsize(ptr)
  wleft := wright := 0
  if (w > 0 and len < w) 
    if justify == 0 ' left justify
      wright := w - len
    elseif justify == 1 ' right justify
      wleft := w - len
    else
      wleft := (w - len)/2
      wright := (w - len) - wleft

    repeat while wleft > 0
      _basic_print_char(h, " ")
      --wleft
  if w == 0
    w := $ffff
  repeat while ((c := byte[ptr++]) <> 0 and w > 0)
    _basic_print_char(h, c)
    --w
  repeat while wright > 0
    _basic_print_char(h, " ")
    --wright
  return

pri _basic_put(h, ptr, siz)|c
  repeat while (siz-- > 0)
    _basic_print_char(h, byte[ptr++])

pri _basic_digit(d)
  return (d < 10) ? d + "0" : (d-10) + "A"

pri _basic_fmt_in_str(u, x, base, mindigits, maxdigits) | digit, i
  if maxdigits == 1
    if x => base
      byte[u] := "*"
    else
      byte[u] := _basic_digit(x)
    return 1

  digit := x +// base
  x := x +/ base
  digit := _basic_digit(digit)
  if (x > 0) or (mindigits > 1)
    if mindigits > 1
      mindigits := mindigits - 1
    i := _basic_fmt_in_str(u, x, base, mindigits, maxdigits-1)
  else
    i := 0
  byte[u + i] := digit
  return i+1
  
pri _basic_fmt_uinteger(ptr, x, base, mindigits, maxdigits, signchar) | u, r
  u := ptr
  if ptr == 0
    return ptr
  if (signchar)
    maxdigits--
    byte[u++] := signchar
    if maxdigits == 0
      byte[u++] := 0
      return ptr
  r := _basic_fmt_in_str(u, x, base, mindigits, maxdigits)
  byte[u+r] := 0
  return ptr
  
pri _basic_print_unsigned(h, x, fmt, base=10) | ptr, mindigits, maxdigits
  maxdigits := fmt & $ff
  mindigits := (fmt>>16) & $1f
  if mindigits == 0
    mindigits := 1
  if maxdigits == 0
     maxdigits := (base < 10) ? 33 : 11
  ptr := __builtin_alloca(maxdigits+1)
  _basic_fmt_uinteger(ptr, x, base, mindigits, maxdigits, 0)
  _basic_print_string(h, ptr, fmt)
  
pri _basic_print_integer(h, x, fmt, base=10) | mindigits, maxdigits, signchar, ptr
  maxdigits := fmt & $ff
  mindigits := (fmt>>16) & $1f
  signchar := (fmt >> 22) & 3
  if mindigits == 0
    mindigits := 1

  if (x < 0)
    signchar := "-"
    x := -x
  else
    if signchar == 1
      signchar := " "
    elseif signchar == 2
      signchar := "+"
    else
      signchar := 0
      
  if maxdigits == 0
    maxdigits := (base < 10) ? 33 : 11
  ptr := __builtin_alloca(maxdigits+1)
  _basic_fmt_uinteger(ptr, x, base, mindigits, maxdigits, signchar)
  _basic_print_string(h, ptr, fmt)
    
pri _basic_print_fixed(h, x, fmt) | i, f
  if (x < 0)
    _basic_print_char(h, "-")
    x := -x
  i := x >> 16
  f := x & $ffff
  ' now i is integer part, f is fractional
  ' round f off: 0.00005 ~= 3 in 16.16
  f := f + 2 
  if (f > $ffff)
    i++
    f -= $10000
  _basic_print_unsigned(h, i, fmt)
  _basic_print_char(h, ".")
  repeat 4
    f := f * 10
    i := f >> 16
    f := f & $ffff
    _basic_print_char(h, i + "0")
  return

pri _basic_print_nl(h)
  _basic_print_char(h, 13)
  _basic_print_char(h, 10)

''
'' fixed point multiply
''
pri _fixed_mul(x, y) | hi, lo
  lo := x * y
  hi := x ** y
  return (hi << 16) | (lo >> 16)

''
'' for divide, we want (x / y) << N, but
'' we have to do it in parts, because
'' probably x<<N will overflow
''
pri _fixed_div(x, y, n) | sign
  sign := (x^y) >> 31
  x := ||x
  y := ||y
  ' figure out how far left we can shift x
  repeat while (x > 0 and n > 0)
    x <<= 1
    --n
  y := y
  x := (x +/ y)
  if (sign)
    x := -x
  return x << n

pri _string_cmp(x, y) | xc, yc, d
  repeat
    xc := byte[x++]
    yc := byte[y++]
    d := xc - yc
  while (d==0) and xc and yc
  return d

pri _string_concat(x, y) | lenx, leny, ptr
  lenx := strsize(x)
  leny := strsize(y)
  ptr := _gc_alloc_managed(lenx + leny + 1)
  if ptr
    bytemove(ptr, x, lenx)
    bytemove(ptr + lenx, y, leny)
    byte[ptr + lenx + leny] := 0
  return ptr

pri chr`$(x=long) | ptr
  ptr := _gc_alloc_managed(2)
  if (ptr)
    byte[ptr+0] := x
    byte[ptr+1] := 0
  return ptr

pri left`$(x, n) | ptr, i, m
  if (n =< 0)
    return ""
  m := strsize(x)
  if (m =< n)
    return x
  ptr := _gc_alloc_managed(n+1)
  if ptr
    bytemove(ptr, x, n)
    byte[ptr+n] := 0
  return ptr
  
pri right`$(x, n) | ptr, i, m
  if (n =< 0)
    return ""
  m := strsize(x)
  if (m =< n)
    return x

  ptr := _gc_alloc_managed(n+1)
  if ptr
    i := m-n
    bytemove(ptr, x+i, n+1)
  return ptr

pri mid`$(x, i=0, j=9999999) | ptr, m, n
  if (j =< 0)
    return ""
  --i ' convert from 1 based to 0 based
  m := strsize(x)
  if (m < i)
    return ""
  ' calculate number of chars we will copy
  n := (m-i)
  n := (n > j) ? j : n
  ptr := _gc_alloc_managed(n+1)
  if ptr
    bytemove(ptr, x+i, n)
    byte[ptr+n] := 0
  return ptr
  
pri val(s) : r | c
  r := 0
  repeat
    c := byte[s++]
    if (c => "0") and (c =< "9")
      r := 10 * r + (c - "0")
    else
      return r
      
pri _make_methodptr(o, func) | ptr
  ptr := _gc_alloc_managed(8)
  if (ptr)
    long[ptr] := o
    long[ptr+4] := func
  return ptr

pri SendRecvDevice(sendf, recvf = 0, closef = 0)
  return (sendf, recvf, closef)

'' read n characters from handle h
pri input`$(n=long, h=0) | c, i, s
  s := _gc_alloc_managed(n+1)
  if s == 0
    return s
  repeat i from 0 to n-1 
    c := _basic_get_char(h)
    if c < 0
      quit
    byte[s+i] := c
  byte[s+i] := 0
  return s

'' pause for m milliseconds
pri pausems(m=long)
  waitcnt(getcnt + m * (clkfreq / 1000))

pri len(s=@byte)
  return strsize(s)
