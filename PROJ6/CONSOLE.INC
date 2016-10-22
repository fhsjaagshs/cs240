;; cursor.inc
;;
;; Nathaniel Symer
;;
;; Provides a console interface
;; implemented using BIOS interrupts.

MoveCursor PROC
  ; IN: cl -> number of characters to move (signed)
  ; OUT: moves the cursor left or right accordingly

  push ax
  push bx
  push dx

  call CursorPosition	; Get cursor position in (DL, DH)
  call ScreenProps	; Get screen width in AH and page # in BH
  add dl, cl		; Advance the cursor
  cmp dl, ah		; IF DL >= AH (column count)
  jge advrow		; Move forward a row.
  cmp dl, 0		; IF DL >= 0?
  jge afterwrap		; Don't change rows.
  			; ELSE to decrementing a row.
backrow:
  cmp dh, 0		; Are we offscreen?
  jl backwardoff	; If yes, then we should exit.
  dec dh		; Decrement the row.
  add dl, ah		; Set the column given movement.
  cmp dl, 0		; IF DL < 0
  jl backrow		; then repeat backrow.
  jmp afterwrap
advrow:
  cmp dh, 24		; Are we offscreen?
  jg forwardoff		; if yes, then we should exit.
  ; TODO: I would have loved to be able to scroll the
  ; screen up instead of jg forwardoff.
  inc dh		; Increment the row.
  sub dl, ah		; Set the column number given movement.
  cmp dl, ah		; IF DL > AH (# columns on screen)
  jge advrow		; then repeat advrow.
afterwrap:
  call MoveCursorTo
  pop dx
  pop bx
  pop ax
  ret
forwardoff:		; When the cursor is off the bottom of the screen.
  mov dh, 24
  mov dl, ah
  dec dl
  jmp afterwrap
backwardoff:		; When the cursor is off the top of the screen.
  mov dx, 0
  jmp afterwrap
MoveCursor ENDP

MoveCursorTo PROC
  ; IN: DH -> row
  ;     DL -> column
  ; Moves the cursor to (column, row)
  push ax
  push sp
  push bp
  push si
  push di

  call ScreenProps
  mov ax, 0200h
  int 10h

  pop di
  pop si
  pop bp
  pop sp
  pop ax
  ret
MoveCursorTo ENDP

ReadConsole PROC
  ; IN: nothing
  ; OUT: dh -> scancode of pressed key
  ;      dl -> ASCII char of pressed key
  push ax
  mov ah, 00h		; BIOS int 16h function code for reading key presses
  int 16h		; Call BIOS
  mov dx, ax		; Move scancode and char into DH and DL, respectively
  pop ax
  ret
ReadConsole ENDP

WriteConsole PROC
  ; IN: dl -> char to write
  ; OUT: Writes DL at the cursor's current
  ;      position. The cursor is then advanced
  ;      one position.
  push cx
  mov cx, 1		; Print the char once.
  call WriteNConsole
  pop cx
  ret
WriteConsole ENDP

WriteNConsole PROC
  ; IN: dl -> char to write
  ;     cx -> number of times to print the char.
  ; OUT: Writes DL at the cursor's current
  ;      position. The cursor is then advanced
  ;      one position.

  push ax
  push bx
  push cx
  push sp
  push bp
  push si
  push di

  push ax
  call ScreenProps	; Put the page number in BH.
  pop ax
  mov al, dl		; Put the char to print in AL.
  mov ah, 0Ah		; BIOS interrupt code to print without attrs.
  int 10h		; Call BIOS.

  call MoveCursor	; Move cursor accordingly.

  pop di
  pop si
  pop bp
  pop sp
  pop cx
  pop bx
  pop ax
  ret
WriteNConsole ENDP

WriteManyAt PROC
  ; stdcall calling conventions
  ; IN: Parameters (in order)
  ;     1. segment
  ;     2. offset
  ;     3. count
  ; IN: dl -> column
  ;     dh -> row
  ; Prints chars without moving the cursor.
  push bp
  mov bp, sp

  push ax
  push bx
  push cx
  push bp
  push si
  push di
  push es

  call ScreenProps	; Load page number into BH

  mov cx, ss:[bp+8]	; Move the count into CX
  mov es, ss:[bp+4]	; Move the segment into ES
  mov bp, ss:[bp+6]	; Move the offset into BP

  mov bl, 0Fh		; White on black attributes
  mov ax, 1300h		; use subservice 00h, don't update cursor
  int 10h		; Print CX chars at ES:BP

  pop es
  pop di
  pop si
  pop bp
  pop cx
  pop bx
  pop ax

  mov sp, bp
  pop bp
  ret 6
WriteManyAt ENDP

ScreenProps PROC
  ; IN: nothing
  ; OUT: AL -> video mode
  ;      AH -> number of character columns per line
  ;      BH -> Active display page number
  push sp
  push bp
  push si
  push di
  mov ax, 0F00h
  int 10h
  pop di
  pop si
  pop bp
  pop sp
  ret
ScreenProps ENDP

CursorPosition PROC
  ; IN: nothing
  ; OUT: dl -> column
  ;      dh -> row

  push ax
  push cx
  push sp
  push bp
  push si
  push di

  call ScreenProps	; Get the page number in BH
  mov ax, 0300h		; Setup BIOS interrupt code & clear extra
			; side effects from calling ScreenProps
  int 10h

  pop di
  pop si
  pop bp
  pop sp
  pop cx
  pop ax
  ret
CursorPosition ENDP






