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

