; FILES.INC
; Nathaniel Symer
;
; DOS file operations.

; Register conventions
; These conventions are roughly followed by
; the below procedures.
; AX -> Error code if CF is set. Otherwise 0.
; BX -> File handle
; CX -> Count of bytes
; CS:DX -> Buffer; Contents may be modified

; TODO: consider using BX for file handle

FOpen PROC
  ; IN: CS:DX -> ASCIIZ file name
  ; OUT: AX, BX (see conventions)
  push ds
  push cs
  pop ds
  mov ax, 3D00h	; DOS interrupt code to open a file
  int 21h	; DOS interrupt
  pop ds
  jc error
  mov bx, ax	; follow conventions, file handle in BX
  xor ax, ax	; clear error
  ret
error:
  xor bx, bx	; clear file handle in BX
  stc		; set the carry flag to be extra sure
  ret
FOpen ENDP

FClose PROC
  ; Closes a file handle
  ; IN: bx -> see conventions
  ; OUT: ax -> see conventions
  mov ax, 3E00h	; DOS interrupt code for closing a file
  int 21h	; DOS interrupt
  ret
FClose ENDP

FReadAdv PROC
  ; Reads at most CX bytes from a file.
  ; After reading, AX is advanced by CX.
  ; IN: bx -> see conventions
  ;     cx -> # of bytes to read (see conventions)
  ;     cs:dx -> buffer to read into (see conventions)
  ; OUT: ax -> see conventions
  ;      cx -> number of bytes read (see conventions). Zero
  ;            on error
  ;      cs:dx -> buffer now contains bytes from file.

  mov ax, 3F00h	; DOS read interrupt code.
  push ds
  push cs
  pop ds
  int 21h	; DOS interrupt
  pop ds
  jc done	; exit on error
  mov cx, ax	; Move number of read bytes to output reg
  mov ax, 0	; clear error, avoid modifying flags
done:
  ret
FReadAdv ENDP

