        section .data

        section .rodata

        section .bss
length:         resb 1                      ; layer length
radius:         resb 1                      ; radius
xsq:            resw 1                      ; x^2
ysq:            resw 1                      ; y^2
rsq:            resw 1                      ; radius^2
fill:           resd 1                      ; fill value

        section .text

; *****************************************************************************
; layer_circ - Create a circle on layer filled with given value (unfilled...)
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

        mov dword [fill], eax               ; save fill value
        mov rax, rbx                        ; load arguments
        shr rax, 8                          ; move to 2nd argument
        and rax, 0xFF                       ; isolate layer_length
        mov byte [length], al               ; save layer_length

        mov rax, rbx                        ; load arguments
        and rax, 0xFF                       ; isolate circ.radius
        mov byte [radius], al               ; store circ.radius
        mov rdx, rax                        ; circ.radius operand
        imul rdx                            ; circ.radius * circ.radius
        mov word [rsq], ax                  ; save circ.radius^2

        movzx rcx, byte [radius]            ; load circ.radius
        neg rcx                             ; y = -circ.radius
.loop_y:
        movzx rdx, byte [radius]            ; load circ.radius
        neg rdx                             ; x = -circ.radius
.loop_x:
        push rdx                            ; save x
        mov rax, rdx                        ; load x operand
        imul rdx                            ; x * x
        mov word [xsq], ax                  ; save x^2
        mov rax, rcx                        ; load y operand
        imul rcx                            ; y * y
        mov word [ysq], ax                  ; save y^2
        movzx rax, word [xsq]               ; load x^2
        add ax, word [ysq]                  ; x^2 + y^2
        pop rdx                             ; restore x
.check1:
        push rbx                            ; save arguments        
        movzx rbx, word [rsq]               ; load circ.radius^2
        sub bl, byte [radius]               ; circ.radius^2 - circ.radius
        cmp rax, rbx                        ; test
        pop rbx                             ; restore arguments
        jg .check2                          ; if (x^2 + y^2 > circ.radius^2 - circ.radius)
        jmp .next_x
.check2:
        push rbx                            ; save arguments
        movzx rbx, word [rsq]               ; load circ.radius^2
        add bl, byte [radius]               ; circ.radius^2 + circ.radius
        cmp rax, rbx                        ; test
        pop rbx                             ; restore arguments
        jge .next_x                         ; if (x^2 + y^2 < circ.radius^2 + circ.radius)
.fill:
        push rdx                            ; save x
        mov rax, rbx                        ; load arguments
        shr rax, 24                         ; move to 4th argument
        and rax, 0xFF                       ; isolate circ.cy
        add rax, rdx                        ; circ.cy + y
        movzx rdx, byte [length]            ; load layer_length
        mul rdx                             ; (circ.cy + y) * layer_length

        mov rdx, rbx                        ; load arguments
        shr rdx, 16                         ; move to 3rd argument
        and rdx, 0xFF                       ; isolate circ.cy
        add rdx, rcx                        ; circ.cy + y
        
        push rcx                            ; save y
        add rax, rdx                        ; i = ((circ.cy + y) * layer_length) + (circ.cx + x)
        mov rcx, rax                        ; set i
        mov eax, dword [fill]               ; load fill value
        mov dword [edi + (ecx * 4)], eax    ; layer[y][x] = fill value
        pop rcx                             ; restore y
        pop rdx                             ; restore x
.next_x:
        inc rdx                             ; x++
        movzx rax, byte [radius]            ; load radius
        cmp rdx, rax                        ; test
        jle .loop_x                         ; while (x <= circ.radius)
.next_y:
        inc rcx                             ; y++
        movzx rax, byte [radius]            ; load radius
        cmp rcx, rax                        ; test
        jle .loop_y                         ; while (y <= circ.radius)
.end:
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rax                             ; restore rax
        pop rdi                             ; restore rdi
        ret                                 ; end of layer_circ subroutine