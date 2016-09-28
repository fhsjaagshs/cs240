TITLE	hello.asm

; Author: Nathaniel Symer
; Last update: 9.5.2016
;
; Prints a string

INCLUDE Irvine16.inc
.8086
.data
x BYTE 'Hello, World!',0
.code

; takes:
; si -> pointer to a string in memory
; causes:
; prints the ASCIZ string at si
writeASCIZ PROC
  push ax
  push si
  push dx

  mov ah, 02h

loopl:
  mov dl, [si]
  cmp dl, 0
  je done
  int 21h
  inc si
  jmp loopl

done:
  pop dx
  pop si
  pop ax
  ret
writeASCIZ ENDP

main PROC
  mov ax,@data	        ; set up the
  mov ds,ax	        ; data segment register

  mov si, OFFSET x      ; setup source index to point at x
  call writeASCIZ       ; write x to STDOUT

  mov ax, 4C00h 	; DOS function 4C exits
  int 21h		; DOS interrupt.
main ENDP
END main












