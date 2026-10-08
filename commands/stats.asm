%ifndef STATS_ASM
%define STATS_ASM

section .data
    msg_stats_title db "--- Task Statistics ---", NL, 0
    msg_stats_total db "Total Tasks: ", 0
    msg_stats_done  db "Completed:   ", 0
    msg_stats_pend  db "Pending:     ", 0
    msg_stats_pct   db "Completion:  ", 0
    msg_stats_pct_s db "%", NL, 0

section .bss
    stats_in_buf resb 8192
    stats_num_buf resb 32

section .text

handle_stats:
    mov rdi, db_filename
    call openFile
    cmp rax, 0
    jl .file_empty
    
    mov r8, rax
    mov rdi, r8
    mov rsi, stats_in_buf
    mov rdx, 8192
    call readFile
    mov r9, rax
    mov rdi, r8
    call closeFile
    
    cmp r9, 0
    jle .file_empty
    
    mov rsi, stats_in_buf
    xor r12, r12
    xor r13, r13
    xor r14, r14
    
.process_line:
    cmp byte [rsi], 0
    je .done_parsing
    
    cmp byte [rsi], NL
    je .skip_char
    
    inc r12
    
.find_pipe:
    mov al, [rsi]
    cmp al, '|'
    je .found_pipe
    cmp al, 0
    je .done_parsing
    cmp al, NL
    je .skip_to_next
    inc rsi
    jmp .find_pipe
    
.found_pipe:
    inc rsi
    mov al, [rsi]
    cmp al, 'D'
    je .is_done
    cmp al, 'P'
    je .is_pending
    jmp .skip_to_next
    
.is_done:
    inc r13
    jmp .skip_to_next
    
.is_pending:
    inc r14
    
.skip_to_next:
    mov al, [rsi]
    cmp al, 0
    je .done_parsing
    cmp al, NL
    je .skip_char
    inc rsi
    jmp .skip_to_next
    
.skip_char:
    inc rsi
    jmp .process_line
    
.file_empty:
    xor r12, r12
    xor r13, r13
    xor r14, r14
    
.done_parsing:
    xor r15, r15
    cmp r12, 0
    je .print_stats
    
    mov rax, r13
    imul rax, 100
    xor rdx, rdx
    mov rbx, r12
    div rbx
    mov r15, rax
    
.print_stats:
    mov rsi, msg_stats_title
    call printString
    
    mov rsi, msg_stats_total
    call printString
    mov rdi, stats_num_buf
    mov rax, r12
    call itoa
    mov rsi, stats_num_buf
    call printString
    call newLine
    
    mov rsi, msg_stats_done
    call printString
    mov rdi, stats_num_buf
    mov rax, r13
    call itoa
    mov rsi, stats_num_buf
    call printString
    call newLine
    
    mov rsi, msg_stats_pend
    call printString
    mov rdi, stats_num_buf
    mov rax, r14
    call itoa
    mov rsi, stats_num_buf
    call printString
    call newLine
    
    mov rsi, msg_stats_pct
    call printString
    mov rdi, stats_num_buf
    mov rax, r15
    call itoa
    mov rsi, stats_num_buf
    call printString
    mov rsi, msg_stats_pct_s
    call printString
    
    ret

%endif
