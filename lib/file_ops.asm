; =============================================================================
;   LIBRARY: file_ops.asm
;   
;   Description: 
;   This library provides safe, easy-to-use wrappers for Linux file system 
;   calls. You do not need to memorize syscall numbers. Just load the correct 
;   arguments into the registers and `call` these functions.
; =============================================================================

%ifndef FILE_OPS_ASM
%define FILE_OPS_ASM

section .data
    ; --- Error Messages ---
    err_msg_create      db "    ❌ FILE ERROR: Cannot create file.", 0xA, 0
    err_msg_open        db "    ❌ FILE ERROR: Cannot open file. Does it exist?", 0xA, 0
    err_msg_append      db "    ❌ FILE ERROR: Cannot open file for appending.", 0xA, 0
    err_msg_write       db "    ❌ FILE ERROR: Failed to write to file.", 0xA, 0
    err_msg_read        db "    ❌ FILE ERROR: Failed to read from file.", 0xA, 0
    err_msg_close       db "    ❌ FILE ERROR: Failed to close file.", 0xA, 0
    err_msg_delete      db "    ❌ FILE ERROR: Failed to delete file.", 0xA, 0

section .text

; --- 64-bit Linux Syscall Numbers ---
sys_read     equ     0
sys_write    equ     1
sys_open     equ     2
sys_close    equ     3
sys_lseek    equ     8
sys_unlink   equ     87

; --- File Access Flags ---
O_RDONLY     equ     0q000000
O_WRONLY     equ     0q000001
O_RDWR       equ     0q000002
O_CREAT      equ     0q000100
O_EXCL       equ     0q000200
O_TRUNC      equ     0q001000
O_APPEND     equ     0q002000

; --- File Permission Flags (0644) ---
sys_IRUSR    equ     0q400   ; User read
sys_IWUSR    equ     0q200   ; User write
sys_IRGRP    equ     0q040   ; Group read
sys_IROTH    equ     0q004   ; Others read

; --- Error Codes ---
EEXIST       equ     17      ; File exists error code

; =============================================================================
; createFile: Creates a new file. If it already exists, it is WIPED CLEAN (truncated).
; Input:  rdi -> Pointer to the filename string (null-terminated)
; Output: rax -> File Descriptor (FD) if successful, negative number on error.
; =============================================================================
createFile:
    mov     rax, sys_open
    mov     rsi, O_WRONLY | O_CREAT | O_TRUNC  ; Write, Create, Truncate
    mov     rdx, sys_IRUSR | sys_IWUSR | sys_IRGRP | sys_IROTH ; 0644 Permissions
    syscall
    cmp     rax, 0
    jle     .error
    ret
.error:
    push    rsi
    mov     rsi, err_msg_create
    call    printString
    pop     rsi
    ret

; =============================================================================
; createFileExclusive: Creates a file ONLY if it does not already exist.
; Input:  rdi -> Pointer to the filename string (null-terminated)
; Output: rax -> File Descriptor (FD) if successful. 
;         rax -> -17 (-EEXIST) if the file already exists.
; =============================================================================
createFileExclusive:
    mov     rax, sys_open
    mov     rsi, O_WRONLY | O_CREAT | O_EXCL   ; Write, Create, Fails if exists
    mov     rdx, sys_IRUSR | sys_IWUSR | sys_IRGRP | sys_IROTH
    syscall
    ret

; =============================================================================
; openFile: Opens a file for Reading/Writing. Quietly creates it if missing.
; Input:  rdi -> Pointer to the filename string (null-terminated)
; Output: rax -> File Descriptor (FD) if successful, negative number on error.
; =============================================================================
openFile:
    mov     rax, sys_open
    ; Added O_CREAT so it silently creates the database file on first run!
    mov     rsi, O_RDWR | O_CREAT
    mov     rdx, sys_IRUSR | sys_IWUSR | sys_IRGRP | sys_IROTH ; 0644 Permissions
    syscall
    cmp     rax, 0
    jle     .error
    ret
.error:
    push    rsi
    mov     rsi, err_msg_open
    call    printString
    pop     rsi
    ret
    
; =============================================================================
; appendFile: Opens a file and places the cursor at the VERY END for safe writing.
; Input:  rdi -> Pointer to the filename string (null-terminated)
; Output: rax -> File Descriptor (FD) if successful, negative number on error.
; =============================================================================
appendFile:
    mov     rax, sys_open
    mov     rsi, O_RDWR | O_APPEND | O_CREAT   ; Read/Write, Append, Create if missing
    mov     rdx, sys_IRUSR | sys_IWUSR | sys_IRGRP | sys_IROTH
    syscall
    cmp     rax, 0
    jle     .error
    ret
.error:
    push    rsi
    mov     rsi, err_msg_append
    call    printString
    pop     rsi
    ret

; =============================================================================
; writeFile: Writes data from a buffer into an open file.
; Input:  rdi -> File Descriptor (from openFile/createFile)
;         rsi -> Pointer to the data buffer you want to write
;         rdx -> EXACT length (number of bytes) to write
; Output: None. Prints error if it fails.
; =============================================================================
writeFile:
    mov     rax, sys_write
    syscall
    cmp     rax, 0
    jl      .error
    ret
.error:
    push    rsi
    mov     rsi, err_msg_write
    call    printString
    pop     rsi
    ret

; =============================================================================
; readFile: Reads data from an open file into a buffer. Automatically adds a null-terminator.
; Input:  rdi -> File Descriptor
;         rsi -> Pointer to the destination buffer
;         rdx -> Maximum number of bytes to read (buffer size)
; Output: rax -> Number of bytes actually read.
; =============================================================================
readFile:
    mov     rax, sys_read
    syscall
    cmp     rax, 0
    jl      .error
    ; Automatically null-terminate the buffer based on bytes read
    mov     byte [rsi + rax], 0
    ret
.error:
    push    rsi
    mov     rsi, err_msg_read
    call    printString
    pop     rsi
    ret

; =============================================================================
; closeFile: Safely closes an open file descriptor. ALWAYS call this when done.
; Input:  rdi -> File Descriptor to close
; Output: None.
; =============================================================================
closeFile:
    mov     rax, sys_close
    syscall
    cmp     rax, 0
    jl      .error
    ret
.error:
    push    rsi
    mov     rsi, err_msg_close
    call    printString
    pop     rsi
    ret

; =============================================================================
; deleteFile: Permanently deletes a file from the disk.
; Input:  rdi -> Pointer to the filename string (null-terminated)
; Output: None.
; =============================================================================
deleteFile:
    mov     rax, sys_unlink
    syscall
    ; We usually don't print an error here, because attempting to delete 
    ; a file that doesn't exist is common and harmless in rebuild loops.
    ret

%endif