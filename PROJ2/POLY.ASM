TITLE	poly.asm

; Author: Nathaniel Symer
; Last update: 9.10.2016
;
; Read a hardcoded (but arbitrary) number
; of integers starting with a and plug them
; into a polynomial calculation.

INCLUDE Irvine16.inc
.8086
.data
rsiBuf BYTE 5 DUP(0) ; 5 bytes, 5 places for a WORD
xval SWORD ?
numplaces WORD 3 ; 3 places is a polynomial

v1 WORD ?
v2 WORD ?
v3 WORD ?
v4 WORD ?
.code

; displays a prompt, reading a signed int.
; takes:
; dl -> character for prompt
; returns:
; dx -> read signed int
prompt PROC
  push ax
  mov ah, 02h
  int 21h

  mov dl, ':'
  int 21h
  mov dl, ' '
  int 21h

  call readSignedInt
  push dx
  mov dl, 0Ah ; newline
  int 21h
  pop dx
  pop ax
  ret
prompt ENDP

; Calculates x^n (unsigned)
; takes:
; ax -> x
; cx -> n
; returns:
; ax -> x^n
pow PROC
  push dx ; mul instruction
  push cx ; loop instruction
  push bx ; *used by proc

  mov bx, ax ; avoid clobbering x
  mov ax, 1  ; prepare ax for multiplication

body:
  mul bx
  loop body

  pop bx
  pop cx
  pop dx
  ret
pow ENDP

; takes params on stack
poly PROC

  mov v1, cx ; since we take params
  mov v2, bx ; on the stack, we can't
  mov v3, ax ; push the registers we use.
  pop v4     ; save value of IP so that
             ; its not confused with a parameter

  mov cx, v1 ; restore values
  mov bx, v2
  mov ax, v3
  push v4
  ret
poly ENDP

main PROC
	mov ax,@data	; set up the
	mov ds,ax	; data segment register

        mov dl, 'x'
        call prompt
	mov xval, dx

;; SETUP STACK FOR POLY

	mov cx, numplaces
	mov dl, 'a'
inputloop:
        mov al, dl   ; save current char
	call prompt ; read a number into DX
	push dx     ; put new number on the stack
	mov dl, al  ; old current char is the new previous char
	inc dl
	loop inputloop

        mov dx, 0         ; set polynomial total to 0
        mov cx, 0         ; set loop counter to 0
        jmp cond

;; POLY ALGO
;; stack contains coefficients in reverse order: eg (head)[c,b,a]
;; eg. pop off c, multiplying c by 10^i where i is zero (first value)
;; 1. set i to zero
;; 2. take 10^i = m
;; 3. pop off first element, e
;; 4. take m*e and add to total
;; 5. increment i and goto #1 if not the last elem

body:
        mov ax, xval ; raise xval to the
        call pow     ; CXth power

        pop bx     ; pop next polynomial coefficient
        push dx    ; * ignore high bits (mul)
        mul bx     ; multiply coefficient by x "multiplier"
        pop dx     ; * END ignore high bits (mul)
        add dx, ax ; add to total
        inc cx
cond:
        cmp cx, numplaces
        jl body

	mov ax, dx
	call WriteInt

	mov ax, 4C00h	; DOS function 4C exits
	int 21h		; DOS interrupt.
main ENDP

;; reads am ASCII char from STDIN
; returns:
; al -> the read char
; ah -> zero
readCharMe PROC
  mov ax, 0100h ; read a char from
  int 21h       ; DOS into AL
  xor ah, ah    ; clear AH
  ret
readCharMe ENDP

;; TODO: backspaces
;; reads a numerical WORD from STDIN
; returns:
; dx -> the resulting signed int
readSignedInt PROC
  push ax
  push bx
  push si

  xor dx, dx
  mov si, OFFSET rsiBuf ; setup rsiBuf
                        ;  this is safe because this proc
                        ;  doesn't iterate when using rsiBuf.
  mov bx, 0             ; setup SI offset
  call readCharMe       ; read first character
  cmp al, '-'           ;  -> compare to negative sign char
  je signed             ;  -> jump if necessary
			;
  cmp al, '+'           ;  -> compare to plus sign char
  je plused	        ;  -> skip all leading plus signs
                        ; WHILE LOOP BEGIN
firstCheck:             ; BX != 5
  cmp bx, 5
  je unpack
secondCheck:            ; AL >= 48
  cmp al, 48
  jl unpack
thirdCheck:             ; AL <= 57
  cmp al, 57
  jg unpack
body:
  sub al, 48            ; ASCII to base 10 digit
  mov [si+bx], al       ; Append digit
  inc bx                ; move to next place
repeater:
  call readCharMe       ; read next char
  jmp firstCheck        ; LOOP REPEAT

signed:
  call readSignedInt ; since we read a negative sign, we can read a number
                     ;  recursion here ensures all negations are evaluated.
                     ;  will make n recursions where n = # negative signs
  xor dx, 0FFFFh      ; two's
  add dx, 1          ; complement
  jmp done

plused:
  call readSignedInt
  jmp done

unpackbody:
  dec bx             ;
  mov al, [si]       ; pop off char at SI
  xor ah, ah
  cmp bx, 0
  jz unpackstep
  push dx            ; * ignore high bytes
  mov dx, 10
  mul dx
  mul bx
  pop dx             ; * ignore high bytes
unpackstep:
  inc si             ; advance to next highest place
  add dx, ax         ; add to total
unpack:
  cmp bx, 0          ; do we have any places left?
  jge unpackbody

done:
  pop si
  pop bx
  pop ax
  ret
readSignedInt ENDP

END main