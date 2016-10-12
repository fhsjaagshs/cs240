;; cursor.inc
;;
;; Nathaniel Symer
;;
;; Provides utilities for controlling the cursor via BIOS

MoveCursor PROC
  ; IN: cl -> number of characters to move (signed)
  ; OUT: moves the cursor accordingly
  push ax
  push bx
  push dx
  push sp
  push bp
  push si
  push di

  call CursorPosition	; Puts cursor position in (DL,DH)
  add dl, cl		; Advance the cursor

  ; At this point
  ; Negative DL: move back a row
  ; DL > AL:	 move forward a row
  ; otherwise:   fine

  call ScreenWidth	; Get screen width in AL
  cmp dl, 0		; Is DL < 0?
  jl backrow		; go to backrow if true
  cmp dl, al		; Is DL > AL (column count)
  jg advrow		; go to advrow if true
  jmp afterwrap
backrow:
  cmp dh, 0
  je afterwrap
  dec dh
  mov dl, al
  jmp afterwrap
advrow:
  mov dl, 0
  inc dh
afterwrap:
  call PageNumber
  mov ax, 0200h
  int 10h
  pop di
  pop si
  pop bp
  pop sp
  pop dx
  pop bx
  pop ax
  ret
MoveCursor ENDP

WriteBufTTY PROC
  ; IN ds:bx -> buffer
  ;    cx    -> size of buffer
  push bx
  push cx
  push dx
  cmp cx, 0
  je after
top:
  mov dl, [bx]
  inc bx
  call WriteTTY
  push cx
  mov cl, 1
  call MoveCursor
  pop cx
  loop top
after:
  pop dx
  pop cx
  pop bx

  push cx
;  dec cx
  neg cx
  call MoveCursor
  pop cx

  ret
WriteBufTTY ENDP

ReadTTY PROC
  ; IN: nothing
  ; OUT: dh -> scancode of pressed key
  ;      dl -> ASCII char of pressed key
  push ax
  mov ah, 00h		; BIOS int 16h function code for reading key presses
  int 16h		; Call BIOS
  mov dx, ax
  pop ax
  ret
ReadTTY ENDP

WriteTTY PROC
  ; IN: dl -> char to write
  ; OUT: writes DL to the TTY at the cursor's current position
  push ax
  push bx
  push cx
  push sp
  push bp
  push si
  push di

  call PageNumber	; Get page number from screen props
  mov ah, 08h		; BIOS function to read char and attrs under the cursor
  int 10h
  mov bl, ah		; Move AH (attrs) into BL

  mov ah, 09h		; BIOS function code for write char (and attr) at cursor.
  mov al, dl		; Setup our character
  mov cx, 1		; We want to print only 1 of it.
  int 10h		; Call BIOS

  pop di
  pop si
  pop bp
  pop sp
  pop cx
  pop bx
  pop ax
  ret
WriteTTY ENDP

BackspaceTTY PROC
  ; IN: nothing
  ; OUT: prints a backspace to the TTY
  push dx
  mov dl, 08h
  call WriteTTY
  pop dx
  ret
BackspaceTTY ENDP

BellTTY PROC
  ; IN: Nothing
  ; OUT: rings the TTY bell
  push dx
  mov dl, 07h
  call WriteTTY
  pop dx
  ret
BellTTY ENDP

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

PageNumber PROC
  ; IN: nothing
  ; OUT: bh -> Active display page number
  push ax
  call ScreenProps
  pop ax
  ret
PageNumber ENDP

ScreenWidth PROC
  ; IN: nothing
  ; OUT: ax -> width of screen in chars
  push bx
  call ScreenProps	; Get screen properties from BIOS
  mov al, ah		; Move AH into AL
  xor ah, ah		; Clear high byte
  pop bx
  ret
ScreenWidth ENDP

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
			; side effects from call ScreenProps
  int 10h

  pop di
  pop si
  pop bp
  pop sp
  pop cx
  pop ax
  ret
CursorPosition ENDP