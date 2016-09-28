TITLE	arysum.asm

; Author: Nathaniel Symer
; Last update: 9.18.2016
;
; Sum an array.

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code

ArraySum PROC
  ; takes:
  ; bx -> start index of array
  ; dl -> size of elements
  ; cx -> number of elements
  ; sets:
  ; ax -> the sum

  push bx
  push cx
  push dx
  push si
  mov si, bx	; Move BX to SI, we need BX as a gen-purpose reg.
  mov ax, 0	; Clear sum register.

body:
  xor bx, bx	; Clear BX.
  mov bl, [si]	; Move first byte of number into low bytes of BX.
  inc si	; Advance ptr.
  cmp dl, 2	; IF the number size isn't 2,
  jne adder	; Skip to adder.
  mov bh, [si]	; ELSE Move second byte of number into high bytes of BX.
  inc si	; Advance ptr.
adder:
  add ax, bx	; Add BX to AX, storing first 32 bits of sum in AX
  loop body

done:
  pop si
  pop dx
  pop cx
  pop bx
  ret
ArraySum ENDP

main PROC
  mov ax, @data ; setup data segment
  mov ds, ax	; make up for machine quirk

.data
  aryb BYTE 1,5,6
  aryw WORD 300,300,300
.code
  mov bx, OFFSET aryb
  mov cx, 3
  mov dl, 1
  call ArraySum
  call WriteInt

  mov dl, 0Ah
  mov ah, 02h
  int 21h

  mov bx, OFFSET aryw
  mov cx, 3
  mov dl, 2
  call ArraySum
  call WriteInt

  mov ax, 4C00h	; exit zero
  int 21h
main ENDP
END main





