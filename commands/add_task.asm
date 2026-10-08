%ifndef ADD_TASK_ASM
%define ADD_TASK_ASM

section .data
    msg_add_syntax_err db "    ❌ Syntax error", NL, 0
    msg_add_success    db "    Task added", NL, 0

section .bss
    add_read_buf resb 8192
    add_desc_buf resb 256
    add_out_buf  resb 512
    add_id_str   resb 32

section .text

handle_add:
    mov rdi, input_buffer
    call skip_word
    
    mov rsi, rax
    
    cmp byte [rsi], 0
    je .syntax_error
    
    mov al, [rsi]
    mov bl, '.'
    
    cmp al, '!'
    je .has_priority
    cmp al, '*'
    je .has_priority
    cmp al, '.'
    je .has_priority
    
    jmp .parse_quotes
    
.has_priority:
    mov bl, al
    inc rsi
    
.skip_spaces_after_prio:
    cmp byte [rsi], ' '
    jne .parse_quotes
    inc rsi
    jmp .skip_spaces_after_prio

.parse_quotes:
    cmp byte [rsi], '"'
    jne .syntax_error
    inc rsi
    
    mov rdi, add_desc_buf
    xor rcx, rcx
.desc_loop:
    mov al, [rsi]
    cmp al, 0
    je .syntax_error
    cmp al, '"'
    je .desc_done
    mov [rdi], al
    inc rsi
    inc rdi
    inc rcx
    jmp .desc_loop
    
.desc_done:
    cmp rcx, 0
    je .syntax_error
    
    mov byte [rdi], 0
    
    push rbx
    
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .file_error_or_empty
    
    mov r8, rax
    
    mov rdi, r8
    mov rsi, add_read_buf
    mov rdx, 8192
    call readFile
    
    mov r9, rax
    
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .empty_file
    
    mov rsi, add_read_buf
    add rsi, r9
    dec rsi
    
.skip_trailing_nl:
    cmp rsi, add_read_buf
    jl .empty_file
    cmp byte [rsi], NL
    jne .find_line_start
    dec rsi
    jmp .skip_trailing_nl
    
.find_line_start:
.back_loop:
    cmp rsi, add_read_buf
    jle .found_start
    cmp byte [rsi-1], NL
    je .found_start
    dec rsi
    jmp .back_loop
    
.found_start:
    mov rdi, rsi
    call atoi
    inc rax
    jmp .got_id

.empty_file:
.file_error_or_empty:
    mov rax, 1

.got_id:
    mov rdi, add_id_str
    call itoa
    
    pop rbx
    
    mov rdi, add_out_buf
    mov rsi, add_id_str
.copy_id:
    mov al, [rsi]
    cmp al, 0
    je .id_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_id
.id_done:
    
    mov byte [rdi], '|'
    inc rdi
    mov byte [rdi], 'P'
    inc rdi
    mov byte [rdi], '|'
    inc rdi
    mov [rdi], bl
    inc rdi
    mov byte [rdi], '|'
    inc rdi
    
    mov rsi, add_desc_buf
.copy_desc:
    mov al, [rsi]
    cmp al, 0
    je .desc_copied
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_desc
.desc_copied:
    
    mov byte [rdi], NL
    inc rdi
    mov byte [rdi], 0
    
    mov rdi, db_filename
    call appendFile
    cmp rax, 0
    jl .done
    mov r8, rax
    
    mov rdi, add_out_buf
    call GetStrlen      
    
    mov rdi, r8
    mov rsi, add_out_buf
    call writeFile
    
    mov rdi, r8
    call closeFile
    
    mov rsi, msg_add_success
    call printString
    
    jmp .done

.syntax_error:
    mov rsi, msg_add_syntax_err
    call printString

.done:
    ret

%endif
