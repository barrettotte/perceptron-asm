        ; PPM file utilities

        global ppm_write                    ; TODO: void ppm_write()

        PPM_EXT:   equ 0x6D70702E           ; .ppm
        P6_HEADER: equ 0x0A0D3650           ; P6 CR LF

        section .text
ppm_new:                                    ; ***** create new ppm file *****
                                            ; rsi = pointer to base file name

        mov rdi, file_name                  ; destination pointer
        mov rcx, 4                          ; TODO: source string length
        lea rbx, [rcx]                      ; copy byte src[rcx] to dst[rax + rcx]
        rep movsb                           ; repeat byte copying until rcx=0
        mov dword [rdi], PPM_EXT            ; add ".ppm" to end of file name
        add rdi, 4                          ; increment pointer
        mov byte [rdi], 0x00                ; null terminate string

        mov rax, 2                          ; sys_open command
        mov rdi, file_name                  ; destination pointer
        mov rsi, 0102o                      ; file mode - r/w
        mov rdx, 0666o                      ; file permissions - r/w
        syscall                             ; call kernel

        mov [fd], rax                       ; store file descriptor
        ret                                 ; end of ppm_new subroutine

ppm_add_header:                             ; ***** add header to PPM file *****
                                            ; TODO: args
        
        mov rdi, file_buffer                ; pointer to file buffer
        mov dword [rdi], P6_HEADER          ; load first line of PPM header
        add rdi, 4                          ; increment pointer

        ; TODO: convert matrix dimensions to ASCII and add to file buffer
        ; "20 20 255" CR LF - 11 bytes

        ; null terminate file buffer?

        mov rax, 1                          ; sys_write command
        mov rdi, [fd]                       ; file descriptor
        mov rsi, file_buffer                ; pointer to string
        mov rdx, 4                          ; string length TODO:
        syscall                             ; call kernel

        ret                                 ; end of ppm_add_header subroutine

ppm_close:                                  ; ***** close PPM file
        mov rax, 3                          ; sys_close command
        mov rdi, [fd]                       ; file descriptor
        syscall                             ; call kernel
        ret                                 ; end ppm_close subroutine

ppm_write:                                  ; ***** write nxm array to PPM file *****
        ; file name pointer
        ; array pointer
        ; width m, height n, max color (use one reg; m[16], n[16], color[16])

        mov rsi, test_file_name             ; source pointer
        call ppm_new                        ; create new PPM file, fd contains new file
        call ppm_add_header                 ; add PPM header
        
        ; TODO: write matrix to file

        call ppm_close                      ; close PPM file

        ret                                 ; end of ppm_write subroutine

        section .data

        section .rodata
test_file_name: db "temp"

        section .bss
fd:             resq 0                      ; scratch file descriptor
file_name:      resb 32                     ; scratch file name
file_buffer:    resb 64                     ; scratch file buffer