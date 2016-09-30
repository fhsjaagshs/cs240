TITLE	hexdump.asm

; Author: Nathaniel Symer
; Last update: 9.28.2016
;
; Works just like hexdump -C on Linux.

INCLUDE Irvine16.inc

.8086
.stack 4096

.data
argv BYTE 128 DUP(0)
argtable BYTE 64 DUP(0) ; Max # args = 64 single character args.
argc WORD 0

.code

INCLUDE argv.inc
INCLUDE files.inc
INCLUDE printing.inc

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov si, OFFSET argv		; Load args addr into SI.
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

  jmp done
invalid_args:
  mov dl, '!'
  call PutChar
  ;; TODO: print error message
done:
  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP

hexdump PROC
  ; IN: bx -> file handle
  ; OUT: prints hexdump
.data
foffset DWORD 0		; Offset in file
buffer BYTE 16 DUP(0)	; Current hexdump line
.code

  push ax
  push bx
  push cx
  push dx

top:
  mov dx, OFFSET foffset	; Load offset into DX
  call PrintUnsigned32		; Print it

  mov cx, 16			; Attempt to read 16 bytes
  mov dx, OFFSET buffer		; into file buffer
  call FReadAdv			; TODO: error handling!

  mov dx, OFFSET foffset	; Update the offset WRT CX from FReadAdv
  call AddOffset		;

  cmp cx, 0			; Are we at the EOF?
  je done			; If we are, we're done.

  call space
  call space

  push ax
  push bx
  mov dx, OFFSET buffer		; Load file buffer offset into DX
  mov ax, 8			; Set the number of chars before a split.
  mov bx, 16			; Set the line length
  call HexOutSplit		; Print the line (CX already set by FReadAdv)
  pop bx
  pop ax

  call space			; We only print a single space b/c
				; HexOutSplit prints a space afterwards

  call pipe
  call PrintHumanReadable
  call pipe
  call newline

  jmp top
done:
  pop dx
  pop cx
  pop bx
  pop ax
  ret
hexdump ENDP

AddOffset PROC
  ; IN: cl -> byte to add
  ;     ds:dx -> pointer to 32bit number
  ; OUT: modifies ds:dx to reflect adding CL

  push ax
  push bx
  push cx

  mov bx, dx		; Move DX to BX so we can access memory.
  mov ax, [bx+2]	; Load low bytes of 32bit num into AX
  xor ch, ch		; Clear high bytes of CX
  adc ax, cx		; Add CX to AX w/ carry
  mov [bx+2], ax	; Load low bytes back into memory. Flags unmodified.
  jnc after		; If we carry over into the high bytes,
  mov ax, [bx]		; load the high bytes
  inc ax		; Add the carry
  mov [bx], ax		; load back into memory
after:
  pop cx
  pop bx
  pop ax
  ret
AddOffset ENDP

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
;	Print a space after each byte.
; 6. Print a pipe
; 7. Print bytes as ASCII, replacing unreadables with '.'
; 8. Print another pipe
; 9. Print a newline
; 10. goto 1

END main

