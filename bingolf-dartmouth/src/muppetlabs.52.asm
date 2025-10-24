
BITS 32

              org     0x00001000

              db      0x7F, "ELF"             ; e_ident
              dd      1                                       ; p_type
              dd      0                                       ; p_offset
              dd      $$                                      ; p_vaddr 
              dw      2                       ; e_type        ; p_paddr
              dw      3                       ; e_machine
              dd      filesize                ; e_version     ; p_filesz
              dd      _start                  ; e_entry       ; p_memsz
              dd      4                       ; e_phoff       ; p_flags
              dd      0                       ; e_shoff       ; p_align
              db      0                       ; e_flags
_start:
              mov     bl, 42
              xor     eax, eax
              inc     eax                     ; e_ehsize
              int     0x80                    ; e_phentsize
              dw      1                       ; e_phnum
              dw      0                       ; e_shentsize
              dw      0                       ; e_shnum
              dw      0                       ; e_shstrndx

filesize      equ     $ - $$
