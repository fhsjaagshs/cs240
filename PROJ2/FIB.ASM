TITLE	fib.asm

; Author: Nathaniel Symer
; Last update: 9.5.2016
;
; Computes the ith fibonacci number
; in the fibonacci sequence

INCLUDE Irvine16.inc
.8086
.data
i WORD 7
.code

; TAKES:
; ax: i
; RETURNS:
; ax: ith in fib sequence
fibi PROC
  push bx
  push cx
  push dx

  mov cx, 1 ; setup the loop
  mov dx, 0 ; prev fib number
  mov ax, 1 ; current fib number

  jmp cond
body:
    mov bx, ax ; store soon-to-be prev num
    add ax, dx ; add prev to current
    mov dx, bx ; set prev
    inc cx
cond:
    cmp cx, i
    jl body

  pop dx
  pop cx
  pop bx
  ret
fibi ENDP

main PROC
  mov ax,@data ; set up the
  mov ds,ax    ; data segment register

  mov ax, i
  call fibi
  call dumpregs

  mov ax, 4C00h	; DOS function 4C exits
  int 21h	; DOS interrupt.
main ENDP
END main





