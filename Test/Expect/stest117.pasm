pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_uscmp
	mov	_var01, #0
	cmp	arg1, #2 wc,wz
 if_e	mov	_var01, #1
	mov	result1, _var01
_uscmp_ret
	ret

result1
	long	0
COG_BSS_START
	fit	496
	org	COG_BSS_START
_var01
	res	1
arg1
	res	1
	fit	496
