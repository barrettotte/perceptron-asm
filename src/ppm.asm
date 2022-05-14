        global ppm_fmatrix                  ; TODO: void ppm_fmatrix()

        ; TODO: move to common.inc
        SYS_WRITE:  equ 1
        SYS_OPEN:   equ 2
        SYS_CLOSE:  equ 3

        P6_HEADER:  equ 0x0A0D3650          ; P6 CR LF
        PPM_EXT:    equ 0x6D70702E          ; .ppm
        PPM_FMODE:  equ 0o102               ; O_CREAT
        PPM_FPERMS: equ 0o666               ; rw-rw-rw-

        section .data

        section .rodata

        section .bss
fd:             resd 1                      ; scratch file descriptor
file_name:      resb 32                     ; scratch file name
file_buffer:    resb 64                     ; scratch file buffer

        section .text

        ; TODO: move to utils.asm
; *****************************************************************************
; strlen - Calculates length of null-terminated string
;
; rdi (arg) - pointer to null-terminated string
; rax (ret) - length of string
; *****************************************************************************
strlen:
        push rcx                            ; save rcx
        xor ecx, ecx                        ; reset counter
        dec rcx                             ; counter = -1
        xor eax, eax                        ; reset AL
        repne scasb                         ; scan memory for AL
        sub rax, rcx                        ; scanned bytes + 1
        sub rax, 2                          ; final string length (-1 if "\0")
        pop rcx                             ; restore rcx
        ret                                 ; end strlen subroutine

; *****************************************************************************
; ppm_new - Create new PPM file
;
; rsi (arg) - pointer to base file name
; TODO: clobbers
; *****************************************************************************
ppm_new:
        mov rdi, rsi                        ; pointer to base file name
        call strlen                         ; find length of base file name
        mov rcx, rax                        ; base file name length

        mov rdi, file_name                  ; pointer to file name buffer
        lea rbx, [rcx]                      ; copy byte src[rcx] to dst[rcx]
        rep movsb                           ; repeat byte copying until rcx=0
        
        mov dword [rdi], PPM_EXT            ; add ".ppm" to end of file name
        add rdi, 4                          ; increment pointer
        mov byte [rdi], 0x00                ; null terminate string

        mov rax, SYS_OPEN                   ; command
        mov rdi, file_name                  ; destination pointer
        mov rsi, PPM_FMODE                  ; file mode
        mov rdx, PPM_FPERMS                 ; file permissions
        syscall                             ; call kernel

        mov [fd], rax                       ; store file descriptor
        ret                                 ; end of ppm_new subroutine

; *****************************************************************************
; ppm_header_p6 - Add P6 header to PPM file
;
; TODO: args/clobbers
; *****************************************************************************
ppm_header_p6:
        mov rdi, file_buffer                ; pointer to file buffer
        mov dword [rdi], P6_HEADER          ; load first line of PPM header
        add rdi, 4                          ; increment pointer

        ; TODO: convert matrix dimensions to ASCII and add to file buffer
        ; "20 20 255" CR LF - 11 bytes

        mov byte [rdi], 0x00                ; null terminate file buffer

        mov rdi, file_buffer                ; reset pointer
        call strlen                         ; calculate length of file buffer
        mov rdx, rax                        ; store file buffer length

        mov rax, SYS_WRITE                  ; command
        mov rdi, [fd]                       ; file descriptor
        mov rsi, file_buffer                ; pointer to string
        syscall                             ; call kernel

        ret                                 ; end of ppm_header_p6 subroutine

; *****************************************************************************
; ppm_fmatrix - Write mxn float matrix to a new PPM file.
;
; rsi (arg) - pointer to base file name string
; rax (arg) - packed field of PPM arguments
;             0:7  - m rows of matrix
;             8:15 - n cols of matrix
;             16:31 - max color value
;             32:63 - unused
; rbx (arg) - pointer to matrix
; TODO: clobbers
; *****************************************************************************
ppm_fmatrix:
        call ppm_new                        ; create new PPM file
        call ppm_header_p6                  ; add P6 header to PPM file
        
        ; TODO: write matrix to file

        mov rax, SYS_CLOSE                  ; command
        mov rdi, [fd]                       ; PPM file descriptor
        syscall                             ; call kernel

        ret                                 ; end of ppm_fmatrix subroutine
