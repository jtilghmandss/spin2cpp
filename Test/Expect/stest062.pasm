pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_mylen
	mov	__system__strsize_r, #0
LR__0001
	rdbyte	_tmp001_, arg1 wz
 if_ne	add	__system__strsize_r, #1
 if_ne	add	arg1, #1
 if_ne	jmp	#LR__0001
	mov	result1, __system__strsize_r
_mylen_ret
	ret

result1
	long	0
COG_BSS_START
	fit	496
	org	COG_BSS_START
__system__strsize_r
	res	1
_tmp001_
	res	1
arg1
	res	1
	fit	496
