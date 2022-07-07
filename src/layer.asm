        global layer_fill
        global layer_add
        global layer_sub
        global layer_circ
        global layer_rect

        %include "inc/common.inc"

        section .data
x0:             db 1                        ; initial x
y0:             db 1                        ; initial y
x1:             db 1                        ; terminal x
y1:             db 1                        ; terminal y

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
;             [2]  16:23 - circle.cx
;             [3]  24:31 - circle.cy
;             [4]  32:39 - layer_length
; *****************************************************************************
layer_circ:
        push rdi                            ; save rdi
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        ; x0 = circle.cx - circle.radius
        ; y0 = circle.cy - circle.radius
        ; x1 = circle.cx + circle.radius
        ; y1 = circle.cy + circle.radius

        ;  for (int y = y0; y <= y1; y++) {
        ;    for (int x = x0; x <= x1; x++) {
        ;      dx = x - cx;
        ;      dy = y - cy;
        ;      if (dx^2 + dy^2 <= r^2)
        ;        layer[y][x] = val;
        ;    }
        ;  }

        nop ; TODO:
.end:
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rdi                             ; restore rdi
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
;
;             ex: 0x1402040A05  
;                 5x10 rect at (2,4) with layer length 20
; *****************************************************************************
layer_rect:
        push rdi                            ; save rdi
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        mov rcx, rbx                        ; load arguments
        shr rcx, 16                         ; clear lower arguments
        and rcx, 0xFFFF                     ; isolate (rect.x, rect.y)
        mov word [x0], cx                   ; save x0 = rect.x, y0 = rect.y

        mov rdx, rbx                        ; load arguments
        and rdx, 0xFFFF                     ; isolate (rect.width, rect.length)
        add rdx, rcx                        ; (rect.width + rect.x, rect.length + rect.y)
        sub rdx, 0x0101                     ; (rect.width + rect.x - 1, rect.length + rect.y - 1)
        mov word [x1], dx                   ; save x1 = (rect.width + rect.x - 1, rect.length + rect.y - 1)

        xor rcx, rcx
        mov cl, byte [y0]                   ; y = y0
.loop_y:
        xor rdx, rdx
        mov dl, byte [x0]                   ; x = x0
.loop_x:
        push rcx                            ; save y
        push rax                            ; save fill value
        mov rax, rbx                        ; load arguments
        shr rax, 32                         ; move to 5th argument
        and rax, 0xFF                       ; isolate layer_length
        push rdx                            ; save x
        mul rcx                             ; (layer_length * y)
        pop rdx                             ; restore x
        add rax, rdx                        ; (layer_length * y) + x
        mov rcx, rax                        ; i = (layer_length * y) + x
.fill:
        pop rax                             ; restore fill value
        mov dword [edi + (ecx * 4)], eax    ; layer[y][x] = fill
        pop rcx                             ; restore y
.next_x:
        inc dl                              ; x++
        push rax                            ; save fill value
        mov al, byte [x1]                   ; load x1
        cmp dl, al                          ; test
        pop rax                             ; restore fill value
        jle .loop_x                         ; while (x <= x1)
.next_y:
        inc cl                              ; y++
        push rax                            ; save fill value
        mov al, byte [y1]                   ; load y1
        cmp cl, al                          ; test
        pop rax                             ; restore fill value
        jle .loop_y                         ; while (y <= y1)
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
