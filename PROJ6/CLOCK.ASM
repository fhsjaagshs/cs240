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
INCLUDE console.inc

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  ; Handler Installation
  push es

;  push cs		; push the code segment
;  pop es		; and pop it into the extra segment
;  mov al, 09h		; Keyboard input interrupt
;  mov dx, OFFSET handlekb
;  call installhandler
;  mov word ptr orig_handle09, bx
;  mov word ptr orig_handle09+2, es
;
;  push cs		; push the code segment
;  pop es		; and pop it into the extra segment
;  mov al, 08h		; System timer interrupt
;  mov dx, offset handletimer
;  call installhandler
;  mov word ptr orig_handle08, bx
;  mov word ptr orig_handle08+2, es

  pop es

  call PrintClockURHCorner

waiter:
  call ReadConsole
  cmp dh, 2Eh		; CTRL-C
  jne waiter

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

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

PrintClockURHCorner PROC
  push ax
  push bx
  push dx

  call CursorPosition
  push dx

  call ScreenProps	; AH -> screen width
  sub ah, 8		; 8 chars from end
  mov dl, ah
  mov dh, 0
  call MoveCursorTo
  call PrintClockConsole

  pop dx
  call MoveCursorTo

  pop dx
  pop bx
  pop ax
  ret
PrintClockURHCorner ENDP

PrintClockConsole PROC
  push cx
  push dx
  call GetTimeBIOS

  xchg dx, cx
  xchg dh, dl
  call HexOut8Console		; Print hours.
  call WriteColonConsole	; Print a colon.
  xchg dh, dl
  call HexOut8Console		; Print minutes.
  call WriteColonConsole	; Print a colon.
  xchg cx, dx
  xchg dl, dh
  call HexOut8Console		; Print seconds.

  pop dx
  pop cx
  ret
PrintClockConsole ENDP

WriteColonConsole PROC
  push dx
  mov dl, ':'
  call WriteConsole
  pop dx
  ret
WriteColonConsole ENDP

HexOut4Console PROC
  ; IN: dl -> byte to print in hex.
  ; Prints low nybble of DL at cursor in hex.
  push ax
  push dx
  and dl, 0Fh		; Clear high butes
  add dl, '0'		; Convert DL into an ASCII char
  cmp dl, '9'		; Is DL numeric? Only test if DL <= ASCII 9
			; because we already ensured that DL >= ASCII 0.
  jle print
  add dl, 7		; When DL isn't numeric, advance to ASCII uppercase.
print:
  call WriteConsole
  pop dx
  pop ax
  ret
HexOut4Console ENDP

HexOut8Console PROC
  ; IN: dl -> byte
  ; Prints DL as hex at the current cursor position.
  push cx
  mov cl, 4
  rol dl, cl
  call HexOut4Console
  rol dl, cl
  call HexOut4Console
  pop cx
  ret
HexOut8Console ENDP

;; TODO: take daylight savings into account
GetTimeBIOS PROC
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
GetTimeBIOS ENDP

END main


