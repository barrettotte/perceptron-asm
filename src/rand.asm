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
; rand32 - Generate unsigned pseudo-random 32-bit integer using 
;   Linear Congruential Generator (LCG) with values from ANSI C.
;   
;   $X_{n+1} = (aX_n + c) % m$
;   
;   where: 
;     - $X_{n+1}$ is the next seed (bits 30..16 of generated value)
;     - $a$ is the multiplier, an arbitrary large prime. In ANSI C, this is 1103515245
;     - $X_n$ is the current seed value
;     - $c$ is the increment, an arbitary prime. In ANSI C, this is 12345
;     - $m$ is the modulus. In ANSI C, this is 2^31 = 1 << 31 = 2147483648
;
; eax (ret) - pseudo random number
; *****************************************************************************
rand32:
        push rdx                            ; save rdx

        mov eax, 0x41C64E6D                 ; a
        imul dword [seed]                   ; (a * seed)
        add eax, 0x3039                     ; (a * seed) + c
        shr eax, 16                         ; isolate output bits
        and eax, 0x7FFF                     ; (a * seed) % m
        call srand                          ; store new seed for next generation

        pop rdx                             ; restore rdx
        ret                                 ; end rand32 subroutine

; *****************************************************************************
; rand32_range - Generate random number in range 0 through (n-1)
;
; eax (arg) - max number
; eax (ret) - pseudo random number
; *****************************************************************************
rand32_range:
        push rbx                            ; save rbx
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        mov ebx, eax                        ; max value
        call rand32                         ; generate random
        xor edx, edx                        ; clear
        div ebx                             ; clamp to range
        mov eax, edx                        ; remainder

        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rbx                             ; restore rbx
        ret                                 ; end rand32_range subroutine
