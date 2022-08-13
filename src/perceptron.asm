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

; .circ:
;         mov rax, LAYER_SIZE                 ; load layer size
;         push rbx                            ; save adj
;         mov rbx, __float32__(0.0)           ; load fill value
;         mov rdi, inputs                     ; load pointer to inputs matrix
;         call layer_fill                     ; clear layer
;         pop rbx                             ; restore adj
; .circ_cx:
;         mov rax, LAYER_LEN                  ; load range [0,LAYER_LEN)
;         call rand32_range                   ; generate random number
;         mov byte [tmp_x], al                ; store circ.cx = rand(0, LAYER_LEN-1)
; .circ_cy:
;         mov rax, LAYER_LEN                  ; load range [0,LAYER_LEN)
;         call rand32_range                   ; generate random number
;         mov byte [tmp_y], al                ; store circ.cy = rand(0, LAYER_LEN-1)
; .circ_r1:
;         movzx rax, byte [tmp_x]             ; tmp = circ.cx
;         movzx rdx, byte [tmp_y]             ; load circ.cy
;         cmp rax,rdx                         ; check clamp
;         jle .circ_r2                        ; if (tmp <= circ.cy); no clamp needed
;         mov rax, rdx                        ; clamp tmp to circ.cy
; .circ_r2:
;         mov rdx, LAYER_LEN                  ;
;         sub dl, byte [tmp_x]                ; LAYER_LEN - circ.cx
;         cmp rax, rdx                        ; check clamp
;         jle .circ_r3                        ; if (tmp <= LAYER_LEN - circ.cx); no clamp needed
;         mov rax, rdx                        ; clamp tmp to LAYER_LEN - circ.cx
; .circ_r3:
;         mov rdx, LAYER_LEN                  ;
;         sub dl, byte [tmp_y]                ; LAYER_LEN - circ.cy
;         cmp rax, rdx                        ; check clamp
;         jle .circ_r4                        ; if (tmp <= LAYER_LEN - circ.cy); no clamp needed
;         mov rax, rdx                        ; clamp tmp to LAYER_LEN - circ.cy
; .circ_r4:
;         cmp rax, 2                          ; check clamp
;         jge .circ_r5                        ; if (tmp >= 2); no clamp needed
;         mov rax, 2                          ; clamp tmp to 2
; .circ_r5:
;         dec rax                             ; set range to [0, tmp-1]
;         call rand32_range                   ; generate random number
;         inc rax                             ; adjust random number to range [1, tmp)
;         mov byte [tmp_l], al                ; save circ.r
; .circ_draw:
;         push rbx                            ; save adj
;         xor rbx, rbx                        ; clear circ args
;         mov bl, byte [tmp_y]                ; args[0] = circ.cy
;         shl rbx, 8                          ; move to next arg
;         mov bl, byte [tmp_x]                ; args[1] = circ.cx
;         shl rbx, 8                          ; move to next arg
;         mov bl, LAYER_LEN                   ; args[2] = layer length
;         shl rbx, 8                          ; move to next arg
;         mov bl, byte [tmp_l]                ; args[3] = circ.r
;         mov rax, __float32__(1.0)           ; load fill value
;         mov rdi, inputs                     ; load pointer to layer
;         call layer_circ                     ; generate circle in layer
;         pop rbx                             ; restore adj
; .circ_activate:
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call feed_fwd                       ; calculate weighted sum
;         cmp rax, BIAS                       ; check if activated
;         jge .next_sample                    ; if (feed_fwd >= BIAS) then circ inactive

;         mov rax, LAYER_SIZE                 ;
;         mov rdi, weights                    ; load pointer to weights matrix (output)
;         mov rsi, inputs                     ; load pointer to inputs matrix
;         call layer_add                      ; add inputs to weights
;         inc rbx                             ; adj++
; .circ_dbg:
;         mov rax, LAYER_LEN                  ; PPM width
;         shl rax, 8                          ; move width to 2nd byte
;         or rax, LAYER_LEN                   ; PPM height in 1st byte
;         mov rsi, weights                    ; pointer to weights matrix (model)
;         mov rdi, output_file                ; pointer to file name
;         call ppm_fmatrix                    ; save float matrix to PPM file
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
