pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_strlen2
	mov	_var01, #0
LR__0001
	rdbyte	_var02, arg1 wz
 if_ne	add	arg1, #1
 if_ne	add	_var01, #1
 if_ne	jmp	#LR__0001
	mov	result1, _var01
_strlen2_ret
	ret

result1
	long	0
COG_BSS_START
	fit	496
	org	COG_BSS_START
_var01
	res	1
_var02
	res	1
arg1
	res	1
	fit	496
