TITLE	template.asm

; Author: Nathaniel Symer
; Last update: 9.15.2016
;
; <DESC>

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code
main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main





