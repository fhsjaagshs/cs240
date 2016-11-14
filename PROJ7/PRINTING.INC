;; Nathaniel Symer
;; printing.inc
;;
;; Basic procedures to print chars

print_urhc PROC
  ; IN: stack parameter: offset of ASCII string to print in CS
  ;	CX: string length
  push bp
  mov bp, sp

  push ax
  push bx
  push dx
  push bp
  push es

  mov bp, ss:[bp+2]

  mov ax, 1300h
  mov bx, 000Fh	; Page 0, white-on-black
  mov dx, 0050h	; print in first line, right justify
  sub dl, cl	; Move the cursor over.
  push cs
  pop es
  int 10h

  pop es
  pop bp
  pop dx
  pop bx
  pop ax

  pop bp
  ret 2
print_urhc ENDP

print_console PROC
  ; IN: stack parameter: offset of ASCII string to print in CS
  ;     CX -> string length
  push bp
  mov bp, sp

  push cx
  push dx
  push si

  mov si, ss:[bp+4]

pc_top:
  cmp cx, 0
  je pc_done
  mov dl, cs:[si]
  inc si
  dec cx
  call print_console_char
  jmp pc_top

pc_done:
  pop si
  pop dx
  pop cx

  pop bp
  ret 2
print_console ENDP

print_console_char PROC
  ; IN: DL -> char to print
  push ax
  mov ah, 0Eh	; Print TTY
  mov al, dl
  int 10h
  pop ax
  ret
print_console_char ENDP
