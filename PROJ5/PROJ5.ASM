TITLE	proj5.asm

; Author: Nathaniel Symer
; Last update: 10.12.2016
;
; 3 functions project

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code

INCLUDE console.inc
INCLUDE utils.inc

;; TODO:
; 1. Safety
; 2. Insert
SafeRead PROC
  ; Read chars from the KB and place them
  ; in a supplied buffer
  ; IN: [bp+6] -> offset of the buffer in the Data segment
  ;     [bp+4] -> buffer length
  ; OUT: reads ACIIZ string into input buffer.

  push bp
  mov bp, sp

  push ax
  push bx
  push cx
  push dx
  push si

  xor cx, cx
  mov si, [bp+6]	; Copy buffer offset to SI
  mov bx, si		; Mov SI to BX

top:
  call ReadTTY		; Read a keycode into DH and ASCII code into DL
  cmp dh, 0Eh		; is it a backspace?
  je backspace
  cmp dh, 4Bh 		; is it a left arrow?
  je left
  cmp dh, 4Dh		; is it a right arrow
  je right
  cmp dh, 2Eh		; is it a control-c?
  je ctrlc
  cmp dh, 1Ch		; is it an enter?
  je done
char:
  push si
  push di
  push cx
  push dx
  mov dx, -1		; Set up _memcpy step
  add si, cx		; Move SI to the last index in the str
  dec si		;
  mov di, si		; Set up DI one byte farther away from
  inc di		; beginning of buffer

  push si		; |
  add si, cx		; |
  sub si, bx		; | Calculate the number of chars between the
  mov cx, si		; | cursor and the end of the string.
  pop si		; |

  call _memcpy          ; do the copy
  pop dx
  pop cx
  pop di
  pop si

  mov [bx], dl		; Write ASCII value to buffer 
  inc cx		; increment str length
  call WriteBufTTY
  jmp top 
right:
  ; TODO: prevent exceeding buffer here
  inc bx
  push cx
  mov cx, 1
  call MoveCursor
  pop cx
  jmp top
backspace:
  push cx		; |
  xor cx, cx		; |
  mov cl, -1		; | Move cursor back a character
  call MoveCursor	; |
  pop cx		; |

  push cx

  push si		; |
  add si, cx		; |
  sub si, bx		; | Calculate the number of chars between the
  mov cx, si		; | cursor and the end of the string.
  pop si		; |

  push si
  push di
  push dx
			; | Shift chars after BX back one byte to signify backspace
  mov si, bx		; Move BX into SI
  mov di, si		; Move SI into DI
  dec di		; Decrement DI
  mov dx, 1		; Set _memcpy step amount 
  call _memcpy		; do the copy
  mov bx, di            ; Move DI into BX
  pop dx
  pop di
  pop si

  call WriteBufTTY

  pop cx

  dec cx

  jmp top
left:
;  cmp bx, si
;  jle skipl
  dec bx
  push cx
  mov cx, -1
  call MoveCursor
  pop cx
skipl:
  jmp top
done:
  add si, cx
  mov ax, 0
  mov [si], ax		; null terminate
  sub si, bx
  mov cx, si
  call MoveCursor
  pop si
  pop dx
  pop cx
  pop bx
  pop ax
  pop bp
  ret 4
ctrlc:
  mov ax, 4C00h
  int 21h
SafeRead ENDP

FastMultiply PROC
  ; IN: ax -> a multiplicand, 16 bit unsigned
  ;     [bp+4] -> another multiplicand, 16 bit unsigned
  ; OUT: dx:ax -> product of AX and [bp+4]
  push bp
  mov bp, sp

  push bx
  push cx

  cmp ax, 0
  je done

  mov cx, ax		; Copy first multiplicand out of product reg
  mov bx, [bp+4]	; Load second multiplicand into BX
  xor ax, ax		; clear product
  xor dx, dx
top:
  cmp bx, 0		; If there is no more multiplying to do
  je done		; Return
  add ax, cx		; This add we will aways do
  jnc @1		; If there is a carry
  inc dx		; Increment DX
@1:
  shr bx, 1		; Divide BX by two
  jnc lastadd
  add ax, cx		; Add once for the carry
  jnc @2
  inc dx
@2:
lastadd:
  add ax, cx
  jmp top

done:
  pop cx
  pop bx

  pop bp
  ret 2
FastMultiply ENDP

MyDelay PROC
  ; IN: ax -> Delay in ms
  push bp
  mov bp, sp
  sub sp, 4	; Allocate stack variables:
		;	[bp] -> dword, time since midnight
		; 		that indicates the end of the delay

  push si			; Push SI
  xor si, si			; So we can clear it
  push si			; and use it for the high bytes in adding
				; AX to the value in DX:AX after call _gettime
  push ax			; Push delay for add32
  call _gettime			; Get the time since midnight.
  call _add32			; Add delay to the time.
  pop si			; We can pop the SI from earlier.
  mov [bp], dx			; Move sum into
  mov [bp-2], ax		; dword stack var.

top:
  call _gettime			; Get time since midnight
  cmp dx, word ptr [bp]		; Are the high bytes of the current time
				; less than the high bytes of the time
				; after the delay?

  jb top			; Try again
  cmp ax, word ptr [bp-2]	; Like previous, but with low bytes
  jb top			; Try again

  add sp, 4
  pop bp
  ret
MyDelay ENDP

_gettime PROC
.data
mspercs WORD 10
mspers WORD 1000
msperm WORD 60000
sperh WORD 3600
.code
  ; OUT: dx:ax -> number of miliseconds since midnight

  push bx
  push cx
  push si

  mov ah, 2Ch
  int 21h

  mov bx, dx			; Protect seconds/100seconds from mul instruction

  xor ax, ax			; Clear DX:AX (sum)
  xor dx, dx			;
  mov al, bl			; Move BL into AL
  mov si, OFFSET mspercs	; Load our conversion factor
  mul word ptr [si]		; and convert.
  push dx			;
  push ax			; push the product

  xor ax, ax
  xor dx, dx
  mov al, bh
  mov si, OFFSET mspers
  mul word ptr [si]
  push dx
  push ax

  xor ax, ax
  xor dx, dx
  mov al, cl
  mov si, OFFSET msperm
  mul word ptr [si]
  push dx
  push ax

  xor ax, ax
  xor dx, dx
  mov al, ch
  mov si, OFFSET sperh
  mul word ptr [si]
  mov si, OFFSET mspers
  mul word ptr [si]

  ; add accumulated parts
  call _add32
  call _add32
  call _add32

  pop si
  pop cx
  pop bx

  ret
_gettime ENDP

_add32 PROC
  ; STDCALL
  ; IN: [bp+6]:[bp+4] -> a 32-bit number
  ;     dx:ax	      -> another 32-bit number
  ; OUT: dx:ax	      -> sum
  push bp
  mov bp, sp

  add dx, [bp+6]	; Add high bytes
  adc ax, [bp+4]	; Add low bytes
  jnc done		; Skip high byte increment if we don't have a carry
  inc dx		; Increment high bytes to satisfy carry
done:
  pop bp
  ret 4
_add32 ENDP

_atoi PROC
  ; IN: DS:SI -> Pointer to ASCIIZ string on data segment
  ; OUT: ax -> read unsigned word
  mov ax, 0
  ret
_atoi ENDP

_itoa PROC
  ; IN: AX -> unsigned word
  ;     DS:SI -> buffer
  ; OUT: DS:SI will contain AX printed as ASCIIZ.
  push ax
  mov ax, 0
  mov [si], ax
  pop ax
  ret
_itoa ENDP

main PROC
.data
buf BYTE 128 DUP(0)
.code
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov cx, 128		; setup buffer size

  mov si, OFFSET buf	; setup buffer ptr
  push si		; |
  push cx		; | setup params for SafeRead
  call SafeRead		; Reads into DS:SI
  mov dx, si
  call WriteString
;  call _atoi		; which is used to calculate a word in AX
;  push ax		; which is pushed.

;  mov si, OFFSET buf
;  push si
;  push cx
;  call SafeRead
;  call _atoi
;  push ax

;  call FastMultiply	; Multiply pushed AXes.
;  call _itoa		; Turn product into a string.
;  mov dx, si		; |
;  call WriteString	; | From Irvine16

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main






