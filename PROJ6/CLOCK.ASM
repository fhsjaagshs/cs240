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

INCLUDE inthdl.inc
INCLUDE console.inc

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  call install08
  call install09
  call PrintClockURHCorner
waiter:
  call ReadConsole
  cmp dh, 2Eh		; CTRL-C
  jne waiter

  call uninstall09
  call uninstall08

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

orig_handle08 DWORD 0
orig_handle09 DWORD 0

show_clock BYTE 1

readzero PROC
  ; IN si -> Byte index relative to 0 you want to read
  ; OUT dl -> byte at 0:si
  push es

  ; Sets ES to 0
  push dx
  mov dx, 0
  push dx
  pop es
  pop dx

  mov dl, es:[si]
  pop es
  ret
readzero ENDP

handlekb PROC
  pushf
  call orig_handle09

  push dx
  push si
  push ax
  xor ax, ax
  mov si, 0417h		; Read shift byte
  call readzero
  add al, dl
  mov si, 0418h		; Read extended shift byte
  call readzero
  add al, dl
  cmp al, 3		; 3 means both shifts are pressed
  jne done
  xor [show_clock], 00000001b	; Toggle show_clock
done:
  pop ax
  pop si
  pop dx
  iret
handlekb ENDP

handletimer PROC
  pushf
  call orig_handle08
  cmp [show_clock], 0
  je noclock
  call PrintClockURHCorner
  jmp done
noclock:
  ; TODO: blot out bytes
done:
  iret
handletimer ENDP

install08 PROC
  push es
  push ax
  push bx
  push dx

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
  mov al, 08h
  mov dx, OFFSET cs:handletimer
  call installhandler
  mov word ptr cs:orig_handle08, bx
  mov word ptr cs:orig_handle08+2, es

  pop dx
  pop bx
  pop ax
  pop es
  ret
install08 ENDP

uninstall08 PROC
  push es
  push ax
  push bx
  push dx

  mov ax, word ptr cs:orig_handle08+2
  push ax
  pop es
  mov al, 08h
  mov dx, word ptr cs:orig_handle08
  call installhandler

  pop dx
  pop bx
  pop ax
  pop es
  ret
uninstall08 ENDP

install09 PROC
  push es
  push ax
  push bx
  push dx

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
  mov al, 09h
  mov dx, OFFSET cs:handlekb
  call installhandler
  mov word ptr cs:orig_handle09, bx
  mov word ptr cs:orig_handle09+2, es

  pop dx
  pop bx
  pop ax
  pop es
  ret
install09 ENDP

uninstall09 PROC
  push es
  push ax
  push bx
  push dx

  mov ax, word ptr cs:orig_handle09+2
  push ax
  pop es
  mov al, 09h
  mov dx, word ptr cs:orig_handle09
  call installhandler

  pop dx
  pop bx
  pop ax
  pop es
  ret
uninstall09 ENDP

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


