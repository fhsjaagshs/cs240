; FILES.INC
;
; Manage open files

; Register conventions
; These conventions are roughly followed by
; the below procedures.
; AX -> File handle
; BX -> Error code if CF is set. Otherwise garbage.
; CX -> Count of bytes
; DS:DX -> Buffer; Contents may be modified

; TODO: consider using BX for file handle

FOpen PROC
  ; IN: DS:DX -> ASCIIZ file name
  ; OUT: AX, BX (see conventions)
  xor bx, bx	; Clear error in BX
  mov ax 3D00h	; DOS interrupt code to open a file
  int 21h	; DOS interrupt
  jc error
  ret
error:
  xor ax, ax	; clear AX
  mov bx, ax	; setup error code return value
  stc		; set the carry flag to be extra sure
  ret
FOpen ENDP

FClose PROC
  ; Causes file handle specified by AX to be closed.
  ; IN: ax -> see conventions
  ; OUT: bx -> see conventions
  push bx	; save value of BX
  mov bx, ax	; move file handle # to BX, effectively saving it (avoid a push/pop)
  mov ah, 3Eh	; setup DOS interrupt code
  int 21h	; DOS interrupt
  mov ax, bx	; restore value of AX
  pop bx	; restore value of BX
  ret
FClose ENDP

FReadAdv PROC
  ; Reads at most CX bytes from a file.
  ; After reading, AX is advanced by CX.
  ; IN: ax -> see conventions
  ;     cx -> # of bytes to read (see conventions)
  ;     ds:dx -> buffer to read into (see conventions)
  ; OUT: cx -> number of bytes read (see conventions). Zero
  ;            on error
  ;      bx -> see conventions
  ;      ds:dx -> buffer now contains bytes from file.

  push ax

  mov bx, ax	; setup file handle arg
  mov ax, 3F00h	; DOS read interrupt code.
  int 21h	; DOS interrupt
  jc error

  mov cx, ax	; Move number of read bytes to output reg
  xor bx, bx	; clear error
  jmp done
error:
  mov bx, ax
  stc
done:
  pop ax
  ret
FReadAdv ENDP






