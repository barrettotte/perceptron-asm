        global _start                       ;
        
        HEIGHT:       equ 20                ; height of layer
        WIDTH:        equ 20                ; width of layer
        SAMPLE_SIZE:  equ 10                ; sample size for training model
        TRAIN_PASSES: equ 50                ; number of training passes to perform

        section .text

_start:                                     ; ***** entry *****
        mov eax, 1                          ; request feature report
        cpuid                               ; check CPU features 
        xor rax, rax                        ;
        bt edx, 0x0                         ; test bit 0 for x87 FPU
        setc al                             ; set carry if FPU found
        jnc err_fpu                         ; if !C, no FPU found

        mov rax, 1                          ; write command
        mov rdi, 1                          ; set file handle to stdout
        mov rsi, msg_hello                  ; pointer to message
        mov rdx, msg_hello_len              ; length of message
        syscall                             ; invoke syscall

        ; TODO: init weights to zero
        ; TODO: output weights to PPM

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
        mov rax, 1                          ; write command
        mov rdi, 1                          ; set file handle to stdout
        mov rsi, msg_err_1                  ; pointer to error message
        mov rdx, msg_err_1_len              ; length of error message
        syscall                             ; invoke syscall
        mov rdi, 1                          ; set exit status
        jmp end                             ; exit program with failure

end:                                        ; ***** end of main *****
        mov rax, 60                         ; exit command
        syscall                             ; invoke syscall

        section .data

bias:           dq 20.0                     ; bias used for training model

msg_hello:      db "Hello world",
                db 0x0D, 0x0A, 0x00
msg_hello_len:  equ $ - msg_hello

msg_err_1:      db "CPU does not have floating point support",
                db 0x0D, 0x0A, 0x00
msg_err_1_len:  equ $ - msg_err_1
