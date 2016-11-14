; ARGV.INC
;
; Utilities to read the DOS command tail
; as if it were a C/C++ argv/argc pair.
;
; "Monadic" versions of ARGV functions from class.

args PROC
  ; IN: CS:SI -> to be ARGV values (buffer of at least 128 bytes)
  ;     CS:BX -> to be ARGV offsets (buffer of at least 64 bytes)
  ; OUT: CX -> ARGC
  ;      CS:SI is set up with ASCIIZ args
  ;      CS:BX is set up with offsets to args
  push ax
  push bx
  push dx
  push si

  call getcmdtail
  call nullify

  mov cx, 128
  xor ax, ax		; Clear the number of args (temp stored in AX)
  jmp args_compare
args_top:
  inc ax		; Inc temporary ARGC counter. (skipwhile uses CX)
  mov cs:[bx], si	; Add offset to ARGV offsets.
  inc bx
  mov dx, 0100h
  call skipwhile	; Skip past the arg we just made a ptr to
args_compare:
  mov dx, 0000h
  call skipwhile	; Skip past leading nulls.
  cmp cx, 0
  ja args_top		; strlen(SI) > 0

  mov cx, ax

  pop si
  pop dx
  pop bx
  pop ax
  ret
args ENDP

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
  jmp top
done:
  ret
skipwhile ENDP

getcmdtail PROC
  ; IN: CS:SI -> buffer, should be >= 128 bytes
  ; OUT: CX -> length of command tail
  ;      copies DOS command tail to DS:SI
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

  push es
  pop ds

  push cs
  pop es

  cld				; Ensure movsb moves forward
gct_top:
  movsb 			; moves byte at DS:SI to ES:DI
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

nullify PROC
  ; IN: CS:SI -> ASCIIZ String to nullify
  ; OUT: CS:SI is nullified.
  ; Replace all whitespace chars with 00h
  push si
nf_top:
  cmp cs:[si], 0		; While the current char isn't NULL
  je nf_done
  cmp cs:[si], 20h
  jne nf_next
  cmp cs:[si], 08h
  jb nf_next
  cmp cs:[si], 0dh
  ja nf_next
  mov byte ptr cs:[si], 0	; null it out
nf_next:
  inc si			; Advance SI
  jmp nf_top
nf_done:
  pop si
  ret
nullify ENDP

