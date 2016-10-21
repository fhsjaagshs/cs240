TITLE	clock.asm

; Author: Nathaniel Symer
; Last update: 10.17.2016
;
; Displays a clock in the upper right hand corner.

.model small
.8086
.stack 4096
.data
.code

; These must be in the code segment
; in order to be able to call them.
;
; Apparently it's a common security
; measure to avoid executing code
; in the data segment. I'm guessing
; DOS/BIOS recognizes instances where
; this happens and it crashes intentionally.

INCLUDE clogic.inc
INCLUDE cinstall.inc

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  call installinthandlers
waiter:
  call ReadConsole
  cmp dh, 2Eh		; CTRL-C
  jne waiter

  call uninstallinthandlers

  mov ax, 4C00h	; Exit zero
  int 21h		; DOS interrupt with 4C00h
main ENDP

END main

