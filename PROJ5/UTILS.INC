;; UTILS.INC
;; Nathaniel Symer
;;
;; Contains a variety of useful procedures
;; that would normally be provided by a standard library

_memcpy PROC
  ; IN: ds:si -> source buffer
  ;     ds:di -> destination buffer
  ;     cx    -> number of units to copy
  cmp cx, 0
  je done

  push ax
  push cx
  push di
  push si
top:
  mov al, byte ptr [si]
  mov byte ptr [di], al
  inc si
  inc di
  loop top
  pop si
  pop di
  pop cx
  pop ax
done:
  ret
_memcpy ENDP

_memcpyreverse PROC
  ; IN: ds:si -> source buffer
  ;     ds:di -> destination buffer
  ;     cx    -> number of units to copy
  cmp cx, 0
  je done

  push ax
  push cx
  push di
  push si
top:
  mov al, byte ptr [si]
  mov byte ptr [di], al
  dec si
  dec di
  loop top
  pop si
  pop di
  pop cx
  pop ax
done:
  ret
_memcpyreverse ENDP

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
  push bx
  push cx
  push dx
  push si
  xor cx, cx
  xor ax, ax
  mov bx, 10
top:
  mov cl, [si]
  cmp cl, 0
  je done
  cmp cl, '0'
  jb done
  cmp cl, '9'
  ja done
  inc si
  sub cl, '0'
  mul bx
  add ax, cx
  jmp top
done:
  pop si
  pop dx
  pop cx
  pop bx
  ret
_atoi ENDP

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


