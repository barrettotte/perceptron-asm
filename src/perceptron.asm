        global _start

        extern layer_clear
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
        TEST_SEED:    equ 0x1337            ; test PRNG seed

        section .data
test_layer:     times LAYER_SIZE dd __float32__(0.50)

        section .rodata
test_file_name: db "temp", 0x00

        section .bss
weights:        resw LAYER_SIZE             ; weight matrix
inputs:         resw LAYER_SIZE             ; input matrix 

        section .text
_start:                                     ; ***** main entry *****
        finit                               ; empty stack, mask exceptions, set default rounding to nearest
main:
        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        ;mov rsi, inputs                     ; pointer to inputs matrix
        mov rsi, test_layer
        mov rdi, test_file_name             ; pointer to file name
        call ppm_fmatrix                    ; save float matrix to PPM file

        ; rdrand eax
        ; mov rax, TEST_SEED
        ; call srand
        ; mov rax, 10
        ; call rand32_range

        ; int count = 0;
        ;
        ; for (int i = 0; i < TRAIN_PASSES; i++) {
        ;   for (int j = 0; j < SAMPLE_SIZE; j++) {
        ;
        ;     // make random rectangle
        ;     layer_clear();
        ;     x = rand(0,LAYER_LEN), y = rand(0,LAYER_LEN);
        ;     w = LAYER_LEN-x, h = LAYER_LEN-y;
        ;     layer_rect(inputs, x, y, w, h, 1.0); // add rect
        ;
        ;     if (feed_fwd(inputs, weights) > BIAS) {
        ;       layer_sub(inputs, weights);  // sub inputs from weights
        ;       ppm_fmatrix(weights, "training/weights-xxx.ppm");
        ;       count++;
        ;     }
        ;
        ;     // make random circle
        ;     layer_clear();
        ;     cx = rand(0,LAYER_LEN), cy = rand(0,LAYER_LEN);
        ;     r = MAX
        ;     if (r > cx) r = cx;
        ;     if (r > cy) r = cy;
        ;     if (r > LAYER_LEN - cx) r = LAYER_LEN - cx;
        ;     if (r > LAYER_LEN - cy) r = LAYER_LEN - cy;
        ;     r = rand(1, r);
        ;     layer_circ(inputs, cx, cy, r, 1.0);
        ;
        ;     if (feed_fwd(inputs, weights) < BIAS) {
        ;       layer_add(inputs, weights);  // add inputs to weights
        ;       ppm_fmatrix(weights, "training/weights-xxx.ppm");
        ;       count++;
        ;     }
        ;   }
        ;   if (count <= 0) break;
        ; }

        xor rdi, rdi                        ; clear exit code
end:
        mov rax, SYS_EXIT                   ; command
        syscall                             ; call kernel
