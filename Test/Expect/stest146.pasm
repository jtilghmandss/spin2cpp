pub main
  coginit(0, @entry, 0)
dat
	org	0
entry

_geta
	add	ptr__dat__, #8
	rdlong	result1, ptr__dat__
	sub	ptr__dat__, #8
_geta_ret
	ret

_getb
	add	ptr__dat__, #16
	rdlong	result1, ptr__dat__
	sub	ptr__dat__, #16
_getb_ret
	ret

_getc
	add	ptr__dat__, #20
	rdlong	result1, ptr__dat__
	sub	ptr__dat__, #20
_getc_ret
	ret

ptr__dat__
	long	@@@_dat_
result1
	long	0
COG_BSS_START
	fit	496
	long
_dat_
	byte	$00[24]
	org	COG_BSS_START
	fit	496
