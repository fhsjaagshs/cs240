TITLE	hexdump.asm

; Author: Nathaniel Symer
; Last update: 9.21.2016
;
; Works just like hexdump -C.
;
; Stores a 32-bit offset

INCLUDE Irvine16.inc
INCLUDE argv.inc
INCLUDE files.inc

.8086
.stack 4096

.data
args BYTE 128 DUP(0)
argtable BYTE 64 DUP(0) ; Max # args = 64 single character args.
argc BYTE 0

bytes BYTE 16 DUP(0)	; The 16 bytes we're currently printing.
offset DWORD 0

.code
main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov si, OFFSET args		; Load args addr into SI.
  mov bx, OFFSET argtable	; Load argtable addr into BX.
  call args			; Read command line args.
  mov argc, cx			; Store the number of args in memory.

  ; TODO: check for errors

  cmp argc, 1			; If we don't have exactly one argument
  jne invalid_args		; we have invalid args and need to exit.

  mov bx, OFFSET argtable	; Load argtable into BX
  mov dx, [bx]			; and dereference BX into DX
				; This loads the location of the first arg
				; into DX.
  call FOpen			; Open file specified by argument
  call hexdump			; print file as hex
  call FClose			; Close the file

  jmp exit
invalid_args:
  ;; TODO: print error message
exit:
  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

hexdump PROC
  ; IN: bx -> file handle

top:
  

  ret
hexdump ENDP

; PRINTING ALGO (some is Haskell pseudocode)
; 1. Print offset
; 2. Read 16 or less bytes (filesize isn't usually divisble by 16)
; 3. If (count bytes) == 0, STOP
; 4. print 2 padding spaces
; 5. print bytes in hex
;    1. print up to* 8 bytes
;    2. print a space
;    3. print up to* 8 bytes
;     * print up to n bytes, if n bytes aren't available, print spaces.
	Print a space after each byte.
; 6. Print a pipe
; 7. Print bytes as ASCII, replacing unreadables with '.'
; 8. Print another pipe
; 9. Print a newline
; 10. goto 1

END main








