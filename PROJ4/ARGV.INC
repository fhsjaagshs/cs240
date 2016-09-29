; ARGV.INC
;
; Utilities to read the DOS command tail
; as if it were a C/C++ argv/argc pair.
;
; "Monadic" versions of ARGV functions from class.

args PROC
  ; IN: DS:SI -> to be ARGV values (buffer of at least 128 bytes)
  ;     DS:BX -> to be ARGV offsets (buffer of at least 64 bytes)
  ; OUT: CX -> ARGC
  ;      DS:SI is set up with ASCIIZ args
  ;      DS:BX is set up with offsets to args
  push ax
  push bx
  push dx
  push si

  call getcmdtail
  call nullify

  mov cx, 128
  xor ax, ax		; Clear the number of args (temp stored in AX)
  jmp compare
top:
  inc ax		; Inc temporary ARGC counter. (skipwhile uses CX)
  mov [bx], si		; Add offset to ARGV offsets.
  inc bx
  mov dx, 0100h
  call skipwhile	; Skip past the arg we just made a ptr to
compare:
  mov dx, 0000h
  call skipwhile	; Skip past leading nulls.
  cmp cx, 0
  ja top		; strlen(SI) > 0

  mov cx, ax

  pop si
  pop dx
  pop bx
  pop ax
  ret
args ENDP

skipwhile PROC
  ; IN: DS:SI -> string
  ;     DL    -> character to skip or not to skip (depends on DH)
  ;     DH    -> If 0, skip while eq, otherwise skip while not eq
  ; 	CX    -> String length
  ; OUT: DS:SI -> String input, advanced to reflect skipping
  ;      CX    -> Remaining string length
top:
  cmp cx, 0	; Are there any chars left?
  je done	; Exit procedure.
  cmp [si], dl	; compare current char to DL
  je matches	; Branch accordingly.
doesntmatch:
  cmp dh, 1	; If we skip while not equal
  jmp body	; Flags unmodified by JMP.
matches:
  cmp dh, 0	; If we skip while equal
body:
  jne done
  inc si	; Skip a char
  dec cx	;
  jmp top
done:
  ret
skipwhile ENDP

getcmdtail PROC
  ; IN: DS:SI -> buffer, should be >= 128 bytes
  ; OUT: CX -> length of command tail
  ;      copies DOS command tail to DS:SI
  push dx
  push si
  push di

  mov di, si
  mov si, 81h		; Set SI to start of CMD tail

  xor cx, cx		; Clear CX
  mov cl, es:[80h]	; Read number of bytes in CMD tail

  push cx
top:
  mov dl, es:[si]	; Read a char from the CMD tail
  mov [di], dl		; Write it to our buffer
  inc si		; Advance ptr in CMD tail
  inc di		; Advance ptr in buffer
  loop top
  pop cx

  mov byte ptr [di], 0	; NULL terminate

  pop di
  pop si
  pop dx
  ret
getcmdtail ENDP

isspace PROC
  ; IN: dl -> char
  ; OUT: sets carry flag if dl (20h, 08h - 0Dh)
  ;      otherwise reset carry flag
  ;      trash other flags

  cmp dl, 20h
  je yes
  cmp dl, 08h
  jb no
  cmp dl, 0Dh
  ja no
yes:
  stc
  ret
no:
  clc
  ret
isspace ENDP

nullify PROC
  ; IN: DS:SI -> ASCIIZ String to nullify
  ; OUT: DS:SI is nullified.
  ; Replace all whitespace chars with 00h
  push cx
  push dx
  push si
top:
  mov dl, [si]		; Get the current char
  cmp dl, 0      	; While the character isn't a NULL
  je done
  inc cx
  call isspace		; if it's a space
  jnc next
  mov byte ptr [si], 0	; null it out
next:
  inc si		; Advance SI
  jmp top
done:
  pop si
  pop dx
  pop cx
  ret
nullify ENDP








