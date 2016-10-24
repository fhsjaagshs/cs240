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
  push cx
  push dx
  push ds
  push si

  push cs			; Ensure that DS
  pop ds			; is equivalent to CS.
				; Necessary for WriteManyAt.

  call UpdateClock

  mov si, OFFSET cs:noclockstr	; Assume we're clearing the clock.

  cmp cs:[show_clock], 0	; Are we printing a clock?
  je ot_print			; If we're not printing a clock, print
  mov si, OFFSET cs:clockstr	; Otherwise, load the clock str into SI
ot_print:
  call ScreenProps		; AH -> screen width
  sub ah, 8			; 8 chars from end
  mov dl, ah			; Move AH into column param for WriteManyAt
  mov dh, 0

  mov cx, 8
  call WriteManyAt

  pop si
  pop ds
  pop dx
  pop cx
  pop bx
  pop ax
  ret
ontimer ENDP

BCDToASCII PROC
  ; IN: al -> BCD value
  ;     ds:si -> buffer containing at least 2 bytes
  ;              that will contain the BCD value
  ;              in an ASCII representation.

  push ax
  and al, 0Fh		; Clear high nybble
  add al, '0'		; ASCII-ize, assume no hex digits from A-F.
  mov ds:[si+1], al	; Move into memory
  pop ax

  push ax
  push cx
  and al, 0F0h		; Clear low nybble
  mov cl, 4		; | Shift AL 4 bytes
  shr al, cl		; | to the right (move high bits into low bits)
  add al, '0'		; ASCII-ize, assume no hex digits from A-F.
  mov ds:[si], al	; Move into memory
  pop cx
  pop ax

  ret
BCDToASCII ENDP

UpdateClock PROC
  ; IN/OUT -> nothing
  ; updates cs:clockstr

  push ax
  push cx
  push dx
  push si
  mov si, OFFSET cs:clockstr
  call GetTimeBIOS

  mov al, ch		; | print hours to clockstr
  call BCDToASCII	; |

  add si, 3		; move to minutes position
  mov al, cl		; | print minutes to clockstr
  call BCDToASCII	; |

  add si, 3		; move to seconds position
  mov al, dh		; | print seconds to clockstr
  call BCDToASCII	; |

  pop si
  pop dx
  pop cx
  pop ax
  ret
UpdateClock ENDP

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

