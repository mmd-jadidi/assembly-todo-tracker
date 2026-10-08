%ifndef EDIT_TASK_ASM
%define EDIT_TASK_ASM

section .data
    msg_edit_syntax_err db "    ❌ Syntax error: EDIT requires ID and quoted description.", NL, 0
    msg_edit_not_found  db "    ❌ Task not found.", NL, 0
    msg_edit_success    db "    ✅ Task edited.", NL, 0

section .bss
    edit_in_buf  resb 8192
    edit_out_buf resb 8192
    edit_tgt_id  resb 32
    edit_cur_id  resb 32
    edit_new_desc resb 256

section .text

handle_edit:
    mov rdi, input_buffer
    call skip_word
    mov rsi, rax
    
    cmp byte [rsi], 0
    je .syntax_error
    
    mov rdi, edit_tgt_id
.copy_tgt:
    mov al, [rsi]
    cmp al, ' '
    je .tgt_done
    cmp al, 0
    je .syntax_error
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_tgt
.tgt_done:
    mov byte [rdi], 0
    
    cmp rdi, edit_tgt_id
    je .syntax_error
    
.skip_spaces_edit:
    cmp byte [rsi], ' '
    jne .parse_quotes
    inc rsi
    jmp .skip_spaces_edit
    
.parse_quotes:
    cmp byte [rsi], '"'
    jne .syntax_error
    inc rsi
    
    mov rdi, edit_new_desc
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
    
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .not_found_file
    
    mov r8, rax
    mov rdi, r8
    mov rsi, edit_in_buf
    mov rdx, 8192
    call readFile
    mov r9, rax
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .not_found_file
    
    mov rsi, edit_in_buf
    mov rdi, edit_out_buf
    xor r12, r12
    
.process_line:
    cmp byte [rsi], 0
    je .finish_processing
    
    mov r13, rsi
    
    mov rcx, edit_cur_id
.id_loop:
    mov al, [rsi]
    cmp al, '|'
    je .id_done
    cmp al, 0
    je .id_done_eof
    cmp al, NL
    je .id_done_eof
    mov [rcx], al
    inc rsi
    inc rcx
    jmp .id_loop
.id_done:
    mov byte [rcx], 0
    
    push rdi
    push rsi
    mov rdi, edit_tgt_id
    mov rsi, edit_cur_id
    call strcmp
    mov r14, rax
    pop rsi
    pop rdi
    
    cmp r14, 0
    jne .copy_rest_of_line
    
    mov r12, 1
    
    mov r15, r13
.copy_prefix_loop:
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    cmp al, '|'
    jne .copy_prefix_loop
    
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    
    push rsi
    mov rsi, edit_new_desc
.copy_new_desc:
    mov al, [rsi]
    cmp al, 0
    je .new_desc_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_new_desc
.new_desc_done:
    pop rsi
    
.skip_old_desc:
    mov al, [rsi]
    cmp al, 0
    je .finish_processing
    cmp al, NL
    je .finish_skip
    inc rsi
    jmp .skip_old_desc
.finish_skip:
    mov byte [rdi], NL
    inc rdi
    inc rsi
    jmp .process_line
    
.copy_rest_of_line:
    mov r15, r13
.copy_all_loop:
    cmp r15, rsi
    je .copy_rest_loop
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    jmp .copy_all_loop
.copy_rest_loop:
    mov al, [rsi]
    cmp al, 0
    je .finish_processing
    mov [rdi], al
    inc rsi
    inc rdi
    cmp al, NL
    je .process_line
    jmp .copy_rest_loop

.id_done_eof:
    mov r15, r13
.malformed_copy:
    cmp r15, rsi
    je .malformed_done
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    jmp .malformed_copy
.malformed_done:
    cmp byte [rsi], 0
    je .finish_processing
    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .process_line
    
.finish_processing:
    mov byte [rdi], 0
    
    cmp r12, 0
    je .not_found
    
    push rdi
    mov rdi, db_filename
    call createFile
    mov r8, rax
    pop rdi
    
    mov rdx, rdi
    sub rdx, edit_out_buf
    
    mov rdi, r8
    mov rsi, edit_out_buf
    call writeFile
    
    mov rdi, r8
    call closeFile
    
    mov rsi, msg_edit_success
    call printString
    jmp .end

.not_found_file:
.not_found:
    mov rsi, msg_edit_not_found
    call printString
    jmp .end

.syntax_error:
    mov rsi, msg_edit_syntax_err
    call printString

.end:
    ret

%endif
