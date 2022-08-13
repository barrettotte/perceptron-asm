        global _start

        extern layer_fill
        extern layer_add
        extern layer_sub
        extern layer_circ
        extern layer_rect
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
tmp_x:          resb 1                      ; temp x position
tmp_y:          resb 1                      ; temp y position
tmp_w:          resb 1                      ; temp width
tmp_l:          resb 1                      ; temp length
ffwd:           resd 1                      ; temp feed forward output

        section .text
_start:                                     ; ***** main entry *****
        finit                               ; empty stack, mask exceptions, set default rounding to nearest
main:
        mov rax, SEED                       ; load seed
        call srand                          ; seed random number generator

        xor rcx, rcx                        ; i = 0
.train_loop:
        call train                          ; round of training

        cmp rax, 0                          ; check if training done (no adjustments to model)
        jle .end                            ; if (adj <= 0) break;

        inc rcx                             ; i++
        cmp rcx, TRAIN_PASSES               ; check loop condition
        jl .train_loop                      ; while (i < TRAIN_PASSES)
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

        xor rbx, rbx                        ; adj = 0
        xor rcx, rcx                        ; i = 0
.sample_loop:

.rect:
        mov rax, LAYER_SIZE                 ; load layer size
        mov rbx, __float32__(0.0)           ; load fill value
        mov rdi, inputs                     ; load pointer to layer
        call layer_fill                     ; clear layer
.rect_x:
        mov rax, LAYER_LEN                  ; load range [0,LAYER_LEN)
        call rand32_range                   ; generate random number
        mov byte [tmp_x], al                ; store rect.x = rand(0, LAYER_LEN-1)
.rect_y:
        mov rax, LAYER_LEN                  ; load range [0,LAYER_LEN)
        call rand32_range                   ; generate random number
        mov byte [tmp_y], al                ; store rect.y = rand(0, LAYER_LEN-1)
.rect_w:
        mov rax, LAYER_LEN                  ; 
        sub rax, [tmp_x]                    ; tmp = LAYER_LEN - rect.x
        cmp rax, 2                          ; check for clamp
        jge .rect_w_set                     ; if (tmp >= 2); no need to clamp value
        mov rax, 2                          ; clamp tmp to 2
.rect_w_set:
        dec rax                             ; set range to [0, tmp-1]
        call rand32_range                   ; generate random number
        inc rax                             ; adjust random number to range [1, temp)
        mov byte [tmp_w], al                ; save rect.w
.rect_l:
        mov rax, LAYER_LEN                  ;
        sub rax, [tmp_y]                    ; tmp = LAYER_LEN - rect.y
        cmp rax, 2                          ; check for clamp
        jge .rect_l_set                     ; if (tmp >= 2); no need to clamp value
        mov rax, 2                          ; clamp tmp to 2
.rect_l_set:
        dec rax                             ; set range to [0, tmp-1]
        call rand32_range                   ; generate random number
        inc rax                             ; adjust random number to range [1, temp)
        mov byte [tmp_l], al                ; save rect.l
.rect_args:
        push rbx                            ; save adj
        xor rbx, rbx                        ; clear rect args
        mov rbx, LAYER_LEN                  ; args[0] = layer length
        shl rbx, 8                          ; move to next arg
        mov bl, byte [tmp_y]                ; args[1] = rect.y
        shl rbx, 8                          ; move to next arg
        mov bl, byte [tmp_x]                ; args[2] = rect.x
        shl rbx, 8                          ; move to next arg
        mov bl, byte [tmp_l]                ; args[3] = rect.length
        shl rbx, 8                          ; move to next arg
        mov bl, byte [tmp_w]                ; args[4] = rect.width
        mov rax, __float32__(1.0)           ; load fill value
        mov rdi, inputs                     ; load pointer to layer
        call layer_rect                     ; generate rectangle in layer
        pop rbx                             ; restore adj
.rect_activate:
        call feed_fwd                       ; calculate weighted sum

;     float tmp = feed_fwd(inputs, weights);
;     if (tmp > BIAS) {
;       layer_sub(inputs, weights);  // sub inputs from weights
;       ppm_fmatrix(weights, "training/weights-xxx.ppm");
;       count++;
;     }

.circ:
        mov rax, LAYER_SIZE                 ; load layer size
        mov rbx, __float32__(0.0)           ; load fill value
        mov rdi, inputs                     ; load pointer to layer
        call layer_fill                     ; clear layer

.circ_cx:
.circ_cy:
.circ_r:
;     cx = rand(0,LAYER_LEN), cy = rand(0,LAYER_LEN);
;     r = MAX
;     if (r > cx) r = cx;
;     if (r > cy) r = cy;
;     if (r > LAYER_LEN - cx) r = LAYER_LEN - cx;
;     if (r > LAYER_LEN - cy) r = LAYER_LEN - cy;
;     r = rand(1, r);

.circ_args:
;     layer_circ(inputs, cx, cy, r, 1.0);

.circ_activate:
        ; call feed_fwd                       ; calculate weighted sum
;     float tmp = feed_fwd(inputs, weights);
;     if (tmp < BIAS) {
;       layer_add(inputs, weights);  // add inputs to weights
;       ppm_fmatrix(weights, "training/weights-xxx.ppm");
;       count++;
;     }

        inc rcx                             ; i++
        cmp rcx, SAMPLE_SIZE                ; check loop condition
        jl .sample_loop                     ; while (i < SAMPLE_SIZE)
.end:
        mov rax, rbx                        ; return adjustments made to model

        pop rdi                             ; restore rdi
        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rbx                             ; restore rbx
        ret                                 ; end of train subroutine
