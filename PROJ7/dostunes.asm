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
; frequency WORD
; duration WORD
; lyric_len BYTE: 0 means no new lyric
;
; TODO:
; - (pausing via space)

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
runtsr BYTE 0			; A var to be modified by hand to run the program as a TSR or not.
file_handle WORD ?

current_freq WORD 0		; The frequency of the currently playing note
remaining_time WORD 0		; How much longer the current note is going to play (in ms)
current_lyric WORD 256 DUP(0)	; Current lyric (ASCII)
current_lyric_len BYTE 0	; Length of current lyric
finished_playing BYTE 0		; Did the song finish playing?
song_title BYTE 64 DUP(0)	; The name of the currently playing song.

;;
;; INCLUDES
;;
INCLUDE files.inc
INCLUDE argv.inc
INCLUDE speakers.inc
INCLUDE printing.inc

read_note PROC
  ; OUT: AX -> error code from reading file
  ;      sets carry flag on EOF
  ; updates global player state

  push ax
  push bx
  push cx
  push dx

  mov bx, cs:[file_handle]

  ;; read the frequency
  mov cx, 2
  mov dx, OFFSET cs:current_freq
  call FReadAdv
  cmp ax, 0				; Did we get an error?
  jne read_note_done			; if we did, abort.
  cmp cx, 2				; Did we read enough chars?
  jl read_note_eof			; if we didn't abort.

  ;; read the duration
  mov cx, 2
  mov dx, OFFSET cs:remaining_time
  call FReadAdv
  cmp ax, 0
  jne read_note_done
  cmp cx, 2
  jl read_note_eof

  ;; read the lyric length
  mov cx, 1
  mov dx, OFFSET cs:current_lyric_len
  call FReadAdv
  cmp ax, 0
  jne read_note_done
  cmp cx, 1
  jl read_note_eof

  ;; read the lyric itself
  xor ch, ch
  mov cl, cs:[current_lyric_len]
  mov dx, OFFSET cs:current_lyric
  call FReadAdv
  cmp ax, 0
  jne read_note_done
  cmp cl, cs:[current_lyric_len]
  jl read_note_eof

read_note_done:
  clc
  jmp read_note_return
read_note_eof:
  stc
read_note_return:
  pop dx
  pop cx
  pop bx
  pop ax
  ret
read_note ENDP

;; Every 55 ms
ontimer PROC
  push bx
  push cx
  push dx
  cmp remaining_time, 55
  jg timer_done	; FIXME: should this be jge?

  call read_note			; Read the next note & update global player state.
  jc timer_finished_playing		; See read_note definition/documentation

  mov bx, cs:[current_freq]		; Load the frequency of the current note into BX.
  call set_speaker_frequency 		; Set the speaker's frequency to BX.

  xor ch, ch				; Clear CH.
  mov cl, cs:[current_lyric_len]	; Load lyric len into CL.
  mov dx, OFFSET cs:current_lyric  	; Load offset of current lyric into DX.
  push dx				; Prepare a stdcall to either print_urhc or print_console.

  cmp cs:[runtsr], 0			; Are we a TSR?
  je timer_notsr			; If we're not, skip to timer_notsr.
  call print_urhc			; If we are, print in upper right hand corner
  jmp timer_done			; and skip to timer_done.
timer_notsr:
  call print_console
timer_done:
  sub cs:[remaining_time], 55		; Decrement remaining_time by timer interval
  jmp ontimer_done			; and we're done for this tick.
timer_finished_playing:
  call disable_speaker			; Turn off the speaker hardware.
  mov bx, cs:[file_handle]		; Load our file handle into BX.
  call FClose				; Close the file handle in BX.
  mov cs:[remaining_time], 0		; Set the remaining time to 0
  mov cs:[finished_playing], 1		; Indicate that we finished playing.
ontimer_done:
  pop dx
  pop cx
  pop bx
  ret
ontimer ENDP

onkb PROC
  ; TODO: space button pause
  ret
onkb ENDP


;
;; INT handlers
;

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
  call onkb
  iret
handle09 ENDP


;
;; Functions to handle the
;; installation of the timer INT handler.
;; Hasn't changed from the clock project.
;

installer:

install09 PROC
  cmp word ptr cs:[orig_handle09], 0
  jne install09_done

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
install09_done:
  ret
install09 ENDP

uninstall09 PROC
  cmp word ptr cs:[orig_handle09], 0
  je uninstall09_done

  push es
  push ax
  push bx
  push dx

  push word ptr cs:orig_handle09+2
  pop es
  mov al, 09h
  mov dx, word ptr cs:orig_handle09
  call installhandler
  mov word ptr cs:orig_handle09, 0
  mov word ptr cs:orig_handle09 + 2, 0

  pop dx
  pop bx
  pop ax
  pop es
uninstall09_done:
  ret
uninstall09 ENDP

install08 PROC
  cmp word ptr cs:[orig_handle08], 0
  jne install08_done

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
install08_done:
  ret
install08 ENDP

uninstall08 PROC
  cmp word ptr cs:[orig_handle08], 0
  je uninstall08_done

  push es
  push ax
  push bx
  push dx

  push word ptr cs:orig_handle08+2
  pop es
  mov al, 08h
  mov dx, word ptr cs:orig_handle08
  call installhandler
  mov word ptr cs:orig_handle08, 0
  mov word ptr cs:orig_handle08 + 2, 0

  pop dx
  pop bx
  pop ax
  pop es
uninstall08_done:
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

strlen PROC
  ; IN: CS:SI -> ASCIIZ string offset in mem
  ; OUT: CX -> length
  push si
  xor cx, cx
sl_top:
  cmp byte ptr cs:[si], 0
  je sl_done
  inc cx
  inc si
  jmp sl_top
sl_done:
  pop si

  ret
strlen ENDP

;; ARGV
argv WORD 64 DUP(0)
argv_mem BYTE 128 DUP(0)

waiter:
  cmp cs:[finished_playing], 0
  je waiter
exit:
  call uninstall08
  call uninstall09
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
  call getcmdtail
  call nullify
  cmp cx, 1
  jne exit

  mov dx, cs:[argv]
  call FOpen
  cmp ax, 0
  jne exit

  mov cs:[file_handle], bx

  mov cx, 2
  mov dx, OFFSET cs:song_title
  call FReadAdv
  cmp ax, 0				; Did we get an error?
  jne exit				; if we did, abort.
  cmp cx, 2				; Did we read enough chars?
  jl exit				; if we didn't abort.

  mov cx, word ptr cs:[song_title]
  call FReadAdv
  cmp ax, 0
  jne exit

  call install08

  cmp cs:[runtsr], 1
  je installtsr

  call install09
  jmp waiter
END main






