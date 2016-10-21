;; CLOGIC.INC
;;
;; Logic for printing a clock display in the upper right hand corner.
;;

INCLUDE console.inc

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

onkeypress PROC
  push dx
  push si
  push ax
  xor ax, ax
  mov si, 0417h						; Read shift byte
  call readzero
  add al, dl
  mov si, 0418h						; Read extended shift byte
  call readzero
  add al, dl
  cmp al, 3							; 3 means both shifts are pressed
  jne done
  xor cs:[show_clock], 00000001b	; Toggle show_clock
done:
  pop ax
  pop si
  pop dx
  ret
onkeypress ENDP

ontimer PROC
  cmp cs:[show_clock], 0
  je noclock
  call PrintClockURHCorner
  jmp done
noclock:
  ; TODO: blot out bytes
done:
  ret
ontimer ENDP

PrintClockURHCorner PROC
  push ax
  push bx
  push dx

  call CursorPosition
  push dx

  call ScreenProps	; AH -> screen width
  sub ah, 8			; 8 chars from end
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
gtblbl:
  push ax
  mov ax, 0200h
  int 1Ah
  pop ax
  jc gtblbl		; 1Ah/02h sets CF when it can't read the systime.
			; 99.999999% of the time, this is when the interrupt
			; is called when the value is changing. Try again.
  ret
GetTimeBIOS ENDP

