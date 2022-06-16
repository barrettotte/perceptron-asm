        global ppm_fmatrix
        extern itoa_10
        extern strlen

        %include "src/common.inc"

        PPM_P3:     equ 0x3350              ; P3
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

; *****************************************************************************
; ppm_new - Create new PPM file
;
; rdi (arg) - pointer to base file name
; *****************************************************************************
ppm_new:
        push rax                            ; store rax

        call strlen                         ; find length of base file name
        mov rcx, rax                        ; base file name length

        mov rsi, rdi                        ; pointer to base file name
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

        pop rax                             ; restore rax
        ret                                 ; end of ppm_new subroutine

; *****************************************************************************
; ppm_header_p3 - Add P3 header to PPM file
;
; rax (arg) - packed field of PPM arguments
;             0:7  - m rows of matrix
;             8:15 - n cols of matrix
;             16:31 - max color value
;             32:63 - unused
; *****************************************************************************
ppm_header_p3:
        push rax                            ; save rax
        push rbx                            ; save rbx

        mov rbx, rax                        ; move packed field
        
        mov rdi, file_buffer                ; pointer to file buffer
        mov word [rdi], PPM_P3              ; load PPM mode
        add rdi, 2                          ; increment pointer
        mov word [rdi], CRLF                ; load newline
        add rdi, 2                          ; increment pointer

        mov rax, rbx                        ; load packed field
        and rax, 0xFF                       ; get rows of matrix
        call itoa_10                        ; rows ASCII
        mov byte [rdi], ' '                 ; add space
        inc rdi                             ; increment pointer
        
        mov rax, rbx                        ; load packed field
        and rax, 0xFF00                     ; get columns of matrix
        shr rax, 8                          ; adjust field - shift 1 byte
        call itoa_10                        ; columns ASCII
        mov byte [rdi], ' '                 ; add space
        inc rdi                             ; increment pointer
        
        mov rax, rbx                        ; load packed field
        and rax, 0xFF0000                   ; get max color value
        shr rax, 16                         ; adjust field - shift 2 bytes
        call itoa_10                        ; max color value ASCII
        mov word [rdi], CRLF                ; newline
        add rdi, 2                          ; increment pointer

        mov byte [rdi], 0x00                ; null terminate file buffer
        mov rdi, file_buffer                ; reset pointer
        call strlen                         ; calculate length of file buffer
        mov rdx, rax                        ; store file buffer length

        mov rax, SYS_WRITE                  ; command
        mov rdi, [fd]                       ; file descriptor
        mov rsi, file_buffer                ; pointer to string
        syscall                             ; call kernel

        pop rbx                             ; restore rbx
        pop rax                             ; restore rax
        ret                                 ; end of ppm_header_p3 subroutine

; *****************************************************************************
; ppm_fmatrix - Write mxn float matrix to a new PPM file.
;
; rax (arg) - packed field of PPM arguments
;             0:7  - m rows of matrix
;             8:15 - n cols of matrix
;             16:31 - max color value
;             32:63 - unused
; rdi (arg) - pointer to base file name string
; rsi (arg) - pointer to matrix of floats
; *****************************************************************************
ppm_fmatrix:
        call ppm_new                        ; create new PPM file
        call ppm_header_p3                  ; add P3 header to PPM file

        ; loop over rows,cols

        ; TODO: function to convert float to int 0-255 (binary)
        
        ; TODO: build pixel[3] = {int r, int g, int b}

        ; TODO: convert int to ASCII

        ; TODO: write ASCII to file

        mov rax, SYS_CLOSE                  ; command
        mov rdi, [fd]                       ; PPM file descriptor
        syscall                             ; call kernel

        ret                                 ; end of ppm_fmatrix subroutine
