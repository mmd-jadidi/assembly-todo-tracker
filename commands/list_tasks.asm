%ifndef LIST_TASKS_ASM
%define LIST_TASKS_ASM

section .data
    msg_list_title db "--- To-Do List ---", NL, 0
    msg_list_empty db "    📭 The list is empty.", NL, 0
    list_str_pending db "[ ] ", 0
    list_str_done    db "[X] ", 0
    list_str_colon   db ": ", 0

section .bss
    list_read_buf resb 8192
    list_id_buf   resb 32
    list_desc_buf resb 256

section .text

handle_list:
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .file_empty
    
    mov r8, rax
    
    mov rdi, r8
    mov rsi, list_read_buf
    mov rdx, 8192
    call readFile
    
    mov r9, rax
    
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .file_empty
    
    mov rsi, msg_list_title
    call printString
    
    mov rsi, list_read_buf
    xor r10, r10
    
.parse_line:
    cmp byte [rsi], 0
    je .done_parsing
    
    cmp byte [rsi], NL
    je .skip_char
    
    mov rdi, list_id_buf
.id_loop:
    mov al, [rsi]
    cmp al, '|'
    je .id_done
    cmp al, 0
    je .done_parsing
    cmp al, NL
    je .skip_char
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .id_loop
.id_done:
    mov byte [rdi], 0
    inc rsi
    
    mov bl, [rsi]
    inc rsi
    
    cmp byte [rsi], '|'
    jne .find_next_nl
    inc rsi
    
    inc rsi
    
    cmp byte [rsi], '|'
    jne .find_next_nl
    inc rsi
    
    mov rdi, list_desc_buf
.desc_loop:
    mov al, [rsi]
    cmp al, NL
    je .desc_done
    cmp al, 0
    je .desc_done
    mov [rdi], al
    inc rsi
    inc rdi
    jmp .desc_loop
.desc_done:
    mov byte [rdi], 0
    
    cmp al, NL
    jne .skip_inc
    inc rsi
.skip_inc:
    
    push rsi
    
    cmp bl, 'D'
    je .print_done
.print_pending:
    mov rsi, list_str_pending
    call printString
    jmp .print_id
.print_done:
    mov rsi, list_str_done
    call printString
    
.print_id:
    mov rsi, list_id_buf
    call printString
    
    mov rsi, list_str_colon
    call printString
    
    mov rsi, list_desc_buf
    call printString
    call newLine
    
    pop rsi
    inc r10
    
    jmp .parse_line

.skip_char:
    inc rsi
    jmp .parse_line
    
.find_next_nl:
    mov al, [rsi]
    cmp al, NL
    je .skip_char
    cmp al, 0
    je .done_parsing
    inc rsi
    jmp .find_next_nl

.done_parsing:
    cmp r10, 0
    jg .end
.file_empty:
    mov rsi, msg_list_empty
    call printString

.end:
    ret

%endif
