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
; layer_fill - Reset all layer elements to given value
;
; rdi (arg) - pointer to layer
; rax (arg) - layer size
; ebx (arg) - value to fill with
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
; layer_circ - Create a circle on layer filled with given value
;
; rdi (arg) - pointer to layer
; eax (arg) - value to fill with
; rbx (arg) - packed field
;             [0]  0:7   - circle.radius
;             [1]  8:15  - unused
;             [2]  16:23 - circle.x
;             [3]  24:31 - circle.y
;             [4]  32:39 - layer_length
; *****************************************************************************
layer_circ:
        nop ; TODO:
        ret                                 ; end of layer_circ subroutine

; *****************************************************************************
; layer_rect - Create a rectangle on layer filled with given value
;
; rdi (arg) - pointer to layer
; eax (arg) - value to fill with
; rbx (arg) - packed field
;             [0]  0:7   - rect.width
;             [1]  8:15  - rect.length
;             [2]  16:23 - rect.x
;             [3]  24:31 - rect.y
;             [4]  32:39 - layer_length
;                  40:63 - unused
; *****************************************************************************
layer_rect:
        push rdi                            ; save rdi
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        push rax                            ; save fill value
        mov rcx, rbx                        ; load arguments
        shr rcx, 24                         ; move to 4th argument
        and rcx, 0xFF                       ; isolate rect.y
        mov rax, rbx                        ; load arguments
        shr rax, 32                         ; move to 5th argument
        and rax, 0xFF                       ; isolate layer_length
        mul rcx                             ; offset = (rect.y * layer_length)
        shl rax, 2                          ; offset = 4 * (rect.y * layer_length)
        add rdi, rax                        ; offset to first layer element
        pop rax                             ; restore fill value

        mov rdx, rbx                        ; load arguments
        shr rdx, 24                         ; move to 4th argument
        and rdx, 0xFF                       ; isolate rect.y
.loop_y:
        mov rcx, rbx                        ; load arguments
        shr rcx, 16                         ; move to 3rd argument
        and rcx, 0xFF                       ; isolate rect.x
        push rcx                            ; save rect.x
        shl rcx, 2                          ; dword offset of rect.x
        add rdi, rcx                        ; increment layer by offset
        pop rcx                             ; x = rect.x
.loop_x:
        push rbx                            ; save arguments
        push rcx                            ; save x
        mov rcx, rbx                        ; load arguments
        shr rcx, 16                         ; move to 3rd argument
        and rcx, 0xFF                       ; isolate rect.x
        and rbx, 0xFF                       ; isolate rect.width
        add rbx, rcx                        ; rect.x + rect.width
        pop rcx                             ; restore x
        cmp rcx, rbx                        ; test x >= (rect.x + rect.width)
        pop rbx                             ; restore arguments
        jge .next_x                         ; skip over fill

        mov dword [rdi], eax                ; layer[y][x] = fill
.next_x:
        add rdi, 4                          ; increment matrix pointer
        inc rcx                             ; x++

        push rbx                            ; save arguments
        shr rbx, 32                         ; move to 5th argument
        and rbx, 0xFF                       ; isolate layer_length
        cmp rcx, rbx                        ; test
        pop rbx                             ; restore arguments
        jl .loop_x                          ; while (x < layer_length)
.next_y:
        inc rdx                             ; y++

        push rbx                            ; save arguments
        mov rcx, rbx                        ; load arguments
        shr rcx, 8                          ; move to 2nd argument
        and rcx, 0xFF                       ; isolate rect.length
        shr rbx, 24                         ; move to 4th argument
        and rbx, 0xFF                       ; isolate rect.y
        add rcx, rbx                        ; rect.y + rect.length
        cmp rdx, rcx                        ; test
        pop rbx                             ; restore arguments
        jge .end                            ; if (y >= (rect.y + rect.length)) break

        push rbx                            ; save arguments
        shr rbx, 32                         ; move to 5th argument
        and rbx, 0xFF                       ; isolate layer_length
        cmp rdx, rbx                        ; test
        pop rbx                             ; restore arguments
        jl .loop_y                          ; while (y < layer_length)
.end:
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rdi                             ; restore rdi
        ret                                 ; end of layer_rect subroutine

; *****************************************************************************
; layer_sub - Subtract one layer from the other. A = A - B
;
; rdi (arg) - layer A
; rsi (arg) - layer B
; rax (arg) - layer size
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
; rdi (arg) - layer A
; rsi (arg) - layer B
; rax (arg) - layer size
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
