;; CLOGIC.INC
;;
;; Logic for printing a clock display in the upper right hand corner.
;;

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
clock_attrs  BYTE 0Fh		; White on black

ontimer PROC
  push ax
  push bx
  push cx
  push dx
  push bp
  push es

  call UpdateClock		; Update cs:clockstr.

  mov bp, OFFSET cs:noclockstr	; Assume we're clearing the clock.
  cmp cs:[show_clock], 0	; Are we printing a clock?
  je ot_print			; If we're not printing a clock, print
  mov bp, OFFSET cs:clockstr	; Otherwise, load the clock str into BP
ot_print:
  mov ax, 1300h			; Write String to Screen; Subservice 00h
				; (Print char string, don't update cursor)
  mov bh, 0			; ASSUME page #0
  mov bl, cs:clock_attrs	; Load clock attributes.
  mov cx, 8			; cs:*clockstr is always 8 bytes long.
  mov dx, 0048h			; Print in Upper RHS corner. ASSUME width=80
  push cs			; | Point ES to the code segment,
  pop es			; | since that's where *clockstr live.
  int 10h			; Print CX chars at ES:BP

  pop es
  pop bp
  pop dx
  pop cx
  pop bx
  pop ax
  ret
ontimer ENDP

BCDToASCII PROC
  ; IN: al -> BCD value
  ;     cs:si -> buffer containing at least 2 bytes
  ;              that will contain the BCD value
  ;              in an ASCII representation.
  ; OUT: modifies buffer pointed to by CS:SI

  push ax
  and al, 0Fh		; Clear high nybble
  add al, '0'		; ASCII-ize, assume no hex digits from A-F.
  mov cs:[si+1], al	; Move into memory
  pop ax

  push ax
  push cx
  and al, 0F0h		; Clear low nybble
  mov cl, 4		; | Shift AL 4 bytes
  shr al, cl		; | to the right (move high bits into low bits)
  add al, '0'		; ASCII-ize, assume no hex digits from A-F.
  mov cs:[si], al	; Move into memory
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

  mov ax, 0200h
  int 1Ah
  jc uc_done		; 1Ah/AH=0200h doesn't work if it's called
			; when the BIOS is updating the internal time.
			; In that case, don't update the time.

  ; At this point:
  ; CH -> hour (BCD)
  ; CL -> minute (BCD)
  ; DH -> seconds (BCD)
  ; DL -> (00h std time, 01h daylight savings time)

  push ax
  mov al, ch		; Move CH into daa compatible register.
  add al, dl		; add DST shift to AL (the hours).
  daa			; No daa! (hah)
  mov ch, al		; move hours back into CH.
  pop ax

  cmp ch, 24h
  jl uc_after_rotate_hour
  mov ch, 00h
uc_after_rotate_hour:

  ; At this point:
  ; CH -> hour w/ DST (BCD)
  ; CL -> minute (BCD)
  ; DH -> seconds (BCD)

  mov si, OFFSET cs:clockstr

  mov al, ch		; | print hours to clockstr
  call BCDToASCII	; |

  add si, 3		; move to minutes position
  mov al, cl		; | print minutes to clockstr
  call BCDToASCII	; |

  add si, 3		; move to seconds position
  mov al, dh		; | print seconds to clockstr
  call BCDToASCII	; |
uc_done:
  pop si
  pop dx
  pop cx
  pop ax
  ret
UpdateClock ENDP

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
