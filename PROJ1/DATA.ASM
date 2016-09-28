TITLE	data.asm

; Author: Nathaniel Symer
; Last update: 8.29.2016
;
; Declares a bunch of data definitions.

INCLUDE Irvine16.inc
.8086
.data

;; declare one definition for each data type that;s
;; fewer than 32 bits wide
a BYTE 255
b SBYTE -128
z WORD 65535
d SWORD -32768 ;; 8000h
e DWORD 4294967295
f SDWORD -2147483648
;; floating point numbers (REALs) were
;; excluded because they haven't been
;; as much as brought up in class.

.code
main PROC
	mov ax,@data	; set up the
	mov ds,ax	; data segment register

	mov al, a ; valid
	mov ah, 00h
	mov bl, b ; valid
	mov bh, 00h
	mov cx, z ; valid
	call dumpregs

	; We only need to check one of each:
	; 1. signed number
	; 2. multibyte number

	mov ax, 4C00h	; DOS function 4C exits
	int 21h		; DOS interrupt.
main ENDP
END main





