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
  push ax
  push cx

  mov ax, cx

  push bx
  sub bx, si		; BX - SI = chars up to cursor
  sub cx, bx		; Store chars after cursor in CX
  pop bx

  add si, ax
  mov di, si		; DI points to byte beyond end of string
  dec si		; SI points to byte at end of string

  call _memcpyreverse   ; do the copy

  pop cx
  pop ax
  pop di
  pop si

  mov [bx], dl		; Write ASCII value to buffer
  inc cx		; increment str length
  call WriteBufTTY      ; everything shifted right, so we have to re-print
right:
  ; TODO: prevent exceeding buffer here
  inc bx
  push cx
  mov cl, 1
  call MoveCursor
  pop cx
  jmp top
backspace:
  dec bx
  push cx
  mov cl, -1
  call MoveCursor
  pop cx

  push cx

  push bx
  sub bx, si		; BX - SI = chars up to cursor
  sub cx, bx		; Store chars after cursor in CX
 ; dec cx		; Store number of chars not to be deleted in CX.
			; This value will be used with _memcpy below.
  pop bx

  push si
  push di
  mov si, bx
  inc si		; SI points to first char not to be deleted.
  mov di, bx		; DI points to the char to be deleted.
  call _memcpy
  add di, cx
  dec di
  mov cx, 0
  mov [di], cx
  pop di
  pop si
  pop cx

  push bx
  mov bx, si
  call WriteBufTTY	; Write str at SI to console
  pop bx

  dec cx
  jmp top
left:
;  cmp bx, si
;  jle skipl
  dec bx
  push cx
  mov cl, -1
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

