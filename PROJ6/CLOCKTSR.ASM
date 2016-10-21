TITLE	clocktsr.asm

; Author: Nathaniel Symer
; Last update: 10.21.2016
;
; TSR version of clock.asm

.8086
.model tiny

.code
  org 100h

top:
  jmp start


INCLUDE clogic.inc

;;*****************************************************************************
; BEGINNING OF INSTALLER
;;*****************************************************************************
install:

INCLUDE cinstall.inc

start:
  call installinthandlers  

  mov dx, OFFSET install
  mov cl, 4
  shr dx, cl			; DX is bytes/16
  inc dx				; DX is paragraphcs to reserve
  mov ax, 3100h
  int 21h

end top

