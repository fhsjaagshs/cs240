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
  push bx
  push cx
  push dx

  call getcommandtail
  call nullify

  jmp compare
top:
  mov [bx], si		; add offset to ARGV offsets
  inc bx		; and move onto the next position in the ary
  mov dx, 0100h		; Skip past current argument
  call skipwhile
  mov dx, 0000h		; Skip past trailing nulls
  call skipwhile
compare:
  cmp cx, 0		; strlen(SI) > 0
  jne top

  pop dx
  pop cx
  pop bx
  ret
args ENDP

skipwhile PROC
  ; IN: DS:SI -> string
  ;     DL    -> character to skip or not to skip (depends on DH)
  ;     DH    -> If 0, skip while eq, otherwise skip while not eq
  ;     CX    -> Length of string in DS:SI
  ; OUT: DS:SI -> String input, advanced to reflect skipping
  ;      CX    -> Resulting string length
top:
  cmp cx, 0
  je done
  cmp [si], dl	; compare current char to DL
  je matches	; branch accordingly
doesntmatch:
  cmp dh, 1	; If we skip while not equal
  jne done
  inc si	; skip a char
  dec cx
  jmp top
matches:
  cmp dh, 0	; If we skip while equal
  jne done
  inc si	; skip a char
  dec cx
  jmp top
done:
  ret
skipwhile ENDP

getcmdtail PROC
  ; IN: DS:SI -> buffer, should be at least 128 bytes
  ; OUT: Nothing, cmdtail copied to buffer
  push cx
  push dx
  push si
  push dx

  mov di, si
  mov si, 81h		; beginning of chars in tail
  mov cx, 0		; put number of chars
  mov cl, es:[80h] 	; CX
top:
  jcxz done
  mov dl, es:[si]
  mov [di], dl
  inc si
  inc di
  loop top
done:
  mov byte ptr [di], 0
  pop di
  pop si
  pop dx
  pop cx
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
  ; IN: DS:SI -> ASCIIZ str
  ; OUT: CX -> str length
  ;      DS:SI is nullified.
  ; The idea is to make separators
  ; between arguments act like separators
  ; between arguments on an ASCIIZ level.
  push si
  push dx
  xor cx, cx		; Zero out CX.
top:
  mov dl, [si]		; Get the current char
  cmp dl, 0      	; While the character isn't a NULL
  je done
  inc cx		; add one to CX
  call isspace		; if it's a space
  jnc next
  mov byte ptr [si], 0	; null it out
next:
  inc si		; Advance SI
  jmp top
done:
  pop dx
  pop si
  ret
nullify ENDP








