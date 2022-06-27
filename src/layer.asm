        global layer_clear
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
; layer_clear - Reset all layer elements to 0.0
;
; rax (arg) - layer size
; rdi (arg) - pointer to layer
; *****************************************************************************
layer_clear:
        push rcx                            ; save rcx
        push rdi                            ; save layer pointer
        xor rcx, rcx                        ; x = 0
.loop_i:
        mov dword [rdi], __float32__(0.0)   ; clear element
.next_i:
        add rdi, 4                          ; move to next element
        inc rcx                             ; x++
        cmp rcx, rax                        ; test
        jl .loop_i                          ; while (i < layer_size)
.done:
        pop rdi                             ; restore layer pointer
        pop rcx                             ; restore rcx
        ret                                 ; end of layer_clear subroutine

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
; layer_sub - Subtract one layer from the other
;
; TODO:
; *****************************************************************************
layer_sub:
        nop                                 ; TODO:
        ret                                 ; end of layer_sub subroutine

; *****************************************************************************
; layer_add - Add one layer to the other
;
; TODO:
; *****************************************************************************
layer_add:
        nop                                 ; TODO:
        ret                                 ; end of layer_add subroutine
