pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_select
	cmp	arg1, #0 wz
 if_ne	mov	_var01, arg2
 if_e	add	arg3, #2
 if_e	mov	_var01, arg3
	mov	result1, _var01
_select_ret
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
arg2
	res	1
arg3
	res	1
	fit	496
