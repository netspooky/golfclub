;-- 0xFFtactics.asm ------------------------------------------------------------
; build:
;   $ nasm -f bin 0xFFtactics.asm -o 0xFFtactics
BITS 64

        org 0x4FFFFFFFF000    ; Base Address

;-----------------------------+------+-------------+----------+-----------------
; ELF Header struct           | OFFS | ELFHDR      | PHDR     | ASSEMBLY OUTPUT
;-----------------------------+------+-------------+----------+-----------------
        db 0x7F, "ELF"        ; 0x00 | e_ident     | A        
        db 0xFE               ; 0x04 | ei_class    | B        
        db 0xFF               ; 0x05 | ei_data     | C        
        db 0xFF               ; 0x06 | ei_version  | D        
        db 0xFF               ; 0x07 |             | E        
        dq 0xFFFFFFFFFFFFFFFF ; 0x08 | e_padding   | F
        dw 0x02               ; 0x10 | e_type      | G        
        dw 0x3e               ; 0x12 | e_machine   | H        
        dd 0xFFFFFFFF         ; 0x14 | e_version   | I        
        dq 0x4FFFFFFFF078     ; 0x18 | e_entry     | J  
        dq phdr - $$          ; 0x20 | e_phoff     | K        
        dq 0xFFFFFFFFFFFFFFFF ; 0x28 | e_shoff     | L
        dd 0xFFFFFFFF         ; 0x30 | e_flags     | M        
        dw 0xFFFF             ; 0x34 | e_ehsize    | N        
        dw 0x38               ; 0x36 | e_phentsize | O        
        dw 1                  ; 0x38 | e_phnum     | P        
        dw 0xFFFF             ; 0x3A | e_shentsize | Q        
        dw 0xFFFF             ; 0x3C | e_shnum     | R        
        dw 0xFFFF             ; 0x3E | e_shstrndx  | S        
;-----------------------------+------+-------------+----------+-----------------
; Program Header Begin        | OFFS | ELFHDR      | PHDR     | ASSEMBLY OUTPUT
;-----------------------------+------+-------------+----------+-----------------
phdr:   dd 1                  ; 0x40 | PA          | p_type   | 
        dd 0xFFFFFFFF         ; 0x44 | PB          | p_flags  | 
        dq 0                  ; 0x48 | PC          | p_offset | 
        dq $$                 ; 0x50 | PD          | p_vaddr  |
        dq 0xFFFFFFFFFFFFFFFF ; 0x58 | PE          | p_paddr  |
        dq 0x7FFFFFF00        ; 0x60 | PF          | p_filesz |
        dq 0x7FFFFFF00        ; 0x68 | PG          | p_memsz  |
        dq 0xFFFFFFFFFFFFFFFE ; 0x70 | PH          | p_align  |
_start: mov    al,0x3c        ; exit syscall                  | b0 3c 
        mov    di, 6          ; return value 6                | 66 bf 06 00
        syscall               ; call the kernel               | 0f 05
;-- END ------------------------------------------------------------------------



