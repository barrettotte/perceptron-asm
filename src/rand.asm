        global rand32_range
        global srand

        section .data
seed:           dd 1                        ; current PRNG seed

        section .text

; *****************************************************************************
; srand - Seed pseudo-random number generator
;
; eax (arg) - seed value
; *****************************************************************************
srand:
        mov dword [seed], eax               ; set PRNG seed
        ret                                 ; end srand subroutine

; *****************************************************************************
; rand32 - Generate unsigned pseudo-random 32-bit integer
;
; eax (ret) - generated number
; *****************************************************************************
rand32:
        push rdx                            ; save rdx
        mov eax, 0x377AA                    ; divide by arbitrary number
        imul dword [seed]                   ; generate base random
        add eax, 0x1AAC4A                   ; add arbitrary number
        mov dword [seed], eax               ; save seed for next call
        ror eax, 8                          ; grab lowest digit
        pop rdx                             ; restore rdx
        ret                                 ; end rand32 subroutine

; *****************************************************************************
; rand32_range - Generate random number in range 0 through (n-1)
;
; eax (arg) - max number
; eax (ret) - generated number
; *****************************************************************************
rand32_range:
        push rbx                            ; save rbx
        push rdx                            ; save rdx

        mov ebx, eax                        ; max value
        call rand32                         ; generate random
        xor edx, edx                        ; clear
        div ebx                             ; clamp to range
        mov eax, edx                        ; remainder

        pop rdx                             ; restore rdx
        pop rbx                             ; restore rbx
        ret                                 ; end rand32_range subroutine
