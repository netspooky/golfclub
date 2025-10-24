BITS 32

              org     0x08048000

ehdr:
              db      0x7F, "ELF"             ; e_ident
              db      1, 1, 1, 0, 0
_start:       mov     bl, 42
              xor     eax, eax
              inc     eax
              int     0x80
              dw      2                       ; e_type
              dw      3                       ; e_machine
              dd      1                       ; e_version
              dd      _start                  ; e_entry
              dd      phdr - $$               ; e_phoff
              dd      0                       ; e_shoff
              dd      0                       ; e_flags
              dw      ehdrsize                ; e_ehsize
              dw      phdrsize                ; e_phentsize
phdr:         dd      1                       ; e_phnum       ; p_type
                                              ; e_shentsize
              dd      0                       ; e_shnum       ; p_offset
                                              ; e_shstrndx
ehdrsize      equ     $ - ehdr
              dd      $$                                      ; p_vaddr
              dd      $$                                      ; p_paddr
              dd      filesize                                ; p_filesz
              dd      filesize                                ; p_memsz
              dd      5                                       ; p_flags
              dd      0x1000                                  ; p_align
phdrsize      equ     $ - phdr

filesize      equ     $ - $$
