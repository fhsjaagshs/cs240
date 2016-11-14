TITLE	dostunes.asm

; Author: Nathaniel Symer
; Last update: 11.11.2016
;
; Read a .tune file and play the music encoded in it.
;
; The file consists of the following:
; 
; +-----------+-------+-------+
; | title len | title | music |
; +-----------+-------+-------+
;
; title_len -> WORD
; title -> ASCII byte array
; music -> see below
;
; music is an array of the following:
;
; +-----------+----------+-----------+-------+
; | frequency | duration | lyric_len | lyric |
; +-----------+----------+-----------+-------+
;
; frequency
; duration
; lyric_len: 0 means no new lyric, -1 means clear lyric
;
; TODO:
; 3. Console I/O (use existing code!)
; 5. Load music
; 6. (pausing via space)
.8086
.model tiny
.stack 4096
.code
  org 100h
main:
  jmp start

;; DOSTUNES CONSTANTS
CLOCKSPEED DWORD 1193280
;; DOSTUNES STATE
runtsr BYTE 0		; A var to be modified by hand to run the program as a TSR or not.
file_handle WORD ?
remaining_time WORD 0	; How much longer the current note is going to play (in ms)
finished_playing BYTE 0	; Did the song finish playing?
is_paused BYTE 0	; Is the player paused?

INCLUDE files.inc
INCLUDE args.inc
INCLUDE speaker.inc

strlen PROC
  ; IN: CS:BP -> ASCIIZ string
  ; OUT: CX -> length of string
  push bp
  xor cx, cx
strlen_top:
  cmp cs:[bp], 0
  je strlen_done
  inc cx
  inc bp
  jmp strlen_top
strlen_done:
  pop bp
  ret
strlen ENDP

print_urhc PROC
  ; IN: stack parameter: offset of ASCII string to print in CS
  push bp
  mov bp, sp

  push ax
  push bx
  push cx
  push dx
  push bp
  push es

  mov bp, ss:[bp+2] 
  call strlen

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
  pop cx
  pop bx
  pop ax
  
  pop bp
  ret 4
print_urhc ENDP

print_console PROC
  ; IN: stack parameter: offset of ASCII string to print in CS
  push bp
  mov bp, sp

  push ax
  push bx
  push cx
  push si

  mov si, ss:[bp+2] 
  call strlen

  mov ah, 0Eh		; Print TTY
print_console_loop:
  mov al, cs:[si]
  int 10h
  loop print_console_loop
  
  pop si
  pop cx
  pop bx
  pop ax

  pop bp
  ret 4
print_console ENDP

;; Every 55 ms
ontimer PROC
  cmp remaining_time, 55
  jg timer_done	; FIXME: should this be jge?

  ;; TODO: read next note

  ; if eof encountered,
  ; jmp finished_playing

  ;; TODO: load lyric
 

  ;; FReadAdv 
  ;; IN:
  ;;   BX -> handle
  ;;   CX -> # bytes to read
  ;;   CS:DX -> buffer to read into
  ;; OUT:
  ;;   AX -> error
  ;;   CX -> number of bytes read
  ;;   * updates CS:DX * 

  cmp cs:[runstr], 0
  je timer_notsr
  call print_urhc
  jmp timer_done
timer_notsr:
  call print_console
timer_done:
  sub cs:[remaining_time], 55
  ret
finished_playing:
  call disable_speaker
  call uninstall08	; Figure out how to remove the handler from here after without DOS
  mov bx, cs:[file_handle]
  call FClose
  mov cs:[remaining_time], 0
  mov cs:[finished_playing], 1
  ret
ontimer ENDP

onkb PROC

  ret
onkb ENDP

;
;; Functions to handle the
;; installation of the timer INT handler.
;; Hasn't changed from the clock project.
;

orig_handle08 DWORD ?
orig_handle09 DWORD ?

handle08 PROC
  pushf
  call cs:[orig_handle08]
  call ontimer
  iret
handle08 ENDP

handle09 PROC
  pushf
  call cs:[orig_handle09]
  call onkb
  iret
handle09 ENDP

installer:

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

installhandler PROC
  ; IN ->  al: interrupt number
  ;        es: segment of new handler
  ;        dx: offset of new handler
  ; OUT -> bx: offset of old handler.
  ;        es: segment of old handler
  ; CAUSES -> installs the new handler.

  push ax
  push ds

  push es		; Push segment of new handler for handler setter. Handler getter overwrites ES.

  mov ah, 35h		; Read IVT entry # AL
  int 21h		; and set BX and ES.

  pop ds		; Pop segment of new handler into DS.
  mov ah, 25h		; Set the entry in
  int 21h		; the IVT to (DS:DX).

  pop ds
  pop ax

  ret
installhandler ENDP

;; ARGV
argc WORD 0
argv BYTE 0 DUP(64)
argv_mem BYTE 0 DUP(128)

waiter:
  cmp cs:[], 0
  je waiter
exit:
  mov ax, 4C00h
  int 21h
installtsr:
  mov dx, OFFSET installer
  mov cl, 4
  shr dx, cl
  inc dx
  mov ax, 3100h
  int 21h

start:
  mov si, OFFSET cs:argv_mem
  mov bx, OFFSET cs:argv
  call args
  mov cs:[argc], cx

  cmp cs:[argc], 1
  jne exit

  mov dx, cs:[argv]
  call FOpen
  cmp ax, 0
  jne exit

  mov cs:[file_handle], bx

  call install08

  cmp cs:[runtsr], 1
  je installtsr

  call install09
  
  ;; don't int 21h/AX=4C00h, we'll do that when the song is over.
END main

