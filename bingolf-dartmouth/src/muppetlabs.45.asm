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
              db      1                       ; e_phnum
                                              ; e_shentsize
                                              ; e_shnum
                                              ; e_shstrndx

filesize      equ     $ - $$

;muppetlabs.45.asm - annotation by netspooky
;00: 7f45 4c46 .... .... .... .... .... .... ; e_ident
;04: .... .... 0100 0000 .... .... .... .... ;             p_type
;08: .... .... .... .... 0000 0000 .... .... ;             p_offset 
;0C: .... .... .... .... .... .... 0010 0000 ;             p_vaddr 
;10: 0200 .... .... .... .... .... .... .... ; e_type      p_paddr
;12: .... 0300 .... .... .... .... .... .... ; e_machine   ''
;14: .... .... 2d00 0000 .... .... .... .... ; e_version   p_filesz
;18: .... .... .... .... 2510 0000 .... .... ; e_entry     p_memsz
;1C: .... .... .... .... .... .... 0400 0000 ; e_phoff     p_flags
;20: 0000 0000 .... .... .... .... .... .... ; e_shoff     p_align
;24: .... .... 00b3 2a31 .... .... .... .... ; e_flags
;28: .... .... .... .... c040 .... .... .... ; e_ehsize
;2A: .... .... .... .... .... cd80 .... .... ; e_phentsize
;2C: .... .... .... .... .... .... 01.. .... ; e_phnum
;2E: .... .... .... .... .... .... .... .... ; e_shentsize
;30: .... .... .... .... .... .... .... .... ; e_shnum
;32: .... .... .... .... .... .... .... .... ; e_shstrndx
