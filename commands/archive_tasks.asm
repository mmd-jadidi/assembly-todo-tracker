%ifndef ARCHIVE_TASKS_ASM
%define ARCHIVE_TASKS_ASM

section .data
    msg_archive_empty db "    ❌ No completed tasks to archive.", NL, 0
    msg_archive_success db "    ✅ Completed tasks archived.", NL, 0
    archive_filename db "data/archive.txt", 0

section .bss
    arc_in_buf  resb 8192
    arc_out_todo resb 8192
    arc_out_arc  resb 8192
    arc_cur_id   resb 32

section .text

handle_archive:
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .no_tasks
    
    mov r8, rax
    mov rdi, r8
    mov rsi, arc_in_buf
    mov rdx, 8192
    call readFile
    mov r9, rax
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .no_tasks
    
    mov rsi, arc_in_buf
    mov rdi, arc_out_todo
    mov r8, arc_out_arc
    xor r12, r12
    
.process_line:
    cmp byte [rsi], 0
    je .finish_processing
    
    mov r13, rsi
    
    mov rcx, arc_cur_id
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
    inc rsi
    
    mov bl, [rsi]
    
    cmp bl, 'D'
    je .archive_line
    
.keep_line:
    mov r15, r13
.keep_loop:
    cmp r15, rsi
    je .keep_rest
    mov al, [r15]
    mov [rdi], al
    inc r15
    inc rdi
    jmp .keep_loop
.keep_rest:
    mov al, [rsi]
    cmp al, 0
    je .finish_processing
    mov [rdi], al
    inc rsi
    inc rdi
    cmp al, NL
    je .process_line
    jmp .keep_rest
    
.archive_line:
    inc r12
    mov r15, r13
.archive_loop:
    cmp r15, rsi
    je .archive_rest
    mov al, [r15]
    mov [r8], al
    inc r15
    inc r8
    jmp .archive_loop
.archive_rest:
    mov al, [rsi]
    cmp al, 0
    je .finish_processing
    mov [r8], al
    inc rsi
    inc r8
    cmp al, NL
    je .process_line
    jmp .archive_rest

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
    mov byte [r8], 0
    
    cmp r12, 0
    je .no_tasks
    
    push rdi
    push r8
    mov rdi, db_filename
    call createFile
    mov rbx, rax
    pop r8
    pop rdi
    
    mov rdx, rdi
    sub rdx, arc_out_todo
    mov rdi, rbx
    mov rsi, arc_out_todo
    call writeFile
    mov rdi, rbx
    call closeFile
    
    push r8
    mov rdi, archive_filename
    call appendFile
    mov rbx, rax
    pop r8
    
    mov rdx, r8
    sub rdx, arc_out_arc
    mov rdi, rbx
    mov rsi, arc_out_arc
    call writeFile
    mov rdi, rbx
    call closeFile
    
    mov rsi, msg_archive_success
    call printString
    jmp .end

.no_tasks:
    mov rsi, msg_archive_empty
    call printString

.end:
    ret

%endif
