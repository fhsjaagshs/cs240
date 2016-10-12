;; UTILS.INC
;; Nathaniel Symer
;;
;; Contains a variety of useful procedures
;; that would normally be provided by a standard library

_memcpy PROC
  ; IN: ds:si -> source buffer
  ;     ds:di -> destination buffer
  ;     dx    -> copy step amount (signed)
  ;     cx    -> number of units to copy
  push ax
  push cx
  push di
  push si

top:
  mov ax, [si]
  mov [di], ax
  add si, dx
  add di, dx
  loop top

  pop si
  pop di
  pop cx
  pop ax
  ret
_memcpy ENDP

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


