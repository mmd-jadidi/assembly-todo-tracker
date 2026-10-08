; --- Core Libraries ---
%include "lib/string_utils.asm"
%include "lib/file_ops.asm"

; --- Command Handlers ---
%include "commands/add_task.asm"
%include "commands/list_tasks.asm"
%include "commands/mark_done.asm"
%include "commands/edit_task.asm"
%include "commands/delete_task.asm"
%include "commands/clear_tasks.asm"
%include "commands/stats.asm"
%include "commands/sort_tasks.asm"
%include "commands/archive_tasks.asm"

section .data
    ; --- User Interface Strings ---
    prompt          db "ToDo> ", 0
    unknown_cmd db "    ❌ Unknown command. Available: ADD, LIST, DONE, EDIT, DELETE, CLEAR, STATS, SORT, ARCHIVE, EXIT", NL, 0

    ; --- Command Keywords ---
    cmd_add         db "ADD", 0
    cmd_list        db "LIST", 0
    cmd_done        db "DONE", 0
    cmd_edit        db "EDIT", 0
    cmd_delete      db "DELETE", 0
    cmd_clear       db "CLEAR", 0
    cmd_stats       db "STATS", 0
    cmd_sort        db "SORT", 0
    cmd_exit        db "EXIT", 0
    cmd_archive     db "ARCHIVE", 0

    ; --- Global Database File Path ---
    db_filename     db "data/todo.txt", 0

section .bss
    ; --- Global Buffers ---
    ; Accessible by all included command handlers to save memory
    input_buffer    resb 256
    command_word    resb 32
    current_word    resb 32

section .text
    global _start

_start:
main_loop:
    call    newLine
    mov     rsi, prompt
    call    printString

    ; 1. Read User Input
    mov     rdi, input_buffer
    call    readString

    ; 2. Handle empty input (if user just presses Enter, loop back immediately)
    mov     al, [input_buffer]
    cmp     al, 0
    je      main_loop

    ; 3. Extract the first word to identify the command
    mov     rdi, input_buffer
    mov     rsi, command_word
    call    get_next_word

    ; =========================================================================
    ; --- COMMAND DISPATCHER ---
    ; =========================================================================

    mov     rdi, command_word
    mov     rsi, cmd_exit
    call    strcmp
    cmp     rax, 0
    je      Exit

    mov     rdi, command_word
    mov     rsi, cmd_add
    call    strcmp
    cmp     rax, 0
    je      dispatch_add

    mov     rdi, command_word
    mov     rsi, cmd_list
    call    strcmp
    cmp     rax, 0
    je      dispatch_list

    mov     rdi, command_word
    mov     rsi, cmd_done
    call    strcmp
    cmp     rax, 0
    je      dispatch_done

    mov     rdi, command_word
    mov     rsi, cmd_edit
    call    strcmp
    cmp     rax, 0
    je      dispatch_edit

    mov     rdi, command_word
    mov     rsi, cmd_delete
    call    strcmp
    cmp     rax, 0
    je      dispatch_delete

    mov     rdi, command_word
    mov     rsi, cmd_clear
    call    strcmp
    cmp     rax, 0
    je      dispatch_clear

    mov     rdi, command_word
    mov     rsi, cmd_stats
    call    strcmp
    cmp     rax, 0
    je      dispatch_stats

    mov     rdi, command_word
    mov     rsi, cmd_sort
    call    strcmp
    cmp     rax, 0
    je      dispatch_sort

    mov     rdi, command_word
    mov     rsi, cmd_archive
    call    strcmp
    cmp     rax, 0
    je      dispatch_archive

    ; If we got here, the command didn't match anything
    mov     rsi, unknown_cmd
    call    printString
    jmp     main_loop

; =========================================================================
; --- DISPATCH BLOCKS ---
; =========================================================================

dispatch_add:
    call    handle_add
    jmp     main_loop

dispatch_list:
    call    handle_list
    jmp     main_loop

dispatch_done:
    call    handle_done
    jmp     main_loop

dispatch_edit:
    call    handle_edit
    jmp     main_loop

dispatch_delete:
    call    handle_delete
    jmp     main_loop

dispatch_clear:
    call    handle_clear
    jmp     main_loop

dispatch_stats:
    call    handle_stats
    jmp     main_loop

dispatch_sort:
    call    handle_sort
    jmp     main_loop

dispatch_archive:
    call    handle_archive
    jmp     main_loop

Exit:
    ; Exit gracefully
    mov     rax, 60     ; sys_exit
    xor     rdi, rdi    ; Return code 0
    syscall