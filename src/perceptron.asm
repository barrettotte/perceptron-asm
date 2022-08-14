        global _start

        extern layer_fill
        extern layer_add
        extern layer_sub
        extern layer_randcirc
        extern layer_randrect
        extern ppm_fmatrix
        extern rand32_range
        extern srand

        %include "inc/config.inc"
        %include "inc/common.inc"

        LAYER_SIZE:   equ LAYER_LEN * LAYER_LEN

        section .data
weights:        times LAYER_SIZE dd __float32__(0.0) ; weight matrix
inputs:         times LAYER_SIZE dd __float32__(0.0) ; input matrix

        section .rodata
output_file:    db "model", 0x00            ; output file name

        section .bss
tmpf1:          resd 1                      ; temp float
tmpf2:          resd 1                      ; temp float

        section .text
_start:                                     ; ***** main entry *****
        finit                               ; empty stack, mask exceptions, set default rounding to nearest
main:
        xor rcx, rcx                        ; i = 0
.train_loop:
        mov rax, TRAIN_SEED                 ; load training seed
        call srand                          ; seed random number generator
        call train                          ; perform a round of training on the model
        cmp rax, 0                          ; check if training done - no adjustments to model
        jle .train_done                     ; if (adj <= 0) break;
.train_next:
        inc rcx                             ; i++
        cmp rcx, TRAIN_PASSES               ; check loop condition
        jl .train_loop                      ; while (i < TRAIN_PASSES)
.train_done:
        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        mov rsi, weights                    ; pointer to weights matrix (model)
        mov rdi, output_file                ; pointer to file name
        call ppm_fmatrix                    ; save float matrix to PPM file
.results:
        call verify                         ; verify model
        mov dword [tmpf1], eax              ; save adj
        mov ecx, SAMPLE_SIZE                ;
        shl ecx, 1                          ; SAMPLE_SIZE * 2
        mov dword [tmpf2], ecx              ;
.test:
        fld1                                ; ST0 = 1
        fld dword [tmpf1]                   ; ST0 = adj, ST1 = 1
        fld dword [tmpf2]                   ; ST0 = (SAMPLE_SIZE*2), ST1 = adj, ST2 = 1
        fdivp                               ; ST0 = (adj / (SAMPLE_SIZE * 2)), ST1 = 1
        fsubp                               ; ST0 = 1 - (adj / (SAMPLE_SIZE * 2))
        fstp dword [tmpf1]                  ; save model success = 1 - (adj / (SAMPLE_SIZE) * 2))

        mov ebx, dword [tmpf1]              ; load model success
        
        nop ; TODO: print to console
            ;  print("Trained model success rate of {success}")
.end:
        xor rdi, rdi                        ; clear exit code
        mov rax, SYS_EXIT                   ; command
        syscall                             ; call kernel

; *****************************************************************************
; feed_fwd - Calculate weighted sum of perceptron
;
; rax (ret) - weighted sum of perceptron
; *****************************************************************************
feed_fwd:
        push rcx                            ; save rcx
        push rdx                            ; save rdx

        mov dword [tmpf1], __float32__(0.0) ; out = 0.0
        mov rdi, inputs                     ; load pointer to inputs matrix
        mov rsi, weights                    ; load pointer to weights matrix
        xor rcx, rcx                        ; i = 0
.loop_i:
        fld dword [rsi + (rcx * 4)]         ; ST0 = weights[i]
        fld dword [rdi + (rcx * 4)]         ; ST0 = inputs[i], ST1=weights[i]
        fmulp                               ; ST0 = weights[i] * inputs[i]
        fld dword [tmpf1]                   ; ST0 = out, ST1=weights[i] * inputs[i]
        faddp                               ; ST0 = out + (weights[i] * inputs[i])
        fstp dword [tmpf1]                  ; out += weights[i] * inputs[i]
.next_i:
        inc rcx                             ; i++
        cmp rcx, LAYER_SIZE                 ; check loop condition
        jl .loop_i                          ; while (i < LAYER_SIZE)
.end:
        mov eax, dword [tmpf1]              ; return weighted sum
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        ret                                 ; end of feed_fwd subroutine

; *****************************************************************************
; train - Training pass on the model.
;
; rax (ret) - number of adjustments done to model
; *****************************************************************************
train:
        push rbx                            ; save rbx
        push rcx                            ; save rcx
        push rdx                            ; save rdx
        push rdi                            ; save rdi

        xor rdx, rdx                        ; adj = 0
        xor rcx, rcx                        ; i = 0
.sample_loop:
.rect:
        mov rdi, inputs                     ; pointer to inputs matrix
        mov rbx, LAYER_SIZE                 ; 
        mov rax, __float32__(0.0)           ; fill value
        call layer_fill                     ; clear matrix
        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        call layer_randrect                 ; generate random rectangle

        mov rsi, inputs                     ; load pointer to inputs matrix
        call feed_fwd                       ; calculate weighted sum
        cmp rax, BIAS                       ; check if model needs adjusting
        jle .circ                           ; if (feed_fwd <= BIAS) then model needs no adjustment
.rect_adjust:
        mov rax, LAYER_SIZE                 ;
        mov rdi, weights                    ; load pointer to weights matrix (output)
        mov rsi, inputs                     ; load pointer to inputs matrix
        call layer_sub                      ; subtract inputs from weights
        inc rdx                             ; adj++
.circ:
        mov rdi, inputs                     ; pointer to inputs matrix
        mov rbx, LAYER_SIZE                 ;
        mov rax, __float32__(0.0)           ; fill value
        call layer_fill                     ; clear matrix
        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        call layer_randcirc                 ; generate random circle

        mov rsi, inputs                     ; load pointer to inputs matrix
        call feed_fwd                       ; calculate weighted sum
        cmp rax, BIAS                       ; check if model needs adjusting
        jge .next_sample                    ; if (feed_fwd >= BIAS) then model needs no adjustment
.circ_adjust:
        mov rax, LAYER_SIZE                 ;
        mov rdi, weights                    ; load pointer to weights matrix (output)
        mov rsi, inputs                     ; load pointer to inputs matrix
        call layer_add                      ; add inputs to weights
        inc rdx                             ; adj++
.next_sample:
        inc rcx                             ; i++
        cmp rcx, SAMPLE_SIZE                ; check loop condition
        jl .sample_loop                     ; while (i < SAMPLE_SIZE)
.end:
        mov rax, rdx                        ; return adjustments made to model

        pop rdi                             ; restore rdi
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rbx                             ; restore rbx
        ret                                 ; end of train subroutine

; *****************************************************************************
; verify - Verify how the trained model does against new data.
;
; rax (ret) - number of adjustments done to trained model
; *****************************************************************************
verify:
        push rdx                            ; save rdx
        push rcx                            ; save rcx

        mov rax, VERIFY_SEED                ; load verification seed
        call srand                          ; seed random number generator

        xor rdx, rdx                        ; adj = 0
        xor rcx, rcx                        ; i = 0
.sample_loop:
.rect:
        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        mov rdi, inputs                     ; pointer to inputs matrix
        call layer_randrect                 ; generate random rectangle
        call feed_fwd                       ; calculate weighted sum
        cmp rax, BIAS                       ; check if model needs adjusting
        jge .circ                           ; if (feed_fwd >= BIAS) then model needs no adjustment
.rect_adjust:
        inc rbx                             ; adj++
.circ:
        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        mov rdi, inputs                     ; pointer to inputs matrix
        call layer_randcirc                 ; generate random circle
        call feed_fwd                       ; calculate weighted sum
        cmp rax, BIAS                       ; check if model needs adjusting
        jge .sample_next                    ; if (feed_fwd >= BIAS) then model needs no adjustment
.circ_adjust:
        inc rbx                             ; adj++
.sample_next:
        inc rcx                             ; i++
        cmp rcx, SAMPLE_SIZE                ; check loop condition
        jl .sample_loop                     ; while (i < SAMPLE_SIZE)
.end:
        mov rax, rbx                        ; return adj

        pop rcx                             ; restore rcx
        pop rdx                             ; restore rdx
        ret                                 ; end verify subroutine
