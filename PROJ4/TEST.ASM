TITLE	test.asm

; Author: Nathaniel Symer
; Last update: 9.28.2016

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code

PrintColor PROC
  ; IN: dl -> char
  ;     dh -> BIOS color codes, see int 10h docs
  ; 

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov ah, 02h
  mov dl, 'c'
  int 21h

  mov ah, 09h
  mov al, 'd'
  mov bh, 0
  mov bl, 00000011b
  mov cx, 1
  int 10h

  mov ah, 02h
  mov dl, 'e'
  int 21h

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main








