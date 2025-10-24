BITS 32

              org     0x08048000

              db      0x7F, "ELF"             ; e_ident
              db      1, 1, 1, 0, 0
_start:
              mov     bl, 42
              xor     eax, eax
              inc     eax
              int     0x80
              dw      2                       ; e_type
              dw      3                       ; e_machine
              dd      1                       ; e_version
              dd      _start                  ; e_entry
              dd      phdr - $$               ; e_phoff
phdr:         dd      1                       ; e_shoff       ; p_type
              dd      0                       ; e_flags       ; p_offset
              dd      $$                      ; e_ehsize      ; p_vaddr
                                              ; e_phentsize
              dw      1                       ; e_phnum       ; p_paddr
              dw      0                       ; e_shentsize
              dd      filesize                ; e_shnum       ; p_filesz
                                              ; e_shstrndx
              dd      filesize                                ; p_memsz
              dd      5                                       ; p_flags
              dd      0x1000                                  ; p_align

filesize      equ     $ - $$