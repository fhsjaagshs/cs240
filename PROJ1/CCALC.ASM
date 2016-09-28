TITLE ccalc.asm

; Author: Nathaniel Symer
; Last update: 8.29.2016
;
; This program calculates the hours (/inf), minutes (/60), and
; seconds (/60) out of a single quantity of time in seconds.
; This quantity is hardcoded into the program.

INCLUDE Irvine16.inc
.8086
.data
num WORD ?
denom WORD ?
.code

; takes:
; ax: number (16-bit) to divide
; bx: number (16-bit) to divide by
; returns:
; ax: remainder (16-bit)
; cx: quotient
quotRem PROC
	;; Zero out dx. This way,
	;; the dword used by div
	;; is guaranteed equivalent
	;; to the input value in ax.
        push dx
	mov dx, 00h

	;; divide 32-bit unsigned
	;; integer in dx:ax by 16-bit
	;; integer in bx.
	div bx

	;; set up CPU state as per
	;; above documenting comment
	mov cx, ax
	mov ax, dx

	;; Undo dx zeroing-out
	pop dx
	ret
quotRem ENDP

main PROC
	mov ax,@data	; set up the
	mov ds,ax	; data segment register

        mov ax, 12345 ;; starting value in seconds

	;; calculate hours
        mov bx, 3600
	call quotRem
        push cx

	;; calculate minutes, carrying
	;; remainder from hours calc
	mov bx, 60d
        call quotRem

	nop ;; seconds already in AX
	mov bx, cx ;; minutes in BX
	pop cx ;; hours in CX

        call dumpregs

	mov ax, 4C00h	; DOS function 4C exits
	int 21h		; DOS interrupt.
main ENDP
END main


























