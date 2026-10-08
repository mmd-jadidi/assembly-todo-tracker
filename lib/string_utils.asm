; =============================================================================
;   LIBRARY: string_utils.asm
;
;   Description:
;   A collection of safe, tested string manipulation and I/O functions.
;   Pay close attention to the "Input" and "Output" comments for each function 
;   to know which registers to use!
; =============================================================================

%ifndef STRING_UTILS_ASM
%define STRING_UTILS_ASM

section .text

; --- System Call Constants for I/O ---
sys_read     equ     0
sys_write    equ     1
stdin        equ     0
stdout       equ     1
NL           equ     0xA    ; Newline character (\n)

; =============================================================================
;   SECTION 1: CONSOLE I/O (Printing and Reading)
; =============================================================================

; -----------------------------------------------------------------------------
; printString: Prints a null-terminated string to the console.
; Input:  rsi -> Pointer to the string to print.
; Output: None.
; -----------------------------------------------------------------------------
printString:
    push    rax
    push    rcx
    push    rdx
    push    rdi
    push    rsi

    mov     rdi, rsi        ; GetStrlen expects string in rdi
    call    GetStrlen       ; Returns length in rdx
    mov     rax, sys_write
    mov     rdi, stdout
    syscall

    pop     rsi
    pop     rdi
    pop     rdx
    pop     rcx
    pop     rax
    ret

; -----------------------------------------------------------------------------
; newLine: Prints a single newline character to the console.
; -----------------------------------------------------------------------------
newLine:
    push    rax
    push    rdi
    push    rsi
    push    rdx
    
    dec     rsp             ; Allocate 1 byte on stack
    mov     byte [rsp], NL
    mov     rax, sys_write
    mov     rdi, stdout
    mov     rsi, rsp
    mov     rdx, 1
    syscall
    inc     rsp             ; Free the 1 byte
    
    pop     rdx
    pop     rsi
    pop     rdi
    pop     rax
    ret

; -----------------------------------------------------------------------------
; readString: Reads user input from the console until they press Enter.
; Input:  rdi -> Pointer to the destination buffer (where to save the typing).
; Output: The user's input is saved in the buffer, null-terminated.
; -----------------------------------------------------------------------------
readString:
    push    rax
    push    rbx
    push    r12             ; <-- FIX: Use r12 instead of rcx
    push    rdx
    push    rsi
    push    rdi

    mov     rbx, rdi        ; Save buffer pointer in rbx
    xor     r12, r12        ; <-- FIX: r12 is our safe byte counter

.read_loop:
    mov     rax, sys_read
    mov     rdi, stdin
    lea     rsi, [rbx + r12] ; Read directly into the correct buffer offset
    mov     rdx, 1          ; Read 1 byte at a time
    syscall

    cmp     rax, 0          ; Error or EOF?
    jg      .check_newline
    cmp     r12, 0
    jg      .done
    mov     rax, 60
    xor     rdi, rdi
    syscall
.check_newline:    
    mov     al, [rbx + r12]
    cmp     al, NL          ; Did they press Enter?
    je      .done
    
    inc     r12
    jmp     .read_loop

.done:
    mov     byte [rbx + r12], 0 ; Replace the newline with a null-terminator
    pop     rdi
    pop     rsi
    pop     rdx
    pop     r12             ; <-- FIX: Pop r12
    pop     rbx
    pop     rax
    ret


; =============================================================================
;   SECTION 2: STRING MEASUREMENT & COMPARISON
; =============================================================================

; -----------------------------------------------------------------------------
; GetStrlen: Calculates the length of a string.
; Input:  rdi -> Pointer to the null-terminated string.
; Output: rdx -> The length of the string (number of characters).
; -----------------------------------------------------------------------------
GetStrlen:
    push    rax
    push    rcx
    push    rdi

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    mov     rdx, rcx
    dec     rdx

    pop     rdi
    pop     rcx
    pop     rax
    ret

; -----------------------------------------------------------------------------
; strcmp: Compares two strings to see if they are exactly the same.
; Input:  rdi -> Pointer to string 1.
;         rsi -> Pointer to string 2.
; Output: rax -> 0 if strings are EQUAL, 1 if they are NOT EQUAL.
; -----------------------------------------------------------------------------
strcmp:
    push    rcx
    push    rdi
    push    rsi
.loop:
    mov     cl, [rdi]
    cmp     cl, [rsi]
    jne     .notequal
    cmp     cl, 0
    je      .equal
    inc     rdi
    inc     rsi
    jmp     .loop
.notequal:
    mov     rax, 1
    jmp     .end_strcmp
.equal:
    mov     rax, 0
.end_strcmp:
    pop     rsi
    pop     rdi
    pop     rcx
    ret

; =============================================================================
;   SECTION 3: STRING PARSING & MANIPULATION
; =============================================================================

; -----------------------------------------------------------------------------
; get_next_word: Reads one word (stopping at a space) and moves the cursor forward.
; Input:  rdi -> Cursor pointing into the source string.
;         rsi -> Destination buffer to save the word.
; Output: rdi -> Updated cursor, pointing AFTER the word.
; -----------------------------------------------------------------------------
get_next_word:
    push    rax
.copy_loop:
    mov     al, [rdi]
    cmp     al, ' '
    je      .done
    cmp     al, 0
    je      .done
    mov     [rsi], al
    inc     rdi
    inc     rsi
    jmp     .copy_loop
.done:
    mov     byte [rsi], 0
    pop     rax
    ret

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
skip_word:
    push    rcx
    mov     rcx, rdi
.skip_chars:
    mov     al, [rcx]
    cmp     al, 0
    je      .skip_word_done
    cmp     al, ' '
    je      .skip_spaces
    inc     rcx
    jmp     .skip_chars
.skip_spaces:
    mov     al, [rcx]
    cmp     al, ' '
    jne     .skip_word_done
    inc     rcx
    jmp     .skip_spaces
.skip_word_done:
    mov     rax, rcx
    pop     rcx
    ret

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
atoi:
    push    rcx
    push    rdx
    push    rdi
    xor     rax, rax
    xor     rcx, rcx
.atoi_loop:
    mov     cl, [rdi]
    cmp     cl, '0'
    jl      .atoi_done
    cmp     cl, '9'
    jg      .atoi_done
    sub     cl, '0'
    imul    rax, 10
    add     rax, rcx
    inc     rdi
    jmp     .atoi_loop
.atoi_done:
    pop     rdi
    pop     rdx
    pop     rcx
    ret

; -----------------------------------------------------------------------------
; -----------------------------------------------------------------------------
itoa:
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    r8
    push    r9
    
    mov     r8, rax
    mov     r9, rdi
    
    cmp     rax, 0
    jne     .itoa_not_zero
    mov     byte [rdi], '0'
    mov     byte [rdi+1], 0
    jmp     .itoa_end
    
.itoa_not_zero:
    mov     rbx, 10
    xor     rcx, rcx
    
.itoa_divide:
    xor     rdx, rdx
    div     rbx
    add     dl, '0'
    push    rdx
    inc     rcx
    cmp     rax, 0
    jne     .itoa_divide
    
.itoa_pop:
    pop     rdx
    mov     [rdi], dl
    inc     rdi
    dec     rcx
    jnz     .itoa_pop
    
    mov     byte [rdi], 0
    
.itoa_end:
    mov     rdi, r9
    pop     r9
    pop     r8
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    ret

%endif