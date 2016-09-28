TITLE	write.asm

; Author: Nathaniel Symer
; Last update: 9.18.2016
;
; Write a recursive proc that
; writes an ASCIIZ string to
; the screen.

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code
write PROC
  ; takes:
  ; bx -> addr of a string
  push ax
  push bx
  push dx
  mov ax, 0200h ; Setup AX for printing BEFORE recursion.
  call _write	; call "internal" recursive procedure.
  pop dx
  pop bx
  pop ax
  ret
write ENDP

_write PROC
  ; takes the same as write
  ;
  ; Recursive internal proc.
  ; Pushes/Pops handled by write.
  ; Avoids exhausting the stack.
  mov dl, [bx]	; Load current character into DL at BX
  cmp dl, 0	; If DL is 0,
  je done	; return.
  inc bx	; Else increment bx, then
  int 21h       ; DOS interrupt (AX set in write)
  call _write	; RECURSIVE CALL!!!
done:
  ret
_write ENDP

main PROC
  ; setup the data
  ; segment register
  mov ax, @data
  mov ds, ax

.data
  mystring BYTE "To explain infinite recursion, "
  _ BYTE "I must first explain infinite recursion.", 0
.code
  mov bx, OFFSET mystring
  call write

  ; Exit 0 with DOS func 4C
  mov ax, 4C00h
  int 21h
main ENDP
END main






