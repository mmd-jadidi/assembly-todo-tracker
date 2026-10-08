# x86-64 Assembly To-Do List Tracker

A modular command-line To-Do list manager written in pure **x86-64 NASM Assembly** for Linux using direct Linux system calls (syscalls).

## Features

- **ADD**: Create tasks with optional priority markers.
- **LIST**: View all pending `[ ]` and completed `[X]` tasks with formatted display.
- **DONE**: Mark a specific task as completed by ID.
- **EDIT**: Update existing task descriptions.
- **DELETE**: Remove a task by ID.
- **CLEAR**: Wipe all tasks.
- **STATS**: View task metrics (total, pending, completed, completion percentage).
- **ARCHIVE**: Move completed tasks to an archive log.
- **Persistent Storage**: Saves tasks directly to disk (`data/todo.txt`).

## Architecture & Code Structure

```
├── main.asm                # Entry point, interactive CLI loop, command dispatcher
├── build.sh                # Shell script for assembling (nasm) and linking (ld)
├── commands/               # Modular command implementations
│   ├── add_task.asm
│   ├── archive_tasks.asm
│   ├── clear_tasks.asm
│   ├── delete_task.asm
│   ├── edit_task.asm
│   ├── list_tasks.asm
│   ├── mark_done.asm
│   ├── sort_tasks.asm
│   └── stats.asm
├── lib/                    # Low-level utility libraries
│   ├── file_ops.asm        # Linux syscall wrappers (open, read, write, close, unlink)
│   └── string_utils.asm    # String processing (len, cmp, copy, atoi, itoa)
├── data/
│   └── todo.txt            # Database file storing serialized task records
└── report.pdf              # Comprehensive project report and documentation
```

## Prerequisites

- **NASM** (Netwide Assembler)
- **GNU ld** (Binutils)
- **Linux (x86-64)**

Install prerequisites on Debian/Ubuntu:
```bash
sudo apt update
sudo apt install nasm binutils
```

## Build and Run

1. Make the build script executable:
   ```bash
   chmod +x build.sh
   ```

2. Assemble, link, and run:
   ```bash
   ./build.sh
   ```

3. Interactive Commands:
   ```
   ToDo> ADD Finish Assembly Project
   ToDo> LIST
   ToDo> DONE 1
   ToDo> STATS
   ToDo> EXIT
   ```

## Documentation

For architectural design and implementation details, refer to [`report.pdf`](report.pdf).