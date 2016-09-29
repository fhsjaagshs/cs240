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
  push cx
  push dx
  push si

  mov si, dx

top:
  mov dl, [si]
  inc si
  cmp dl, '!'	; First printable char
  jb unprintable
  cmp dl, '~'	; Last printable char
  ja unprintable
  call PutChar
  loop top
  jmp done
unprintable:
  call redDot
  loop top
done:
  pop si
  pop dx
  pop cx
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
  mov dl, 0Dh	; Print a '\r'
  call PutChar
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

redDot PROC
  push dx
  mov dl, '.'
  call PutChar
  pop dx
  ret
redDot ENDP

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

HexOutByte PROC
  ; takes:
  ; dl -> byte to print as hex
  ; causes: prints dl as hex

  push dx

  mov dh, dl		; Copy DL to DH for below algorithm

  ; the below algorithm:
  ; we read the character into both DL
  ; and DH so that it appears like so:
  ; DX: <highnybble><lownybble><highnybble><lownybble>
  ;
  ; then we shift DX right by four:
  ; DX: 0000<highnybble><lownybble><highnybble>
  ;
  ; then `call HexOutNybble` to print the high nybble
  ;
  ; shifting right by 4 again causes:
  ; DX: 00000000<highnybble><lownybble>
  ;
  ; then `call HexOutNybble` to print the low nybble.
  ;
  ; Now we've printed the byte in order.

  push cx
  mov cl, 4		; (for the shr instruction)
  shr dx, cl		; Shift dx right 4 bits to
  call HexOutNybble	; print the high nybble.
  shr dx, cl		; Shift dx right 4 more bits to
  call HexOutNybble	; print the low nybble.
  pop cx
  pop dx
  ret
HexOutByte ENDP

HexOutSplit PROC
  ; IN: ax -> number of bytes to print before splitting
  ;     cx -> number of bytes to print
  ;     ds:dx -> buffer
  ; OUT: prints DS:DX

  push bx
  push cx
  push dx

  push cx
  shr cx, 1		; Divide CX by 2.
  cmp cx, ax		; Is CX < AX?
  pop cx		; (doesn't modify flags)
  jl print_remainder	; goto print_remainder if true.
  sub cx, ax		; Subtract AX from CX.
			; This allows execution to fall into
			; print_remainder safely

  push cx
  mov cx, ax		; Follow HexOut calling convention
  call HexOut		; Print AX bytes
  pop cx

  call space

  add dx, ax		; Advance buffer beyond split

print_remainder:
  call HexOut		; Print CX bytes

  cmp ax, cx		; If we didn't print AX bytes again
  je done

  push ax
  sub ax, cx		; Calculate how many
  mov cx, ax		; spaces we need to pad the end into CX
lp:
  call space
  loop lp
  pop ax

done:
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
  call space

  inc bx
  loop top

  pop dx
  pop cx
  pop bx
  ret
HexOut ENDP


