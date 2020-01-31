BITS 64

        org 0x100000000  ; Where to load this into memory

;----------------------+------+-------------+----------+------------------------
; ELF Header struct    | OFFS | ELFHDR      | PHDR     | ASSEMBLY OUTPUT
;----------------------+------+-------------+----------+------------------------
        db 0x7F, "ELF" ; 0x00 | e_ident     |          | 7f 45 4c 46
_start: push 1         ; 0x04 | ei_class    |          | 6a
                       ; 0x05 | ei_data     |          | 01
        pop rcx        ; 0x06 | ei_version  |          | 59
        mov rdi,rsp    ; 0x07 |             |          | 48 89 e7
        mov cl,0xde    ; 0x0A |             |          | b1 de 
        jmp setup      ; 0x0C |             |          | eb 46
        nop            ; 0x0E |             |          | 90
        nop            ; 0x0F |             |          | 90
;----------------------+------+-------------+----------+------------------------
; ELF Header struct ct.| OFFS | ELFHDR      | PHDR     | ASSEMBLY OUTPUT
;----------------------+------+-------------+----------+------------------------
        dw 2           ; 0x10 | e_type      |          | 02 00
        dw 0x3e        ; 0x12 | e_machine   |          | 3e 00
        dd 1           ; 0x14 | e_version   |          | 01 00 00 00
        dd _start - $$ ; 0x18 | e_entry     |          | 04 00 00 00 
;----------------------+------+-------------+----------+------------------------
; Program Header Begin | OFFS | ELFHDR      | PHDR     | ASSEMBLY OUTPUT
;----------------------+------+-------------+----------+------------------------
phdr:   dd 1           ; 0x1C |   ...       | p_type   | 01 00 00 00 
        dd phdr - $$   ; 0x20 | e_phoff     | p_flags  | 1c 00 00 00
        dd 0           ; 0x24 |   ...       | p_offset | 00 00 00 00
        dd 0           ; 0x28 | e_shoff     |   ...    | 00 00 00 00
        dq $$          ; 0x2C |   ...       | p_vaddr  | 00 00 00 00 
                       ; 0x30 | e_flags     |   ...    | 01 00 00 00 
        dw 0x40        ; 0x34 | e_shsize    | p_addr   | 40 00
        dw 0x38        ; 0x36 | e_phentsize |   ...    | 38 00
        dw 1           ; 0x38 | e_phnum     |   ...    | 01 00
        dw 2           ; 0x3A | e_shentsize |   ...    | 02 00
        dq 2           ; 0x3C | e_shnum     | p_filesz | 02 00 00 00 00 00 00 00
        dq 2           ; 0x44 |             | p_memsz  | 02 00 00 00 00 00 00 00  
setup: ; starts @ 0x4C - within p_align of PHDR
    ; Shoutout Anonymous_ for moving this part to p_align!
    ; This payload just does an execve syscall to open /bin/sh
    ; Encrypted payload is pushed onto the stack. The last byte of the first
    ; dword is 48, which will be the first byte of the decrypted payload. 
    ; It is not encrypted because...
    mov dword [rsp],    0x960cef48 ; c7 04 24 48 ef 0c 96   
    mov dword [rsp+4],  0xbcf1f165 ; c7 44 24 04 65 f1 f1 bc
    mov dword [rsp+8],  0xadf1b0b7 ; c7 44 24 08 b7 b0 f1 ad
    mov dword [rsp+12], 0x351f96b6 ; c7 44 24 0c b6 96 1f 35
    mov dword [rsp+16], 0x57968dd6 ; c7 44 24 10 d6 8d 96 57
    mov dword [rsp+20], 0x96898e39 ; c7 44 24 14 39 8e 89 96
    mov dword [rsp+24], 0xe56e3857 ; c7 44 24 18 57 38 6e e5
    mov dword [rsp+28], 0x0000dbd1 ; c7 44 24 1c d1 db 00 00
decrypt:
    ; The decrypt loop will exit with rcx = 0, so the last byte
    ; won't get decrypted. There are ways around this but for
    ; simplicity's sake we're just going to leave the first payload
    ; byte unencrypted.
    ; The decrypt routine is a simple xor 
    xor byte [rdi+rcx], 0xDE  ; 80 34 0f de 
    loop decrypt              ; e2 fa
    jmp rdi                   ; eb 08

;Assemble with 
; $ nasm -f bin bmpoly147.asm -o bmpoly147
; $ sha256sum bmpoly147
; ab814a1cba6b08ec6851c89be204f603323696c7290a5bdcf23b6cd886c8879a  bmpoly4
; $ xxd bmpoly147
; 00000000: 7f45 4c46 6a01 5948 89e7 b1de eb3e 9090  .ELFj.YH.....>..
; 00000010: 0200 3e00 0100 0000 0400 0000 0100 0000  ..>.............
; 00000020: 1c00 0000 0000 0000 0000 0000 0000 0000  ................
; 00000030: 0100 0000 4000 3800 0100 0200 0200 0000  ....@.8.........
; 00000040: 0000 0000 0200 0000 0000 0000 c704 2448  ..............$H
; 00000050: ef0c 96c7 4424 0465 f1f1 bcc7 4424 08b7  ....D$.e....D$..
; 00000060: b0f1 adc7 4424 0cb6 961f 35c7 4424 10d6  ....D$....5.D$..
; 00000070: 8d96 57c7 4424 1439 8e89 96c7 4424 1857  ..W.D$.9....D$.W
; 00000080: 386e e5c7 4424 1cd1 db00 0080 340f dee2  8n..D$......4...
; 00000090: faff e7                                  ...
;The one liner is
; base64 -d <<< f0VMRmoBWUiJ57He6z6QkAIAPgABAAAABAAAAAEAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAEAAOAABAAIAAgAAAAAAAAACAAAAAAAAAMcEJEjvDJbHRCQEZfHxvMdEJAi3sPGtx0QkDLaWHzXHRCQQ1o2WV8dEJBQ5jomWx0QkGFc4buXHRCQc0dsAAIA0D97i+v/n >p;chmod +x p;./p 
