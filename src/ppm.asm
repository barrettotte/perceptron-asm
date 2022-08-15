        global ppm_fmatrix

        extern itoa_10
        extern strlen

        %include "inc/common.inc"

        PPM_P3:     equ 0x3350              ; P3
        PPM_P6:     equ 0x3650              ; P6
        PPM_EXT:    equ 0x6D70702E          ; .ppm
        FMODE:      equ 0o101               ; O_CREAT & O_WRONLY
        FPERMS:     equ 0o666               ; rw-rw-rw-
        SPACES_3:   equ 0x202020            ; 3 blanks
        F255:       equ __float32__(255.0)  ; float 255 (0x437F0000)
        RANGE:      equ __float32__(12.25)  ; color range = (255 * 0.10)
        RANGE2:     equ __float32__(25.50)  ; color range * 2
        BUFF_SIZE:  equ 512                 ; size of file buffer

        section .bss
fd:             resq 1                      ; scratch file descriptor
file_name:      resd 32                     ; scratch file name
tmpf1:          resd 1                      ; scratch float
tmpf2:          resd 1                      ; scratch float
rgb_buffer:     resd 3                      ; RGB buffer
file_buffer:    resb BUFF_SIZE              ; scratch file buffer, for per-line write

        section .text
; *****************************************************************************
; ppm_new - Create new PPM file
;
; rdi (arg) - pointer to base file name
; *****************************************************************************
ppm_new:
        push rax                            ; save rax
        push rsi                            ; save rsi

        call strlen                         ; find length of base file name
        mov rcx, rax                        ; base file name length

        mov rsi, rdi                        ; pointer to base file name
        mov rdi, file_name                  ; pointer to file name buffer
        lea rbx, [rcx]                      ; copy byte src[rcx] to dst[rcx]
        rep movsb                           ; repeat byte copying until rcx=0

        mov dword [rdi], PPM_EXT            ; add ".ppm" to end of file name
        add rdi, 4                          ; increment pointer
        mov byte [rdi], 0x00                ; null terminate string
.open:
        mov rax, SYS_OPEN                   ; command
        mov rdi, file_name                  ; destination pointer
        mov rsi, FMODE                      ; file mode
        mov rdx, FPERMS                     ; file permissions
        syscall                             ; call kernel
.test:
        mov [fd], rax                       ; store file descriptor
.end:
        pop rsi                             ; restore rsi
        pop rax                             ; restore rax
        ret                                 ; end of ppm_new subroutine

; *****************************************************************************
; ppm_header - Add header to PPM file
;
; rax (arg) - packed field of PPM arguments
;             0:7   - m rows of matrix
;             8:15  - n cols of matrix
;             16:63 - unused
; *****************************************************************************
ppm_header:
        push rax                            ; save rax
        push rbx                            ; save rbx
        push rdi                            ; save rdi
        push rsi                            ; save rsi

        mov rdi, file_buffer                ; pointer to file buffer
        mov word [rdi], PPM_P3              ; load PPM mode
        add rdi, 2                          ; increment pointer
        mov word [rdi], CRLF                ; load newline
        add rdi, 2                          ; increment pointer

        mov rbx, rax                        ; load packed field
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

        mov rax, 0xFF                       ; load max color value - 255
        call itoa_10                        ; convert to ASCII
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
.end:
        pop rsi                             ; restore rsi
        pop rdi                             ; restore rdi
        pop rbx                             ; restore rbx
        pop rax                             ; restore rax
        ret                                 ; end of ppm_header subroutine

; *****************************************************************************
; ppm_fmatrix - Write mxn float matrix to a new PPM file.
;
; rax (arg) - packed field of PPM arguments
;             0:7  - m rows of matrix
;             8:15 - n cols of matrix
;             16:63 - unused
; rdi (arg) - pointer to base file name string
; rsi (arg) - pointer to matrix of floats
; *****************************************************************************
ppm_fmatrix:
        push rax                            ; save rax
        push rsi                            ; save rsi
        push rdi                            ; save rdi
        push rbx                            ; save rbx
        push rcx                            ; save rcx
        push rdx                            ; save rdx
        
        call ppm_new                        ; create new PPM file; saves new file descriptor
        call ppm_header                     ; add header to PPM file

        xor rcx, rcx                        ; y = 0
.loop_y:
        mov rdi, file_buffer                ; reset pointer to file buffer
        xor rdx, rdx                        ; x = 0
.loop_x:
        push rax                            ; save PPM args
        push rcx                            ; save y counter
        mov dword eax, [rsi]                ; load layer[y][x]
        call float_rgb                      ; convert layer[y][x] to RGB

        mov dword eax, [rgb_buffer + 8]     ; load red value
        mov dword [rdi], SPACES_3           ; clear piece of buffer for value
        call itoa_10                        ; convert red value to ASCII
        mov rax, 3                          ; max digits
        sub rax, rcx                        ; find blanks needed for value
        add rdi, rax                        ; increment pointer
        mov byte [rdi], ' '                 ; add space
        inc rdi                             ; increment pointer

        mov dword eax, [rgb_buffer + 4]     ; load green value
        mov dword [rdi], SPACES_3           ; clear piece of buffer for value
        call itoa_10                        ; convert green value to ASCII
        mov rax, 3                          ; max digits
        sub rax, rcx                        ; find blanks needed for value
        add rdi, rax                        ; increment pointer
        mov byte [rdi], ' '                 ; add space
        inc rdi                             ; increment pointer

        mov dword eax, [rgb_buffer + 0]     ; load blue value
        mov dword [rdi], SPACES_3           ; clear piece of buffer for value
        call itoa_10                        ; convert blue value to ASCII
        mov rax, 3                          ; max digits
        sub rax, rcx                        ; find blanks needed for value
        add rdi, rax                        ; increment pointer
        mov byte [rdi], ' '                 ; add space
        inc rdi                             ; increment pointer

        mov dword [rdi], SPACES_3           ; 3 spaces between pixels
        add rdi, 3                          ; increment pointer

        pop rcx                             ; restore y counter
        pop rax                             ; restore PPM args
.next_x:
        add rsi, 4                          ; move to next layer[y][x]
        inc rdx                             ; x++
        push rax                            ; save PPM args
        shr rax, 8                          ; isolate cols
        cmp dx, ax                          ; check loop condition
        pop rax                             ; restore PPM args
        jl .loop_x                          ; while (x < cols)
.write_line:
        mov word [rdi], CRLF                ; load newline
        add rdi, 2                          ; increment buffer pointer
        mov byte [rdi], 0x00                ; null terminate buffer

        push rax                            ; save PPM args
        push rcx                            ; save y counter
        push rsi                            ; save pointer to matrix
        mov rdi, file_buffer                ; reset pointer to file buffer
        call strlen                         ; find length of file buffer

        mov rdx, rax                        ; length of file buffer
        mov rax, SYS_WRITE                  ; command
        mov rdi, [fd]                       ; file descriptor
        mov rsi, file_buffer                ; pointer to string
        syscall                             ; call kernel
        pop rsi                             ; restore pointer to matrix
        pop rcx                             ; restore y counter
        pop rax                             ; restore PPM args
.next_y:
        inc rcx                             ; y++
        push rax                            ; save PPM args
        and rax, 0xFF                       ; isolate rows
        cmp cx, ax                          ; check loop condition
        pop rax                             ; restore PPM args
        jl .loop_y                          ; while (y < rows)
.end:
        mov rax, SYS_CLOSE                  ; command
        mov rdi, [fd]                       ; PPM file descriptor
        syscall                             ; call kernel

        pop rdx                             ; restore rdx
        pop rcx                             ; restore rcx
        pop rbx                             ; restore rbx
        pop rdi                             ; restore rdi
        pop rsi                             ; restore rsi
        pop rax                             ; restore rax
        ret                                 ; end of ppm_fmatrix subroutine

; *****************************************************************************
; float_rgb - Convert float to RGB value.
;
;   Populates 12 byte buffer with RGB values [0-255]
;      0:31  - Blue
;      32:63 - Green
;      64:95 - Red
;
; eax (arg) - Float value to convert.
; *****************************************************************************
float_rgb:
        push rbx                            ; save rbx
        mov dword [tmpf1], eax              ; save x
.red:   
        fld dword [tmpf1]                   ; ST0 = x
        mov dword [tmpf2], RANGE            ;
        fld dword [tmpf2]                   ; ST0 = RANGE, ST1 = x
        faddp                               ; ST0 = RANGE + x
        mov dword [tmpf2], RANGE2           ; 
        fld dword [tmpf2]                   ; ST0 = RANGE2, ST1 = RANGE + x
        fdivp                               ; ST0 = (RANGE + x) / RANGE2
        fld1                                ; ST0 = 1, ST1 = (RANGE + x) / RANGE2
        fsubrp                              ; ST0 = 1 - ((RANGE + x) / 2)
        mov dword [tmpf2], F255             ; 
        fld dword [tmpf2]                   ; ST0 = 255.0, ST1 = 1 - ((RANGE + x) / 2)
        fmulp                               ; ST0 = 255.0 * (1 - ((RANGE + x) / 2))
        fisttp dword [tmpf2]                ; save red value
        mov dword ebx, [tmpf2]              ; load red value
        and ebx, 0xFF                       ; only save byte
        mov dword [rgb_buffer + 8], ebx     ; save red value to buffer
.green: 
        fld dword [tmpf1]                   ; ST0 = x
        mov dword [tmpf2], RANGE            ;
        fld dword [tmpf2]                   ; ST0 = RANGE, ST1 = x
        faddp                               ; ST0 = RANGE + x
        mov dword [tmpf2], RANGE2           ; 
        fld dword [tmpf2]                   ; ST0 = RANGE2, ST1 = RANGE + x
        fdivp                               ; ST0 = (RANGE + x) / RANGE2
        mov dword [tmpf2], F255             ; 
        fld dword [tmpf2]                   ; ST0 = 255.0, ST1 = 1 - ((RANGE + x) / 2)
        fmulp                               ; ST0 = 255.0 * (1 - ((RANGE + x) / 2))
        fisttp dword [tmpf2]                ; save green value
        mov dword ebx, [tmpf2]              ; load green value
        and ebx, 0xFF                       ; only save byte
        mov dword [rgb_buffer + 4], ebx     ; save green value to buffer
.blue:
        xor ebx, ebx                        ; no blue component
        mov dword [rgb_buffer + 0], ebx     ; save blue value to buffer
.end:
        pop rbx                             ; restore rbx
        ret                                 ; end of float_rgb subroutine

; *****************************************************************************
; ppm_clrbuffer - Clear buffer used for writing each line of PPM file.
;
; *****************************************************************************
ppm_clrbuffer:
        push rcx                            ; save rcx
        push rdi                            ; save rdi
        mov rdi, file_buffer                ; pointer to file buffer
        xor rcx, rcx                        ; i = 0
.clear:
        mov byte [rdi + rcx], 0x00          ; buffer[i] = 0x00
        inc rcx                             ; i++
        cmp rcx, BUFF_SIZE                  ; check loop condition
        jl .clear                           ; while (i < BUFF_SIZE)

        pop rdi                             ; restore rdi
        pop rcx                             ; restore rcx
        ret                                 ; end of ppm_clrbuffer subroutine
