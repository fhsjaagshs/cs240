TITLE	template.asm

; Author: Nathaniel Symer
; Last update: 8.29.2016
;
; This program illustrates how to write a program of 
; one procedure, calling another procedure from the 
; Irvine library.

INCLUDE Irvine16.inc
.8086
.data

.code

; takes:
; dl -> four least significant bits are a hex nybble
; causes: prints said nybble in hexadecimal
HexOut PROC
  push ax
  push dx
  add dl, 48  ; move to ASCII zero
  cmp dl, 57  ; and determine if DL is numeric
  jle print
  add dl, 7   ; move to capital letters in ASCII
print:
  mov ah, 02h ; DOS print char interrupt code
  int 21h     ; DOS interrupt
  pop dx
  pop ax
  ret
HexOut ENDP

main PROC
	mov ax,@data	; set up the
	mov ds,ax	; data segment register

	mov dl, 00001010b
	call HexOut

	mov ax, 4C00h	; DOS function 4C exits
	int 21h		; DOS interrupt.
main ENDP
END main





