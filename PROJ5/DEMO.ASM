TITLE	demo.asm

; Author: Nathaniel Symer
; Last update: 10.12.2016
;
; 3 functions project

INCLUDE Irvine16.inc
INCLUDE PROJ5.ASM
.8086
.stack 4096
.data
.code

main PROC
.data
buf BYTE 128 DUP(0)
.code
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov cx, 128		; setup buffer size

  mov si, OFFSET buf	; setup buffer ptr
  push si		; |
  push cx		; | setup params for SafeRead
  call SafeRead		; Reads into DS:SI
  call _atoi
  push ax

  call Crlf

  mov si, OFFSET buf
  push si
  push cx
  call SafeRead
  call _atoi
  push ax

  call Crlf

  call FastMultiply	; Multiply pushed AXes.
  push ax
  mov ax, 1000		; Wait for a second before printing result
  call MyDelay
  pop ax
  call WriteInt

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main



