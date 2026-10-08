%ifndef SORT_TASKS_ASM
%define SORT_TASKS_ASM

section .data
    msg_sort_nyi db "    ❌ SORT is not implemented.", NL, 0

section .text

handle_sort:
    mov rsi, msg_sort_nyi
    call printString
    ret

%endif
