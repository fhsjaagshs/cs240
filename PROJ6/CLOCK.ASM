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

; These must be in the code segment
; in order to be able to call them.
;
; Apparently it's a common security
; measure to avoid executing code
; in the data segment. I'm guessing
; DOS/BIOS recognizes instances where
; this happens and it crashes intentionally.
orig_handle08 DWORD 0
orig_handle09 DWORD 0

INCLUDE inthdl.inc

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  ; Handler Installation
  push es

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
  mov al, 09h		; Keyboard input interrupt
  mov dx, OFFSET handlekb
  call installhandler
  mov word ptr orig_handle09, bx
  mov word ptr orig_handle09+2, es

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
  mov al, 08h		; System timer interrupt
  mov dx, offset handletimer
  call installhandler
  mov word ptr orig_handle08, bx
  mov word ptr orig_handle08+2, es

  pop es

  call readloop

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

readloop PROC
top:
  call readstring
  call crlf
  cmp byte ptr [bx], 0
  je done
  call WriteString
  call crlf
  jmp top
done:
  ret
readloop ENDP

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
  pushf
  call orig_handle09
  iret
handlekb ENDP

handletimer PROC
  pushf
  call orig_handle08
  iret
handletimer ENDP

hex BYTE "0123456789abcdef"
Out16 PROC
  ; STDCALL 16-bit value parameter
  ; output in hex

  push bp
  mov bp, sp

  push ax
  push bx
  push cx
  push dx

  mov dx, [bp+4]	; Load the STDCALL 16-bit value param into DX
  mov cx, 4
  mov ah, 0Eh		; BIOS output routine
L1:
  push cx
  mov cx, 4
  rol dx, cl
  pop cx
  mov bx, dx
  and bx, 000Fh
  mov al, hex[bx]
  int 10h
  loop L1

  pop dx
  pop cx
  pop bx
  pop ax

  mov sp, bp
  pop bp
  ret 2
Out16 ENDP

END main

