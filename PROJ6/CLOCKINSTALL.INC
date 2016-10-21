;; CLOCKINSTALL.INC
;;
;; Logic for installing the necessary handlers to handle clock logic.

INCLUDE inthdl.inc

orig_handle08 DWORD 0
orig_handle09 DWORD 0

handle08 PROC
  pushf
  call cs:[orig_handle08]
  call ontimer
  iret
handle08 ENDP

handle09 PROC
  pushf
  call cs:[orig_handle09]
  call onkeypress
  iret
handle09 ENDP

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

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
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

  mov ax, word ptr cs:orig_handle08+2
  push ax
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

  push cs		; push the code segment
  pop es		; and pop it into the extra segment
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

  mov ax, word ptr cs:orig_handle09+2
  push ax
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

