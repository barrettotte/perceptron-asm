        global _start
        extern count_digits
        extern ppm_fmatrix
        
        ; config - move to config.inc?
        HEIGHT:       equ 20                ; height of layer
        WIDTH:        equ 20                ; width of layer
        SAMPLE_SIZE:  equ 10                ; sample size for training model
        TRAIN_PASSES: equ 50                ; number of training passes to perform

        LAYER_SIZE:   equ HEIGHT * WIDTH

        ; TODO: move to common.inc
        SYS_WRITE:    equ 1
        SYS_EXIT:     equ 60

        section .data

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

        mov rax, SYS_WRITE                  ; command
        mov rdi, 1                          ; set file handle to stdout
        mov rsi, msg_hello                  ; pointer to message
        mov rdx, msg_hello_len              ; length of message
        syscall                             ; call kernel

        ; TODO: output weights to PPM
        mov rsi, weights                    ; TODO:
        

        mov dword [rsi], __float32__(123.45)
        add rsi, 4
        mov dword [rsi], __float32__(678.90)
        add rsi, 4

        ; float     hex        bin  sign  exponent  mantissa
        ; 123.45    0x42f6e666      0     10000101  11101101110011001100110
        ; 678.90    0x4429b99a      0     10001000  01010011011100110011010
        ;
        ; 0x4429b99a 0x42f6e666

        mov rax, 0x00FF1414                 ; TODO: get from config
        mov rdi, test_file_name             ; TODO: source pointer
        call ppm_fmatrix

debug:
        nop
        nop
        nop
        nop
        nop

        ; TODO: generate random rectangle
        ; TODO: generate random circle

        ; TODO: create training data folder    (DEBUG only)
        ; TODO: create training data PPM files (DEBUG only)

        ; TODO: report untrained model results
        ; TODO: train
        ; TODO: save each pass weights as PPM  (DEBUG only)
        ; TODO: report each pass results

        ; TODO: report trained model results

        xor rdi, rdi                        ; clear exit code, 0 = success
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
