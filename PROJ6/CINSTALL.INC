;; CINSTALL.INC
;; Logic for installing the necessary handlers to handle clock logic
;; using CLOGIC.INC.

installinthandlers PROC
  call install08
  call install09
  ret
installinthandlers ENDP

uninstallinthandlers PROC
  call uninstall08
  call uninstall09
  ret
uninstallinthandlers ENDP

install08 PROC
  push es
  push ax
  push bx
  push dx

  push cs				; push the code segment
  pop es				; and pop it into the extra segment
  mov al, 08h
  mov dx, OFFSET cs:handle08
  call installhandler
  mov word ptr cs:orig_handle08, bx
  mov word ptr cs:orig_handle08+2, es

  pop dx
  pop bx
  pop ax
  pop es
  ret
install08 ENDP

uninstall08 PROC
  push es
  push ax
  push bx
  push dx

  push word ptr cs:orig_handle08+2
  pop es
  mov al, 08h
  mov dx, word ptr cs:orig_handle08
  call installhandler

  pop dx
  pop bx
  pop ax
  pop es
  ret
uninstall08 ENDP

install09 PROC
  push es
  push ax
  push bx
  push dx

  push cs				; push the code segment
  pop es				; and pop it into the extra segment
  mov al, 09h
  mov dx, OFFSET cs:handle09
  call installhandler
  mov word ptr cs:orig_handle09, bx
  mov word ptr cs:orig_handle09+2, es

  pop dx
  pop bx
  pop ax
  pop es
  ret
install09 ENDP

uninstall09 PROC
  push es
  push ax
  push bx
  push dx

  push word ptr cs:orig_handle09+2
  pop es
  mov al, 09h
  mov dx, word ptr cs:orig_handle09
  call installhandler

  pop dx
  pop bx
  pop ax
  pop es
  ret
uninstall09 ENDP

installhandler PROC
  ; IN ->  al: interrupt number
  ;        es: segment of new handler
  ;        dx: offset of new handler
  ; OUT -> bx: offset of old handler.
  ;        es: segment of old handler
  ; CAUSES -> installs the new handler.

  push ax
  push ds

  push es		; Push segment of new handler
			; This must happen before reading
			; the old handler because ES is overwritten.

  mov ah, 35h		; Read IVT entry # AL
  int 21h		; and set BX and ES.

  pop ds		; Pop segment of new handler into DS.
  mov ah, 25h		; Set the entry in
  int 21h		; the IVT to (DS:DX).

  pop ds
  pop ax

  ret
installhandler ENDP

