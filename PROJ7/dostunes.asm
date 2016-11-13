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
;
; TODO:
; 1. File I/O (use existing code!)
; 2. Sound I/O (use existing code from piazza)
; 3. Console I/O (use existing code!)
; 5. Load music
; 6. (seeking via arrow keys, pausing via space)
.8086
.model tiny
.stack 4096
.code
  org 100h
main:
  jmp start

runtsr BYTE 0		; A var to be modified by hand to run the program as a TSR or not.
file_handle WORD ?

remaining_time WORD 0	; How much longer the current note is going to play (in ms)

enable_speaker PROC

  ret
enable_speaker ENDP

disable_speaker PROC

  ret
disable_speaker ENDP

print_urhc PROC
  ; IN: stack parameter: offset of ASCII string to print in the code segment
  ;     stack parameter: length of string to print
  push bp
  mov bp, sp
  
  pop bp
  ret 4
print_urhc ENDP

print_console PROC
  ; IN: stack parameter: offset of ASCII string to print in the code segment
  ;     stack parameter: length of string to print
  push bp
  mov bp, sp
  
  pop bp
  ret 4
print_console ENDP

play_note PROC
  ; IN: AX frequency in Hz

  ret
play_note ENDP

;; Every 55 ms
ontimer PROC
  ; ALGO:
  ; 1. Add timer interval to counter (mem location)
  ; 2. If the counter > duration of the current note,
  ;    advance.

  cmp remaining_time, 55
  jg timer_done	; FIXME: should this be jge?

  ;; TODO: read next note

  ; if eof encountered,
  ; jmp finished_playing

  ;; TODO: load lyric
  cmp cs:[runtsr], 1
  jne timer_notsr
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
  mov cs:[remaining_time], 0
  ret
ontimer ENDP

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

;
;; Functinos to handle the
;; installation of the timer INT handler.
;; Hasn't changed from the clock project.
;

handle08 PROC
  pushf
  call cs:[orig_handle08]
  call ontimer
  iret
handle08 ENDP

orig_handle08 DWORD ?

installer:

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

start:
  call install08

  cmp cs:[runtsr], 1
  jne aftertsr
  mov dx, OFFSET installer
  mov cl, 4
  shr dx, cl
  inc dx
  mov ax, 3100h
  int 21h
aftertsr:
  ;; don't int 21h/AX=4C00h, we'll do that when the song is over.
END main

