; General scratchpad to keep my head straight while testing

; *****************************************************************************************

        mov rax, LAYER_SIZE                 ; 
        mov rbx, __float32__(0.0)           ; fill value
        mov rdi, test_layer_a               ;
        call layer_fill                     ; 

        mov rax, LAYER_SIZE                 ;
        mov rbx, __float32__(0.7)           ; 0x3F000000
        mov rdi, test_layer_b               ;
        call layer_fill                     ;

        mov rax, LAYER_SIZE                 ;
        mov rdi, test_layer_a               ;
        mov rsi, test_layer_b               ;
        call layer_add                      ;

        mov rax, __float32__(1.0)           ; fill value
        mov rdi, test_layer_a               ; pointer to layer
        mov rbx, 0x1402040A05               ; 5x10 rect at (4,2) with layer length 20
        call layer_rect                     ; fill layer with rect

        mov rax, __float32__(1.0)           ; fill value
        mov rdi, test_layer_a               ; pointer to layer
        mov rbx, 0x07051404                 ; 4 radius circle at (5,7) with layer length 20
        call layer_circ                     ; fill layer with circle

; *****************************************************************************************

        xor rcx, rcx                        ; i = 0
.loop_test:
        mov rdx, 0x1400000000               ; 5x10 rect at (4,2) with layer length 20

        mov rax, 10                         ; range = [0-10)
        call rand32_range                   ; generate random number
        add dh, al                          ;

        mov rax, 10                         ; range = [0-10)
        call rand32_range                   ; generate random number
        add dl, al                          ;

        push rcx                            ; save i
        xor rcx, rcx                        ;

        mov rax, 10                         ; range = [0-10)
        call rand32_range                   ; generate random number
        add cl, al                          ;

        mov rax, 10                         ; range = [0-10)
        call rand32_range                   ; generate random number
        add ch, al                          ;

        shl rcx, 16                         ;
        add rdx, rcx                        ;
        pop rcx                             ; restore i

        mov rax, __float32__(1.0)           ; fill value
        mov rbx, rdx                        ; rect args
        mov rdi, test_layer_a               ; pointer to layer
        call layer_rect                     ; fill layer with rect

        inc rcx                             ; i++
        cmp rcx, 2                          ; check loop condition
        jl .loop_test                       ; while (i < TRAIN_PASSES)

; *****************************************************************************************

.write:
        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        mov rsi, test_layer_a               ;
        mov rdi, test_file_name             ; pointer to file name
        call ppm_fmatrix                    ; save float matrix to PPM file
