        global layer_fill
        global layer_add
        global layer_sub
        global layer_circ
        global layer_rect

        %include "inc/common.inc"

        section .data

        section .rodata

        section .bss

        section .text

; *****************************************************************************
; layer_fill - Reset all layer elements to given floating point value
;
; rax (arg) - layer size
; ebx (arg) - floating point value
; rdi (arg) - pointer to layer
; *****************************************************************************
layer_fill:
        push rcx                            ; save rcx
        xor rcx, rcx                        ; i = 0
.loop_i:
        mov dword [rdi + (rcx * 4)], ebx    ; layer[i] = c
.next_i:
        inc rcx                             ; i++
        cmp rcx, rax                        ; test
        jl .loop_i                          ; while (i < layer_size)
.done:
        pop rcx                             ; restore rcx
        ret                                 ; end of layer_fill subroutine

; *****************************************************************************
; layer_circ - Create a circle on layer made of 1.0
;
; TODO:
; *****************************************************************************
layer_circ:
        nop                                 ; TODO:
        ret                                 ; end of layer_circ subroutine

; *****************************************************************************
; layer_rect - Create a rectangle on layer made of 1.0
;
; TODO:
; *****************************************************************************
layer_rect:
        nop                                 ; TODO:
        ret                                 ; end of layer_rect subroutine

; *****************************************************************************
; layer_sub - Subtract one layer from the other. A = A - B
;
; rax (arg) - layer size
; rdi (arg) - layer A
; rsi (arg) - layer B
; *****************************************************************************
layer_sub:
        push rcx                            ; save rcx
        xor rcx, rcx                        ; i = 0
.loop_i:
        fld dword [rsi + (rcx * 4)]         ; ST0 = A[i]
        fld dword [rdi + (rcx * 4)]         ; ST0 = B[i], ST1=A[i]
        fsubp                               ; ST0 = A[i] - B[i]
        fstp dword [rdi + (rcx * 4)]        ; A[i] = A[i] - B[i]
.next_i:
        inc rcx                             ; i++
        cmp rcx, rax                        ; test
        jl .loop_i                          ; while (i < layer_size)
.end:
        pop rcx                             ; restore rcx
        ret                                 ; end of layer_sub subroutine

; *****************************************************************************
; layer_add - Add one layer to the other. A = A + B
;
; rax (arg) - layer size
; rdi (arg) - layer A
; rsi (arg) - layer B
; *****************************************************************************
layer_add:
        push rcx                            ; save rcx
        xor rcx, rcx                        ; x = 0
.loop_i:
        fld dword [rsi + (rcx * 4)]         ; ST0 = A[i]
        fld dword [rdi + (rcx * 4)]         ; ST0 = B[i], ST1=A[i]
        faddp                               ; ST0 = A[i] + B[i]
        fstp dword [rdi + (rcx * 4)]        ; A[i] = A[i] + B[i]
.next_i:
        inc rcx                             ; i++
        cmp rcx, rax                        ; test
        jl .loop_i                          ; while (i < layer_size)
.end:
        pop rcx                             ; restore rcx
        ret                                 ; end of layer_add subroutine
