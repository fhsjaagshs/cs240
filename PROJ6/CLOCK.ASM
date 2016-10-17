TITLE	clock.asm

; Author: Nathaniel Symer
; Last update: 10.17.2016
;
; Displays a clock in the upper right hand corner.

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code
main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  ; Handler Installation
;  push cs		; push the code segment
;  pop es		; and pop it into the extra segment
;  mov al, 09h		; Keyboard input interrupt
;  mov dx, offset handlekb
;  call installhandler

;  push cs		; push the code segment
;  pop es		; and pop it into the extra segment
;  mov al, 08h		; System timer interrupt
;  mov dx, offset handletimer
;  call installhandler

  call gettimebios
  call DumpRegs

  ;; WAIT

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

gettimebios PROC
  ; OUT -> CH hour (binary coded decimal) - looks like decimal in BCD
  ;        CL minutes (BCD)
  ;        DH seconds (BCD)
  ;        DL daylight savings (00h std time, 01h daylight time)
top:
  push ax
  xor al, al
  mov ah, 02h
  int 1Ah
  pop ax
  jc top	; 1Ah/02h sets CF when it can't read the systime.
		; 99.999999% of the time, this is when the interrupt
		; is called when the value is changing. Try again.
  ret
gettimebios ENDP

handlekb PROC

  iret
handlekb ENDP

lol BYTE 0
handletimer PROC
  push si
  mov si, OFFSET lol
  mov ax, [si]
  iret
handletimer ENDP

installhandler PROC
  ; IN ->  al: interrupt number
  ;        es: segment of new handler
  ;        dx: offset of new handler
  ; OUT -> bx: offset of old handler.
  ;        es: segment of old handler
  ; CAUSES -> installs the new handler.

  push ax
  push ds

  mov ah, 35h	; Read IVT
  int 21h	; sets BX and ES.

  push es	; Push our segment param
  pop ds	; and pop it into where DOS expects it.
  mov ah, 25h	; Set the entry in the IVT.
  int 21h	; other arg is (DS:DX)

  pop ds
  pop ax

  ret
installhandler ENDP

END main





