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

PutNChar PROC
  ; IN: dl -> char to print
  ;     cx -> number of times to print DL
  ; OUT: prints DL CX times
  cmp cx, 0
  je done

  push ax
  push cx
  mov ax, 0200h	; DOS interrupt for printing
l:
  int 21h	; Call DOS interrupt
  loop l
  pop cx
  pop ax
done:
  ret
PutNChar ENDP

PutCharHuman PROC
  ; IN: dl -> char to print human-friendly
  ; OUT: prints it
  cmp dl, '!'	; Is DL gte than 1st printable char?
  jb unprintable
  cmp dl, '~'	; Is DL lte than last printable char?
  ja unprintable
  call PutChar	; Print our character normally; Human-readable
  jmp done
unprintable:
  call redDot	; Print a red period because it's not human readable.
done:
  ret
PutCharHuman ENDP

PrintHumanReadable PROC
  ; IN: cx -> number of chars
  ;     ds:dx -> buffer
  ; OUT: prints human readable characters.
  push cx
  push dx
  push si

  mov si, dx		; Use source index instead of DX

top:
  mov dl, [si]		; Read a byte from our buffer.
  call PutCharHuman	; Print it human-readable.
  inc si		; Advance buffer pointer.
  loop top

  pop si
  pop dx
  pop cx
  ret
PrintHumanReadable ENDP

PrintMine PROC
; IN: DS:DX -> string
  push dx
  push si

  mov si, dx		; Use source index instead of DX

top:
  mov dl, [si]		; Read a byte from our buffer.
  cmp dl, 0		; Is it a null?
  je done
  call PutChar		; Print it human-readable.
  inc si		; Advance buffer pointer.
  jmp top

done:
  pop si
  pop dx
  ret
PrintMine ENDP

PrintUnsigned32 PROC
  ; IN: ds:dx -> ptr to 32-bit number in memory
  ; OUT: prints it!

  push ax
  push bx
  push cx
  push dx
  push si

  xor cx, cx
  mov si, dx
  mov ax, [si+2]
  mov dx, [si]
top:
  call DivMod32_10
  push bx
  inc cx
  cmp ax, 0
  je low0
  jmp top
low0:
  cmp dx, 0
  ja top

  mov ax, 8
  sub ax, cx

  push cx
  mov cx, ax
  mov dl, '0'
  call PutNChar
  pop cx

l:
  pop dx
  add dl, '0'
  call PutChar
  loop l

  pop si
  pop dx
  pop cx
  pop bx
  pop ax

  ret
PrintUnsigned32 ENDP

DivMod32_10 PROC
  ; IN: ax -> low bytes
  ;     dx -> high bytes
  ; OUT: ax -> low bytes quotient
  ;      dx -> high bytes quotient
  ;      bx -> remainder
  ; Divides (DX:AX)

  push cx
  mov cx, 10

  ; high bytes
  push ax
  mov ax, dx	; Move DX into AX for division
  xor dx, dx	; Clear DX
  div cx	; Divide AX by 10, we can't get remainder in high bytes.
  mov dx, ax	; Move AX back into DX
  pop ax

  ; low bytes
  push dx
  xor dx, dx	; Clear DX
  div cx	; Divide AX by 10
  mov bx, dx	; Move DX (remainder) into BX
  pop dx

  pop cx

  ret
DivMod32_10 ENDP

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
  ; **** COPIED FROM PREVIOUS WORK
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

HexOutByte PROC
  ; **** COPIED FROM PREVIOUS WORK
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

PrintNHexChars PROC
  ; IN: ds:dx -> buffer
  ;     cx    -> N
  ; OUT: prints ds:dx

  push si
  push dx
  push cx
  mov si, dx
l:
  mov dl, [si]
  call HexOutByte
  inc si
  call space
  loop l
  pop cx
  pop dx
  pop si
  ret
PrintNHexChars ENDP

HexOutSplit PROC
  ; IN: ax -> number of bytes to print before splitting
  ;     bx -> line length
  ;     cx -> number of bytes to print
  ;     ds:dx -> buffer
  ; OUT: prints DS:DX

  push ax
  push bx
  push cx
  push dx
  push si

  cmp cx, ax
  jb after
  ; print AX chars
  push cx
  mov cx, ax
  call PrintNHexChars
  pop cx
  sub cx, ax
  sub bx, ax
  call space
after:
  call PrintNHexChars
  sub bx, cx
  
  cmp bx, 0
  je finish

  mov cx, bx
l2:
  call space
  call space
  call space
  loop l2

finish:
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  ret
HexOutSplit ENDP
