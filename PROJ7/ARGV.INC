; ARGV.INC
;
; Utilities to read the DOS command tail
; as if it were a C/C++ argv/argc pair.

nullify PROC
  ; IN: CS:SI -> ASCIIZ String to nullify
  ;     CS:BX -> buffer to store string offsets in (words).
  ;       >> CS:BX MUST be able to accommodate CS:SI (tip: (LENGTHOF CS:SI)/2)
  ; OUT: CX -> number of null-terminated string segments.
  ; Replace all tabs and spaces in CS:SI with 00h.
  ; Store offsets to all portions that weren't nulled out in CS:BX.
  push ax
  push bx
  push si

  xor cx, cx
  mov ax, 0
nf_top:
  cmp byte ptr cs:[si], 0		; If a NULL
  je nf_done				; we're done.
  cmp byte ptr cs:[si], 09h		; If a tab
  je nf_nullout				; null it out.
  cmp byte ptr cs:[si], 20h		; If a space
  je nf_nullout				; null it out.

  cmp ax, 1				; If we were in characters
  je nf_next				; Skip to increment

  mov cs:[bx], si			; Store SI in offsets,
  add bx, 2				; increment the tail of the ary.
  inc cx				; Increment str count.

  mov ax, 1				; Indicate that we just entered chars.
  jmp nf_next				; Jump over nulling code
nf_nullout:
  mov ax, 0				; Indicate that we're in whitespace.
  mov byte ptr cs:[si], 0		; null it out.
nf_next:
  inc si				; Advance SI.
  jmp nf_top				; It's a loop, after all.
nf_done:
  pop si
  pop bx
  pop ax
  ret
nullify ENDP

getcmdtail PROC
  ; IN: CS:SI -> buffer, should be >= 128 bytes
  ; OUT: CX -> length of command tail
  ;      copies DOS command tail to CS:SI in ASCIIZ (despite returning len).
  push dx
  push si
  push di

  xor ch, ch			; Clear CH
  mov cl, es:[80h]		; Read number of bytes in CMD tail into CL
  cmp cl, 0
  je gct_done

  mov di, si			; DI should hold the buffer offset
  mov si, 81h			; Set SI to start of CMD tail

  push cx
  push es
  push ds

  push es			; "Set" movsb source segment to ES.
  pop ds

  push cs			; "Set" movsb destination segment to CS.
  pop es

  cld				; Ensure movsb moves forward.
gct_top:
  movsb 			; Move byte at DS:SI to ES:DI & inc SI and DI
  loop gct_top
  pop ds
  pop es
  pop cx

gct_done:
  mov byte ptr cs:[di], 0	; NULL terminate
  pop di
  pop si
  pop dx
  ret
getcmdtail ENDP

skipwhile PROC
  ; IN: CS:SI -> string
  ;     DL    -> character to skip or not to skip (depends on DH)
  ;     DH    -> If 0, skip while eq, otherwise skip while not eq
  ; 	CX    -> String length
  ; OUT: CS:SI -> String input, advanced to reflect skipping
  ;      CX    -> Remaining string length
sw_top:
  cmp cx, 0		; Are there any chars left?
  je sw_done		; Exit procedure.
  cmp cs:[si], dl	; compare current char to DL
  je sw_matches		; Branch accordingly.
sw_doesntmatch:
  cmp dh, 1		; If we skip while not equal
  jmp sw_body		; Flags unmodified by JMP.
sw_matches:
  cmp dh, 0		; If we skip while equal
sw_body:
  jne sw_done
  inc si		; Skip a char
  dec cx		;
  jmp sw_top
sw_done:
  ret
skipwhile ENDP





