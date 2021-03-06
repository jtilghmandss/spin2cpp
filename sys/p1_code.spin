pri waitcnt(x)
  asm
    waitcnt x,#0
  endasm

pri getcnt
  return cnt

pri waitpeq(pin, mask, c = 0)
  asm
    waitpeq pin,mask
  endasm

pri waitpne(pin, mask, c = 0)
  asm
    waitpne pin,mask
  endasm

pri cogid | rval
  asm
    cogid rval
  endasm
  return rval

pri cogstop(id)
  asm
    cogstop id
  endasm
  return 0

pri clkset(mode, freq)
  CLKFREQ := freq
  CLKMODE := mode
  asm
    clkset mode
  endasm

pri reboot
  clkset($80, 0)

pri lockclr(id) | mask, rval
  mask := -1
  asm
    lockclr id wc
    muxc   rval,mask
  endasm
  return rval

pri lockset(id) | mask, rval
  mask := -1
  asm
    lockset id wc
    muxc   rval,mask
  endasm
  return rval

pri locknew | rval
  asm
    locknew rval
  endasm
  return rval

pri lockret(id)
  asm
    lockret id
  endasm
  return 0

pri _coginit(id, code, param) | parm
  parm := (param & $fffc) << 16
  parm |= (code & $fffc) << 2
  parm | = id & $f
  asm
      coginit parm wr, wc
 if_c neg     parm, #1
  endasm
  return parm

pri _sqrt(a) | r, bit, tmp
  if (a =< 0)
    return 0
  r := 0
  bit := (1<<30)
  repeat while (bit > a)
    bit := bit >> 2
  repeat while (bit <> 0)
    tmp := r+bit
    if (a => tmp)
      a := a - tmp
      r := (r >> 1) + bit
    else
      r := r >> 1
    bit := bit >> 2
  return r

con
 _rxpin = 31
 _txpin = 30

dat
_bitcycles long 80_000_000 / 115_200

pri _tx(c) | val, nextcnt, bitcycles
  bitcycles := _bitcycles
  OUTA[_txpin] := 1
  DIRA[_txpin] := 1
  val := (c | 256) << 1
  nextcnt := cnt
  repeat 10
    waitcnt(nextcnt += bitcycles)
    OUTA[_txpin] := val
    val >>= 1

pri _rx | val, rxmask, waitcycles, i, bitcycles
  bitcycles := _bitcycles
  DIRA[_rxpin] := 0
  rxmask := 1<<_rxpin
  waitpeq(0, rxmask)
  waitcycles := cnt + (bitcycles>>1)
  val := 0
  repeat 8
    waitcnt(waitcycles += bitcycles)
    val := (INA[_rxpin] << 7) | (val>>1)
  waitcnt(waitcycles + bitcycles)
  _tx(val)
  return val

pri _setbaud(rate)
  _bitcycles := clkfreq / rate

pri _call_method(o, f, x=0) | r
  asm
    wrlong objptr, sp
    add    sp, #4
    mov    objptr, o
    mov    arg01, x
    call   f
    sub    sp, #4
    rdlong objptr, sp
    mov    r, result1
  endasm
  return r
