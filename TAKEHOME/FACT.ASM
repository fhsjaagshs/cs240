	ifndef	??version
?debug	macro
	endm
	endif
	?debug	S "fact.c"
_TEXT	segment	byte public 'CODE'
DGROUP	group	_DATA,_BSS
	assume	cs:_TEXT,ds:DGROUP,ss:DGROUP
_TEXT	ends
_DATA	segment word public 'DATA'
d@	label	byte
d@w	label	word
_DATA	ends
_BSS	segment word public 'BSS'
b@	label	byte
b@w	label	word
	?debug	C E9A5B24A4906666163742E63
	?debug	C E90895C14816433A5C54435C494E434C5544455C7374646C69622E+
	?debug	C 68
_BSS	ends
_TEXT	segment	byte public 'CODE'
;	?debug	L 3
_facti	proc	near
	push	bp
	mov	bp,sp
;	?debug	L 5
	cmp	word ptr [bp+4],0
	jne	@2
;	?debug	L 6
	mov	ax,word ptr [bp+6]
	jmp	short @1
	jmp	short @3
@2:
;	?debug	L 8
	mov	ax,word ptr [bp+4]
	mul	word ptr [bp+6]
	push	ax
	mov	ax,word ptr [bp+4]
	dec	ax
	push	ax
	call	near ptr _facti
	mov	sp,bp
	jmp	short @1
@3:
@1:
;	?debug	L 9
	pop	bp
	ret	
_facti	endp
_TEXT	ends
_DATA	segment word public 'DATA'
_DATA	ends
_TEXT	segment	byte public 'CODE'
;	?debug	L 11
_main	proc	near
	push	bp
	mov	bp,sp
	sub	sp,2
;	?debug	L 13
	mov	word ptr [bp-2],6
;	?debug	L 14
	mov	ax,1
	push	ax
	push	word ptr [bp-2]
	call	near ptr _facti
	pop	cx
	pop	cx
	push	ax
	push	word ptr [bp-2]
	mov	ax,offset DGROUP:s@
	push	ax
	call	near ptr _printf
	add	sp,6
@4:
;	?debug	L 15
	mov	sp,bp
	pop	bp
	ret	
_main	endp
_TEXT	ends
	?debug	C E9
_DATA	segment word public 'DATA'
s@	label	byte
	db	37
	db	100
	db	33
	db	32
	db	61
	db	32
	db	37
	db	100
	db	0
_DATA	ends
_TEXT	segment	byte public 'CODE'
	extrn	_printf:near
_TEXT	ends
	public	_facti
	public	_main
	end
