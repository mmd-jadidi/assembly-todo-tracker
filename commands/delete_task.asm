%ifndef DELETE_TASK_ASM
%define DELETE_TASK_ASM

section .data
    msg_del_syntax_err db "    ❌ Syntax error: DELETE requires a task ID.", NL, 0
    msg_del_not_found  db "    ❌ Task not found.", NL, 0
    msg_del_success    db "    ✅ Task deleted.", NL, 0

section .bss
    del_in_buf  resb 8192
    del_out_buf resb 8192
    del_tgt_id  resb 32
    del_cur_id  resb 32

section .text

handle_delete:
    mov rdi, input_buffer
    call skip_word
    mov rsi, rax
    
    cmp byte [rsi], 0
    je .syntax_error
    
    mov rdi, del_tgt_id
.copy_tgt:
    mov al, [rsi]
    cmp al, ' '
    je .tgt_done
    cmp al, 0
    je .tgt_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .copy_tgt
.tgt_done:
    mov byte [rdi], 0
    
    cmp rdi, del_tgt_id
    je .syntax_error
    
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .not_found_file
    
    mov r8, rax
    mov rdi, r8
    mov rsi, del_in_buf
    mov rdx, 8192
    call readFile
    mov r9, rax
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .not_found_file
    
    mov rsi, del_in_buf
    mov rdi, del_out_buf
    xor r12, r12
    
.process_line:
    cmp byte [rsi], 0
    je .finish_processing
    
    mov r13, rsi
    
    mov rcx, del_cur_id
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
    mov rdi, del_tgt_id
    mov rsi, del_cur_id
    call strcmp
    mov r14, rax
    pop rsi
    pop rdi
    
    cmp r14, 0
    jne .copy_rest_of_line
    
    mov r12, 1
    
.skip_rest_of_line:
    mov al, [rsi]
    cmp al, 0
    je .finish_processing
    inc rsi
    cmp al, NL
    je .process_line
    jmp .skip_rest_of_line
    
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
    sub rdx, del_out_buf
    
    mov rdi, r8
    mov rsi, del_out_buf
    call writeFile
    
    mov rdi, r8
    call closeFile
    
    mov rsi, msg_del_success
    call printString
    jmp .end

.not_found_file:
.not_found:
    mov rsi, msg_del_not_found
    call printString
    jmp .end

.syntax_error:
    mov rsi, msg_del_syntax_err
    call printString

.end:
    ret

%endif
