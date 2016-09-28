TITLE	decimal.asm

; Author: Nathaniel Symer
; Last update: 9.18.2016
;
; Print a signed word in decimal (base 10).

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code

PrintChar PROC
  ; takes:
  ; dl -> your char
  ; causes: prints your char
  push ax
  mov ax, 0200h	; Setup AX to print a char
  int 21h	; DOS interrupt to print
  pop ax
  ret
PrintChar ENDP

MyWriteWord PROC
  ; takes:
  ; ax -> signed word to print
  ; causes ax to be printed in decimal
  push ax
  push dx

  cmp ax, 8000h		; If AX (as a WORD) < 8000h (8000h is the first neg num)
  jb after_2c		; AX is not signed.

  xor ax, 0FFFFh	; Undo 2's complement, XOR ax with 2 bytes of ones.
  add ax, 1		; add one to AX

  mov dl, '-'		; setup DL to print a negative sign
  call PrintChar	; Print a negative sign
after_2c:
  call MyWriteWordUnsigned
  pop dx
  pop ax
  ret
MyWriteWord ENDP

MyWriteWordUnsigned PROC
  push bx
  push cx
  push dx

  mov cx, 0 	; Prepare to count characters.
  mov bx, 10	; Prepare for division.
builder:
  xor dx, dx	; Clear DX.
  div bx	; Divide our number by 10: DX(mod) AX(quot)
  add dx, '0'	; Turn the remainder into an ASCII char.
		; This isn't ideal because dx could be > 255
		; Even though it shouldn't be.
  push dx	; Push char to stack for later printing.
  inc cx	; Increment char counter.
  cmp ax, 0	; Are there any more places/digits to print?
  jne builder	; If there are, loop back

printer:
  pop dx
  call PrintChar
  loop printer

  pop dx
  pop cx
  pop bx
  ret
MyWriteWordUnsigned ENDP

main PROC
  ; setup the data
  ; segment register
  mov ax, @data
  mov ds, ax

  mov ax, sword ptr 10000
  call MyWriteWord

  ; Exit 0 with DOS func 4C
  mov ax, 4C00h
  int 21h
main ENDP
END main





