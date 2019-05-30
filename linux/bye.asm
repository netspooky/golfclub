; 84 byte LINUX_REBOOT_CMD_POWER_OFF Binary Golf
BITS 64
  org 0x100000000
;---------------------+------+------------+------------------------------------------+-----------------------------+----------+
; CODE LISTING        | OFFS | ASSEMBLY   | CODE COMMENT                             | ELF HEADER STRUCT           | PHDR     | 
;---------------------+------+------------+------------------------------------------+-----------------------------+----------+
  db 0x7F, "ELF"      ; 0x0  |   7f454c46 | PROTIP: Can use magic as a constant ;)   | ELF Magic                   |          |
_start:               ;------|------------|------------------------------------------|-----------------------------|----------|
  mov edx, 0x4321fedc ; 0x04 | badcfe2143 | Moving magic values...                   | ei_class,ei_data,ei_version |          |
  mov esi, 0x28121969 ; 0x09 | be69191228 | into their respective places             | unused                      |          |
  jmp short reeb      ; 0x0E |       eb3c | Short jump down to @x4c                  | unused                      |          |
  dw 2                ; 0x10 |       0200 |                                          | e_type                      |          |
  dw 0x3e             ; 0x12 |       3e00 |                                          | e_machine                   |          |
  dd 1                ; 0x14 |   01000000 |                                          | e_version                   |          |
  dd _start - $$      ; 0x18 |   04000000 |                                          | e_entry                     |          |
phdr:                 ;------|------------|------------------------------------------|-----------------------------|----------|
  dd 1                ; 0x1C |   01000000 |                                          | e_entry                     | p_type   |
  dd phdr - $$        ; 0x20 |   1c000000 |                                          | e_phoff                     | p_flags  |
  dd 0                ; 0x24 |   00000000 |                                          | e_phoff                     | p_offset |
  dd 0                ; 0x28 |   00000000 |                                          | e_shoff                     | p_offset |
  dq $$               ; 0x2C |   00000000 |                                          | e_shoff                     | p_vaddr  |
                      ; 0x30 |   01000000 |                                          | e_flags                     | p_vaddr  |
  dw 0x40             ; 0x34 |       4000 |                                          | e_shsize                    | p_addr   |
  dw 0x38             ; 0x36 |       3800 |                                          | e_phentsize                 | p_addr   |
  dw 1                ; 0x38 |       0100 |                                          | e_phnum                     | p_addr   |
  dw 2                ; 0x3A |       0200 |                                          | e_shentsize                 | p_addr   |
cya:                  ;------|------------|------------------------------------------|-----------------------------|----------|
  mov al, 0xa9        ; 0x3C |       b0a9 | Load syscall                             | e_shnum                     | p_filesz |
  syscall             ; 0x3E |       0f05 | Execute syscall                          | e_shstrndx                  | p_filesz |
  dd 0                ; 0x40 |   00000000 | Filler, should try to keep as all 0's    |                             | p_filesz |
  mov al, 0xa9        ; 0x44 |       b0a9 | Load syscall                             |                             | p_memsz  |
  syscall             ; 0x46 |       0f05 | Execute syscall                          |                             | p_memsz  |
  dd  0               ; 0x48 |   00000000 | Filler, should try to keep as all 0's    |                             | p_memsz  |
reeb:                 ;------|------------|------------------------------------------|-----------------------------|----------|
  mov edi, 0xfee1dead ; 0x4C | bfaddee1fe | Load magic "LINUX_REBOOT_CMD_POWER_OFF"  |                             | p_align  |
  jmp short cya       ; 0x51 |       ebe9 | Short jmp back to e_shnum/p_filesz @0x3C |                             | p_align  |
  nop                 ; 0x53 |         90 | Filler, could use this byte for code.    |                             | p_align  |
;---------------------+------+------------+------------------------------------------+-----------------------------+----------+
; Note that we are overlaying the ELF Header with the program headers.
; You have 12 bytes minus your short jump from 0x4-0x10 to store code
; Then you have 8 bytes within the program headers at 0x4c for more 
; code, plus e_shentsize and the lower bytes of p_filesz + p_memsz for
; storage and code if you stay within the bounds - still testing.
;
;      LINUX_REBOOT_CMD_POWER_OFF
;             (RB_POWER_OFF, 0x4321fedc; since Linux 2.1.30).  The message
;             "Power down." is printed, the system is stopped, and all power
;             is removed from the system, if possible.  If not preceded by a
;             sync(2), data will be lost.
; [ Compile ]
; nasm -f bin -o bye bye.nasm
;
; One Liner 
; base64 -d <<< f0VMRrrc/iFDvmkZEijrPAIAPgABAAAABAAAAAEAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAEAAOAABAAIAsKkPBQAAAACwqQ8FAAAAAL+t3uH+6+mQ > bye;chmod +x bye;sudo ./bye
;
; Syscall reference: http://man7.org/linux/man-pages/man2/reboot.2.html
