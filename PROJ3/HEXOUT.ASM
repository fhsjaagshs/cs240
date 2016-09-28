TITLE	hexout.asm

; Author: Nathaniel Symer
; Last update: 9.18.2016
;
; Writes an array out as hexadecimal

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
mybytes BYTE 04h,5Fh,0DAh	; Bytes we are going to print
len WORD len-mybytes		; Use asm hack to get len of mybytes
.code

HexOutNybble PROC
; takes:
; dl -> least significant nybble as input
; causes -> prints said nybble in hex
  push ax
  push dx
  and dl, 0Fh	; Clear high bits
  add dl, '0'	; Convert dl to ASCII char
  cmp dl, '9'   ; is DL numeric? Only test if dl <= ASCII 9
		; because we ensured dl >= ASCII 0 on the previous line
  jle print
  add dl, 7     ; dl isn't numeric, skip garbage between ASCII 9 and ASCII A
print:
  mov ax, 0200h
  int 21h
  pop dx
  pop ax
  ret
HexOutNybble ENDP

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

HexOut PROC
  ; takes:
  ; bx -> points to array
  ; cx -> number of elements on the array
  ; causes: prints the array as hex, spacing out the chars
  ;
  ; amounts to the Haskell pseudocode (without printing spaces):
  ; (map HexOutByte (mklist bx cx))

  cmp cx, 0		; BASE CASE: we ran out of bytes
  jz done		; so we must return.

  push cx
  push dx

  mov dl, [bx]		; read the next byte
  call HexOutByte	; and print it as hex

  mov dl, ' '		; Print the space after
  mov ax, 0200h		; the hex byte via DOS
  int 21h		; interrupt 21h

  dec cx		; Advance our ptr by decreasing the count (CX) by 1
  inc bx		; and moving our ptr (BX) forward by 1.
  call HexOut

  pop dx
  pop cx
done:
  ret
HexOut ENDP

main PROC
  mov ax, @data 		  ; setup the data
  mov ds, ax			  ; segment register

  mov bx, OFFSET mybytes
  mov cx, len
  call HexOut

  mov ax, 4C00h			  ; Exit 0 with DOS func 4C
  int 21h
main ENDP

END main







