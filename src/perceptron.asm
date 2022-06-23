        global _start

        extern layer_clear
        extern layer_add
        extern layer_sub
        extern layer_circ
        extern layer_rect
        extern ppm_fmatrix

        %include "src/config.inc"
        %include "src/common.inc"

        LAYER_SIZE:   equ LAYER_LEN * LAYER_LEN

        section .data

temp_float:     dw 0.0

        section .rodata
bias:           dw 20.0                     ; bias used for training model

test_file_name: db "temp", 0x00

msg_hello:      db "Hello world",
                db 0x0D, 0x0A, 0x00
msg_hello_len:  equ $ - msg_hello

msg_err_1:      db "CPU does not have floating point support",
                db 0x0D, 0x0A, 0x00
msg_err_1_len:  equ $ - msg_err_1

        section .bss
weights:        resw LAYER_SIZE             ; weight vector
inputs:         resw LAYER_SIZE             ; input vector 

        section .text
_start:                                     ; ***** main entry *****
        mov rax, 1                          ; request feature report
        cpuid                               ; check CPU features 
        xor rax, rax                        ;
        bt rdx, 0x0                         ; test bit 0 for x87 FPU
        setc al                             ; set carry if FPU found
        jnc err_fpu                         ; if !C, no FPU found
        finit                               ; reset floating point registers

        call testing                        ; TODO: remove
main:
        mov rsi, weights                    ;
        mov rax, LAYER_LEN                  ; PPM width
        shl rax, 8                          ; move width to 2nd byte
        or rax, LAYER_LEN                   ; PPM height in 1st byte
        or rax, 0x00FF0000                  ; 255 color in 3rd byte

        mov rdi, test_file_name             ; TODO: source pointer
        call ppm_fmatrix

        ; TODO: main
        ;
        ; seed random - rdseed https://www.felixcloutier.com/x86/rdseed
        ;
        ; get random value - rdrand https://www.felixcloutier.com/x86/rdrand
        ;
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
        ;
        ;   if (count <= 0); 
        ;     break;
        ; }

        xor rdi, rdi                        ; clear exit code
        jmp end                             ; ended successfully

err_fpu:                                    ; ***** CPU has no FPU *****
        mov rax, SYS_WRITE                  ; command
        mov rdi, 1                          ; set file handle to stdout
        mov rsi, msg_err_1                  ; pointer to error message
        mov rdx, msg_err_1_len              ; length of error message
        syscall                             ; call kernel
        mov rdi, 1                          ; set exit status
        jmp end                             ; exit program with failure

end:                                        ; ***** end of main *****
        mov rax, SYS_EXIT                   ; command
        syscall                             ; call kernel



; TODO: remove, this is just screwing around
testing:
        mov rax, SYS_WRITE                  ; command
        mov rdi, 1                          ; set file handle to stdout
        mov rsi, msg_hello                  ; pointer to message
        mov rdx, msg_hello_len              ; length of message
        syscall                             ; call kernel

        ; temp float testing
        mov rsi, weights                    ;
        mov dword [rsi], __float32__(150.1)
        add rsi, 4
        mov dword [rsi], __float32__(245.5)
        add rsi, 4

        mov rsi, weights                    ; load pointer to float matrix
        add rsi, 4                          ; index 1 offset
        fld dword [rsi]                     ; load weights[1] into ST
        ; frndint                             ; round ST float to nearest integer and push ST
        fisttp dword [temp_float]           ; (pop ST) save truncated float; temp_float = (int) weights[1]

        ; temp_float = 0xF6 = 246

        nop
        nop
        nop
        ; 0x4316199A, 0x43758000

        ret