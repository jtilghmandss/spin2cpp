pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_unpack_x
	mov	arg02, #0
	call	#_dounpack_x
_unpack_x_ret
	ret

_unpack_m
	mov	arg02, #1
	call	#_dounpack_x
_unpack_m_ret
	ret

_dounpack_x
	mov	_var01, arg01
	shl	_var01, #1
	shr	_var01, #24
	mov	_var02, _var01 wz
	and	arg01, imm_8388607_
 if_ne	shl	arg01, #6
 if_ne	or	arg01, imm_536870912_
 if_ne	jmp	#LR__0002
	mov	_var03, arg01
	mov	_var04, #32
LR__0001
	shl	_var03, #1 wc
 if_nc	djnz	_var04, #LR__0001
	sub	_var04, #23
	mov	_var02, _var04
	mov	_var05, #7
	sub	_var05, _var04
	shl	arg01, _var05
LR__0002
	sub	_var02, #127
	cmp	arg02, #0 wz
 if_ne	mov	result1, _var02
 if_e	mov	result1, arg01
_dounpack_x_ret
	ret

imm_536870912_
	long	536870912
imm_8388607_
	long	8388607
result1
	long	0
COG_BSS_START
	fit	496
	org	COG_BSS_START
_var01
	res	1
_var02
	res	1
_var03
	res	1
_var04
	res	1
_var05
	res	1
arg01
	res	1
arg02
	res	1
	fit	496
