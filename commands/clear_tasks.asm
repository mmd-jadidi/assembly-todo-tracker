%ifndef CLEAR_TASKS_ASM
%define CLEAR_TASKS_ASM

section .data
    msg_clear_success db "    ✅ All tasks cleared.", NL, 0

section .text

handle_clear:
    mov rdi, db_filename
    call deleteFile
    
    mov rdi, db_filename
    call createFile
    cmp rax, 0
    jl .end
    
    mov rdi, rax
    call closeFile
    
    mov rsi, msg_clear_success
    call printString
    
.end:
    ret

%endif
