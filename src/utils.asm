        
        global count_digits
        global itoa_10
        global strlen

        section .text

; *****************************************************************************
; count_digits - Count digits of unsigned integer (dumb method)
;
; rbx (arg) - unsigned integer to count (up to 999999)
; rax (ret) - number of digits
; *****************************************************************************
count_digits:
        mov ax, 6                           ; digits = 6
        cmp rbx, 100000                     ; check if 6 digits
        jge .done                           ; if (rbx >= 100000) return digits

        dec ax                              ; digits = 5
        cmp rbx, 10000                      ; check if 5 digits
        jge .done                           ; if (rbx >= 10000) return digits

        dec ax                              ; digits = 4
        cmp rbx, 1000                       ; check if 4 digits
        jge .done                           ; if (rbx >= 1000) return digits

        dec ax                              ; digits = 3
        cmp rbx, 100                        ; check if 3 digits
        jge .done                           ; if (rbx >= 100) return digits

        dec ax                              ; digits = 2
        cmp rbx, 10                         ; check if 2 digits
        jge .done                           ; if (rbx >= 10) return digits

        dec ax                              ; digits = 1
.done:
        ret                                 ; end count_digits subroutine

; *****************************************************************************
; itoa_10 - Convert integer to base-10 ASCII string
;
; rax (arg) - integer to convert
; rdi (arg) - pointer to write string to
; *****************************************************************************
itoa_10:
        push rax                            ; save rax
        push rbx                            ; save rbx

        mov ecx, 10                         ; base-10
        xor ebx, ebx                        ; reset divisor
.div:
        xor edx, edx                        ; clear dividend
        div ecx                             ; AX/10
        push dx                             ; save digit
        inc bx                              ; inc divisor
        test eax, eax                       ; check if more digits
        jnz .div                            ; while (eax != 0)

        mov cx, bx                          ; load digit count
.digit:
        pop ax                              ; pop digit
        add al, '0'                         ; convert to ASCII
        mov [rdi], al                       ; store ASCII digit
        inc di                              ; increment pointer
        loop .digit                         ; while (CX > 0)

        pop rbx                             ; restore rbx
        pop rax                             ; restore rax
        ret                                 ; end itoa_10 subroutine

; *****************************************************************************
; strlen - Calculates length of null-terminated string
;
; rdi (arg) - pointer to null-terminated string
; rax (ret) - length of string
; *****************************************************************************
strlen:
        push rcx                            ; save rcx
        push rdi                            ; save rdi

        xor ecx, ecx                        ; reset counter
        dec rcx                             ; counter = -1
        xor eax, eax                        ; reset AL
        repne scasb                         ; scan memory for AL
        sub rax, rcx                        ; scanned bytes + 1
        sub rax, 2                          ; final string length (-1 if "\0")

        pop rdi                             ; restore rdi
        pop rcx                             ; restore rcx
        ret                                 ; end strlen subroutine
