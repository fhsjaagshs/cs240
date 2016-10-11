TITLE	proj5.asm

; Author: Nathaniel Symer
; Last update: 10.10.2016
;
; 3 functions project

INCLUDE Irvine16.inc
.8086
.stack 4096
.data
.code

;SafeRead PROC
;  ; Read chars from the KB and place them
;  ; in a supplied buffer
;  ; IN: [bp+4] -> buffer length
;  ; IN: [bp+6] -> offset of the buffer in the Data segment
;
;
;  push bp		; Start the stack frame by pushing the old BP
;  mov bp, sp		; Move the current stack pointer into the base
;			; pointer to the stack frame
;
;  ; We don't need to allocate any local variables.
;
;;  mov cx, [bp+4]	; Copy buffer length to CX
;  mov dx, [bp+6]	; Copy buffer offset to DX
;
;top:
;  mov dl, 00h 	; Load a char
;  cmp dl, 00h	; is it a backspace?
;  je backspace
;  cmp dl, 00h	; is it a delete?
;  je delete
;  cmp dl, 00h	; is it an arrow?
;  je arrow
;  cmp dl, 00h	; is it a control?
;
;  ; TODO: it's a normal char, add to buffer.
;
;backspace:
;  ; TODO: setup CX
;  clc
;  call _delete_action
;delete:
;  ; TODO: setup CX
;  setc
;  call _delete_action
;arrow:
;  call _arrow_action
;control:
;  call _control_action
;done:
;  pop bp
;  ret
;SafeRead ENDP

;_control_action PROC
;  ; IN: dl -> char code
;  ; OUT: nothing
;  ; evaluates the control key combination specified by DL.
;
;
;_control_action ENDP

;_delete_action PROC
;  ; IN: CF -> if set, deletion acts like delete key
;  ;           otherwise, deletion acts like delete key
;  ;     DS:SI -> buffer to delete from
;  ;     CX -> position in buffer
;
;done:
;  ret
;_delete_action ENDP

;_insert_action PROC
;
;_insert_action ENDP

FastMultiply PROC
  ; IN: ax -> a multiplicand
  ;     [bp+4] -> another multiplicand
  ; OUT: ax -> product of AX and [bp+4], assumed to fit in 16 bits
  push bp	; setup
  mov bp, sp	; stack frame

  sub sp, 2	; Allocate stack vars:
		;   [bp] -> mulcarry

  push cx

  cmp ax, 0		; If AX is zero
  je zerodone		; return

  mov cx, [bp+4]	; Store the second multiplicand in CX

  cmp cx, 0		; If CX is zero
  je zerodone		; return

  mov [bp], cx		; Set mulcarry to CX.
  shr cx, 1		; Divide by two to get the number of times to multiply
			; ax by 2
  jc shifts
  mov word ptr [bp], 0	; We don't have a carry, clear mulcarry
shifts:
  cmp cx, 0		; If CX is not zero
  je addcarry		; Jump to shifts label.

  shl ax, cl		; multiply AX by two CL times
  xor cl, cl		; clear cl

  cmp cx, 0FFh
  jb shifts
  sub cx, 0FFh		; Subtract CL's max from CX
  jmp shifts
addcarry:
  add ax, [bp]		; add mulcarry to ax

done:
  pop cx

  add sp, 2		; Deallocate stack variable
  pop bp		; Destroy stack frame
  ret 2			; And return past the parameters
zerodone:
  xor ax, ax		; Clear AX
  jmp done		; Now we're done
FastMultiply ENDP

main PROC
  mov ax, @data	; setup data segment
  mov ds, ax	; make up for machine quirk

  mov ax, 0
  push ax
  mov ax, 5
  call FastMultiply
  call DumpRegs

  mov ax, 4C00h	; Exit zero
  int 21h	; DOS interrupt with 4C00h
main ENDP
END main





