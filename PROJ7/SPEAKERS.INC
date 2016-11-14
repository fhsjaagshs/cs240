;; Nathaniel Symer
;; speaker.inc
;;
;; Basic Speaker operations

clkspd DWORD 1193280

enable_speaker PROC
  ; IN/OUT: nothing
  ; enables the hardware speaker
  push ax
  in al, 97
  or al,  3
  out 97, al
  pop ax
  ret
enable_speaker ENDP

disable_speaker PROC
  ; IN/OUT: nothing
  ; disables the hardware speaker.
  push ax
  in al, 97
  and al, 0FCh
  out 97, al
  pop ax
  ret
disable_speaker ENDP

set_speaker_frequency PROC
  ; IN: BX -> frequency
  cmp bx, 0
  je ssf_done
  push ax
  push dx

  ; this was reversed from the demo
  mov ax, word ptr cs:clkspd
  mov dx, word ptr cs:clkspd + 2
  div bx

  push ax
  mov al, 182
  out 67, al
  pop ax

  out 66, al
  mov al, ah
  out 66, al

  pop dx
  pop ax
ssf_done:
  ret
set_speaker_frequency ENDP

