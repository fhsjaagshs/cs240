; Printing.inc
; Nathaniel Symer
;
; Utilities for printing characters

INCLUDE Irvine16.inc

PutChar PROC
  ; IN: dl -> char to print
  ; OUT: prints DL
  push ax
  mov ax, 0200h
  int 21h
  pop ax
  ret
PutChar ENDP

PrintHumanReadable PROC
  ; IN: cx -> number of chars
  ;     ds:dx -> buffer
  ; OUT: prints human readable characters.
  ret
PrintHumanReadable ENDP

PrintUnsigned32 PROC
  ; IN: ds:dx -> ptr to 32-bit number in memory
  ; OUT: prints it!

  ret
PrintUnsigned32 ENDP

;;
;; ASCII PRINTING
;;

space PROC
  push dx
  mov dl, ' '
  call PutChar
  pop dx
  ret
space ENDP

newline PROC
  push dx
  mov dl, 0Ah	; Print a '\n'
  call PutChar
  pop dx
  ret
newline ENDP

pipe PROC
  push dx
  mov dl, '|'
  call PutChar
  pop dx
  ret
pipe ENDP

;;
;; HEXADECIMAL PRINTING
;;

HexOutNybble PROC
  ; takes:
  ; dl -> Byte whose low nybble we will print
  ; causes -> prints the nybble
  push dx
  and dl, 0Fh	; Clear high bits of DL
  add dl, '0'	; Convert DL to ASCII
  cmp dl, '9'	; is DL numeric? Only test if DL <= '9'
		; (we ensured DL >= '0' on with the prev instr)

  jle print
  add dl, 7	; DL isn't numeric, skip garbage between '9' and 'A'
print:
  call PutChar
  pop dx
  ret
HexOutNybble ENDP

;; TODO: copy HexOutByte

HexOutSplit PROC
  ; IN: ax -> number of bytes to print before splitting
  ;     cx -> number of bytes to print
  ;     ds:dx -> buffer
  ; OUT: prints DS:DX

  push bx
  push cx
  push dx

  mov bx, cx		; Store CX in BX.
  shr bx		; Divide BX by 2.
  cmp bx, ax		; Is BX < AX?

  jl print_remainder	; goto print_remainder if true.
  sub cx, ax		; Subtract AX from CX.
			; This allows execution to fall into
			; print_remainder safely

  push cx
  mov cx, ax		; Follow HexOut calling convention
  call HexOut		; Print AX bytes
  pop cx

  add dx, ax		; Advance buffer beyond split

print_remainder:
  call HexOut		; Print CX bytes

  pop dx
  pop cx
  pop bx
  ret
HexOutSplit ENDP

HexOut PROC
  ; IN: cx -> number of bytes
  ;     ds:dx -> buffer
  ; OUT: prints DS:DX

  push bx
  push cx
  push dx

  mov bx, dx
top:
  mov dl, [bx]
  call HexOutByte

  inc bx
  loop top

  pop dx
  pop cx
  pop bx
  ret
HexOut ENDP


