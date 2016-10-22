;; CLOGIC.INC
;;
;; Logic for printing a clock display in the upper right hand corner.
;;

INCLUDE console.inc

show_clock BYTE 1

readzero PROC
  ; IN si -> Byte index relative to 0 you want to read
  ; OUT dl -> byte at 0:[si]
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
  push ax
  push dx
  push si

  mov si, 0417h				; Read shift byte.
  call readzero
  mov al, dl				; Store first shift byte in AL.
  mov si, 0418h				; Read extended shift byte.
  call readzero
  add al, dl				; Add ext-shift byte to shift byte.
  cmp al, 3				; 3 means both shifts are pressed.
  jne aftertoggle
  xor cs:[show_clock], 00000001b	; Toggle show_clock
aftertoggle:
  pop si
  pop dx
  pop ax
  ret
onkeypress ENDP

clockstr   BYTE "00:00:00"
noclockstr BYTE "        "

ontimer PROC
  push ax
  push bx
  push dx

  call CursorPosition		; Get the cursor position
  push dx			; and pop it. We'll move back
				; after printing the clock.

  call ScreenProps		; AH -> screen width
  sub ah, 8			; 8 chars from end
  mov dl, ah			; Move AH into column param for MoveCursorTo
  mov dh, 0
  call MoveCursorTo

;; ; This was an idea to print without moving the
;  ; cursor, allowing for more efficient printing.
;  ; it would have used a procedure not too far
;  ; removed from the graphics hardware to print chars.
;  ; Something about WriteManyAt doesn't work (prints garbage).
;  ;
;  ; Because of the cursor independence WriteManyAt offers, it might
;  ; also circumvent the scrolling bug where the clock gets treated
;  ; as part of the text onscreen, allowing the clock to exist independently
;  ; of something like emacs (it seems running the clock over emacs causes
;  ; changes to the file emacs is editing)
;  push ax
;  push cs
;  mov ax, offset cs:noclockstr
;  push ax
;  mov ax, 8
;  push ax
;  call WriteManyAt
;  pop ax

  ; Clear out clock
  push cx
  mov dl, ' '
  mov cx, 8
  call WriteNConsole
  neg cl
  call MoveCursor
  pop cx

  cmp cs:[show_clock], 0	; Do we print a clock?
  je movecback			; Skip printing the clock if we don't show it.
  call PrintClockConsole
movecback:
  pop dx			; Pop the old cursor pos
  call MoveCursorTo		; and move back

  pop dx
  pop bx
  pop ax
  ret
ontimer ENDP

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

orig_handle08 DWORD 0
orig_handle09 DWORD 0

handle08 PROC
  pushf
  call cs:[orig_handle08]
  call ontimer
  iret
handle08 ENDP

handle09 PROC
  pushf
  call cs:[orig_handle09]
  call onkeypress
  iret
handle09 ENDP

