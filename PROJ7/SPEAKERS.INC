;; Nathaniel Symer
;; speaker.inc
;;
;; Basic Speaker operations

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

  push ax
  push bx
  push dx
 
  mov ax, word ptr cs:CLOCKSPEED
  mov dx, word ptr cs:CLOCKSPEED + 2
  div bx

  push ax
  mov al, 182
  out 67, al
  pop ax

  out 66, al
  mov al, ah
  out 66, al

  pop dx
  pop bx
  pop ax

  ret
set_speaker_frequency ENDP

