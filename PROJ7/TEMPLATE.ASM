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
; 4. Timing via timer interrupt
; 5. Load music
;
; Bonus TODO:
; 1. TSR
;   a. Play music in background
;   b. Print lyrics in upper right hand corner (like the clock)

.8086
.model small
.stack 4096
.data
.code
main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main

