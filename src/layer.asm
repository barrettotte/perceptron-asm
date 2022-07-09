        global layer_fill
        global layer_add
        global layer_sub
        global layer_circ
        global layer_rect

        extern clampz

        %include "inc/common.inc"

        section .data

        section .rodata

        section .bss
length:         resb 1                      ; layer length
x0:             resb 1                      ; initial x
y0:             resb 1                      ; initial y
x1:             resb 1                      ; terminal x
y1:             resb 1                      ; terminal y
ydsq:           resw 1                      ; (delta y)^2
rsq:            resw 1                      ; radius^2
fill:           resd 1                      ; fill value

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
;             [0]  0:7   - circ.radius
;             [1]  8:15  - layer_length
;             [2]  16:23 - circ.cx
;             [3]  24:31 - circ.cy
;
;             ex: 0x07051403
;                 3 radius circle at (5,7) with layer length 20
; *****************************************************************************
layer_circ:
        push rdi                            ; save rdi
        push rax                            ; save rax
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        mov rcx, rbx                        ; load arguments
        shr rcx, 8                          ; move to 2nd argument
        and rcx, 0xFF                       ; isolate layer_length
        mov byte [length], cl               ; save layer_length
        mov dword [fill], eax               ; save fill value

        mov rax, rbx                        ; load arguments
        and rax, 0xFF                       ; isolate circ.radius
        mov rcx, rax                        ; save circ.radius
        mul rcx                             ; circ.radius^2
        mov word [rsq], ax                  ; save circ.radius^2

        mov rax, rbx                        ; load arguments
        shr rax, 16                         ; move to 3rd argument
        and rax, 0xFF                       ; isolate circ.cx        
        push rax                            ; save circ.cx
        sub rax, rcx                        ; circ.cx - circ.radius

        push rbx                            ; save arguments
        movzx rbx, byte [length]            ; load layer_length
        dec rbx                             ; layer_length - 1
        call clampz                         ; clamp x0 between (circ.cx - circ.radius, layer_length - 1)
        mov byte [x0], al                   ; x0 = clampz(circ.cx - circ.radius, layer_length - 1)
        mov rdx, rbx                        ; save layer_length - 1
        pop rbx                             ; restore arguments

        pop rax                             ; restore circ.cx
        add rax, rcx                        ; circ.cx + circ.radius
        push rbx                            ; save arguments
        mov rbx, rdx                        ; load layer_length-1
        call clampz                         ; clamp x1 between (circ.cx + circ.radius, layer_length - 1)
        mov byte [x1], al                   ; x1 = clampz(circ.cx + circ.radius, layer_length - 1)
        pop rbx                             ; restore arguments

        push rbx                            ; save arguments
        mov rax, rbx                        ; load arguments
        shr rax, 24                         ; move to 4th argument
        and rax, 0xFF                       ; isolate circ.cy
        push rax                            ; save circ.y

        sub rax, rcx                        ; circ.y - circ.radius
        mov rbx, rdx                        ; load layer_length-1
        call clampz                         ; clamp y0 between (circ.cy - circ.radius, layer_length - 1)
        mov byte [y0], al                   ; y0 = clampz(circ.cx - circ.radius, layer_length - 1)
.check:
        pop rax                             ; restore circ.y
        add rax, rcx                        ; circ.y + circ.radius
        mov rbx, rdx                        ; load layer_length-1
        call clampz                         ; clamp y1 between (circ.cy + circ.radius, layer_length - 1)
        mov byte [y1], al                   ; y1 = clampz(circ.cx + circ.radius, layer_length - 1)

        pop rbx                             ; restore arguments
        movzx rdx, byte [y0]                ; y = y0
.loop_y:
        push rdx                            ; save y
        mov rax, rbx                        ; load arguments
        shr rax, 24                         ; move to 4th argument
        and rax, 0xFF                       ; isolate circ.cy
        sub rdx, rax                        ; calc yd = y - circ.cy

        mov rax, rdx                        ; load yd operand
        imul rdx                            ; calc yd^2
        mov word [ydsq], ax                 ; save yd^2
        pop rdx                             ; restore y

        movzx rcx, byte [x0]                 ; x = x0
.loop_x:
        push rdx                            ; save y
        mov rax, rbx                        ; load arguments
        shr rax, 16                         ; move to 3rd argument
        and rax, 0xFF                       ; isolate circ.cx
        push rcx                            ; save x
        sub rcx, rax                        ; calc xd = x - circ.cx
        mov rax, rcx                        ; load xd operand
        imul rcx                            ; calc xd^2
        pop rcx                             ; restore x

        movzx rdx, word [ydsq]              ; load yd^2
        add rax, rdx                        ; yd^2 + xd^2
        movzx rdx, word [rsq]               ; load circ.radius^2
        cmp rax, rdx                        ; test
        pop rdx                             ; restore y
        jg .next_x                          ; if (xd^2 + yd^2 <= circ.radius^2) dont fill

        push rdx                            ; save y
        movzx rax, byte [length]            ; load layer_length
        mul rdx                             ; i = layer_length * y
        add rax, rcx                        ; i = (layer_length * y) + x
        pop rdx                             ; restore y

        push rcx                            ; save x
        mov rcx, rax                        ; load i
        mov eax, dword [fill]               ; load fill value
        mov dword [rdi + (rcx * 4)], eax    ; layer[i] = fill value
        pop rcx                             ; restore x
.next_x:
        inc rcx                             ; x++
        movzx rax, byte [x1]                ; load x1
        cmp rcx, rax                        ; test
        jle .loop_x                         ; while (x <= x1)
.next_y:
        inc rdx                             ; y++
        movzx rax, byte [y1]                ; load y1
        cmp rdx, rax                        ; test
        jle .loop_y                         ; while (y <= y1)
.end:
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rax                             ; restore rax
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
;                 5x10 rect at (4,2) with layer length 20
; *****************************************************************************
layer_rect:
        push rdi                            ; save rdi
        push rax                            ; save rax
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        mov rcx, rbx                        ; load arguments
        shr rcx, 32                         ; move to 5th argument
        and rcx, 0xFF                       ; isolate layer_length
        mov byte [length], cl               ; save layer_length
        mov dword [fill], eax               ; save fill value

        mov rcx, rbx                        ; load arguments
        shr rcx, 16                         ; clear lower arguments
        and rcx, 0xFFFF                     ; isolate (rect.x, rect.y)
        mov word [x0], cx                   ; save x0 = rect.x, y0 = rect.y

        mov rdx, rbx                        ; load arguments
        and rdx, 0xFFFF                     ; isolate (rect.width, rect.length)
        add rdx, rcx                        ; (rect.width + rect.x, rect.length + rect.y)
        sub rdx, 0x0101                     ; (rect.width + rect.x - 1, rect.length + rect.y - 1)
        mov word [x1], dx                   ; x1 = (rect.width + rect.x - 1), y1 = (rect.length + rect.y - 1)

        movzx rcx, byte [y0]                ; y = y0
.loop_y:
        movzx rdx, byte [x0]                ; x = x0
.loop_x:
        push rcx                            ; save y
        push rdx                            ; save x
        movzx rax, byte [length]            ; load layer_length
        mul rcx                             ; (layer_length * y)
        pop rdx                             ; restore x

        add rax, rdx                        ; (layer_length * y) + x
        mov rcx, rax                        ; i = (layer_length * y) + x
        mov eax, dword [fill]               ; load fill value
        mov dword [edi + (ecx * 4)], eax    ; layer[y][x] = fill value
        pop rcx                             ; restore y
.next_x:
        inc rdx                             ; x++
        movzx rax, byte [x1]                ; load x1
        cmp rdx, rax                        ; test
        jle .loop_x                         ; while (x <= x1)
.next_y:
        inc rcx                             ; y++
        movzx rax, byte [y1]                ; load y1
        cmp rcx, rax                        ; test
        jle .loop_y                         ; while (y <= y1)
.end:
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rax                             ; restore rax
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
