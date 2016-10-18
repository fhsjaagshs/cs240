;; inthdl.inc
;; Nathaniel Symer
;;
;; Utilities for installing/uninstalling
;; interrupt handlers

installhandler PROC
  ; IN ->  al: interrupt number
  ;        es: segment of new handler
  ;        dx: offset of new handler
  ; OUT -> bx: offset of old handler.
  ;        es: segment of old handler
  ; CAUSES -> installs the new handler.

  push ax
  push ds

  push es	; Push segment of new handler

  mov ah, 35h	; Read IVT
  int 21h	; sets BX and ES.

  pop ds	; Pop seg of new handler into where DOS expects it.
  mov ah, 25h	; Set the entry in the IVT.
  int 21h	; other arg is (DS:DX)

  pop ds
  pop ax

  ret
installhandler ENDP

