TITLE	clocktsr.asm

; Author: Nathaniel Symer
; Last update: 10.18.2016
;
; TSR version of clock.asm

.8086
.model tiny

.code
	org 100h

top:	jmp start


;;*****************************************************************************
; BEGINNING OF INSTALLER
;;*****************************************************************************
install:

INCLUDE inthdl.inc

install_timer PROC

  ret
install_timer ENDP

install_kb PROC

  ret
install_kb ENDP

start:
  call install_timer
  call install_kb

  mov dx, OFFSET install
  mov cl, 4
  shr dx, cl			; DX is bytes/16
  inc dx			; DX is paragraphcs to reserve
  mov ax, 3100h
  int 21h

end top








