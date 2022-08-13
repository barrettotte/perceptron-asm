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
ffwd:           resd 1                      ; temp feed forward output

        section .text
_start:                                     ; ***** main entry *****
        finit                               ; empty stack, mask exceptions, set default rounding to nearest
main:
        xor rcx, rcx                        ; i = 0
.train_loop:
        mov rax, TRAIN_SEED                 ; load training seed
        call srand                          ; seed random number generator

        call train                          ; round of training
        cmp rax, 0                          ; check if training done (no adjustments to model)
        jle .verify                         ; if (adj <= 0) break;
.train_next:
        inc rcx                             ; i++
        cmp rcx, TRAIN_PASSES               ; check loop condition
        jl .train_loop                      ; while (i < TRAIN_PASSES)
.verify:
        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        mov rsi, weights                    ; pointer to weights matrix (model)
        mov rdi, output_file                ; pointer to file name
        call ppm_fmatrix                    ; save float matrix to PPM file

        mov rax, VERIFY_SEED                ; load verification seed
        call srand                          ; seed random number generator
        
        nop ; TODO: verify model
        ; int adj = 0;
        ; for (int i = 0; i < SAMPLE_SIZE; i++) {
        ;   random_rect();
        ;   float temp = feed_forward(inputs, weights);
        ;   if (temp > BIAS)
        ;     adj++;
        ;   
        ;  random_circ();
        ;  float temp = feed_forward(inputs, weights);
        ;  if (temp < BIAS)
        ;     adj++;
        ;
        ;  adj / (SAMPLE_SIZE * 2) == fail rate
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

        mov dword [ffwd], __float32__(0.0)  ; out = 0.0
        mov rdi, inputs                     ; load pointer to inputs matrix
        mov rsi, weights                    ; load pointer to weights matrix
        xor rcx, rcx                        ; i = 0
.loop_i:
        fld dword [rsi + (rcx * 4)]         ; ST0 = weights[i]
        fld dword [rdi + (rcx * 4)]         ; ST0 = inputs[i], ST1=weights[i]
        fmulp                               ; ST0 = weights[i] * inputs[i]
        fld dword [ffwd]                    ; ST0 = out, ST1=weights[i] * inputs[i]
        faddp                               ; ST0 = out + (weights[i] * inputs[i])
        fstp dword [ffwd]                   ; out += weights[i] * inputs[i]
.next_i:
        inc rcx                             ; i++
        cmp rcx, LAYER_SIZE                 ; check loop condition
        jl .loop_i                          ; while (i < LAYER_SIZE)
.end:
        mov eax, dword [ffwd]               ; return weighted sum
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

        xor rdx, rdx                        ; tmp = 0
        xor rbx, rbx                        ; adj = 0
        xor rcx, rcx                        ; i = 0
.sample_loop:
        mov rdi, inputs                     ; pointer to inputs matrix
        mov rbx, LAYER_SIZE                 ; 
        mov rax, __float32__(0.0)           ; fill value
        call layer_fill                     ; clear matrix

        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        call layer_randrect                 ; generate random rectangle
.rect_activate:
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call feed_fwd                       ; calculate weighted sum
;         cmp rax, BIAS                       ; check if activated
;         jle .circ                           ; if (feed_fwd <= BIAS) then rect inactive

;         mov rax, LAYER_SIZE                 ;
;         mov rdi, weights                    ; load pointer to weights matrix (output)
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call layer_sub                      ; subtract inputs from weights
;         inc rbx                             ; adj++

        mov rdi, inputs                     ; pointer to inputs matrix
        mov rbx, LAYER_SIZE                 ;
        mov rax, __float32__(0.0)           ; fill value
        call layer_fill                     ; clear matrix

        mov rax, __float32__(1.0)           ; fill value
        mov rbx, LAYER_LEN                  ; 
        call layer_randcirc                 ; generate random circle

        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        mov rsi, inputs                     ; pointer to weights matrix (model)
        mov rdi, output_file                ; pointer to file name
        call ppm_fmatrix  
.circ_activate:
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call feed_fwd                       ; calculate weighted sum
;         cmp rax, BIAS                       ; check if activated
;         jge .next_sample                    ; if (feed_fwd >= BIAS) then circ inactive

;         mov rax, LAYER_SIZE                 ;
;         mov rdi, weights                    ; load pointer to weights matrix (output)
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call layer_add                      ; add inputs to weights
;         inc rbx                             ; adj++
.next_sample:
        inc rcx                             ; i++
        cmp rcx, SAMPLE_SIZE                ; check loop condition
        jl .sample_loop                     ; while (i < SAMPLE_SIZE)
.end:
        ; mov rax, rbx                        ; return adjustments made to model
        xor rax, rax ; TODO: tmp

        pop rdi                             ; restore rdi
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rbx                             ; restore rbx
        ret                                 ; end of train subroutine
