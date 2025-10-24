; 84 byte LINUX_REBOOT_CMD_POWER_OFF Binary Golf - 2018-12-16 - @netspooky
BITS 64
  org 0x100000000     ; Load address
;━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┓   ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
; CODE                ┃ HEXDUMP                                     ┃ ELF HEADER         ┃   ┃ CODE COMMENT                       ┃
;━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━┩   ┡━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┩
  db 0x7F, "ELF"      ; 00: 7f45 4c46 .... .... .... .... .... .... │ ELF Magic          │   │ PROTIP: Use this as a constant ;)  │
_start:               ;                                             │                    │   ├────────────────────────────────────┤
  mov edx, 0x4321fedc ; 04: .... .... badc fe21 43.. .... .... .... │ class,data,version │   │ Moving some magic values...        │
  mov esi, 0x28121969 ; 09: .... .... .... .... ..be 6919 1228 .... │ UNUSED             │   │ ...into specified registers        │
  jmp short reeb      ; 0e: .... .... .... .... .... .... .... eb3c │ UNUSED             │   │ Short jump down to @x4c            │
  dw 2                ; 10: 0200 .... .... .... .... .... .... .... │ e_type             │   │                                    │
  dw 0x3e             ; 12: .... 3e00 .... .... .... .... .... .... │ e_machine   ┏━━━━━━━━━━│┌ What Are We Executing? ──────────┐│
  dd 1                ; 14: .... .... 0100 0000 .... .... .... .... │ e_version   ┃ PROGRAM  ││ reboot() syscall with argument:  ││
  dd _start - $$      ; 18: .... .... .... .... 0400 0000 .... .... │ e_entry     ┃ HEADER   ││ LINUX_REBOOT_CMD_POWER_OFF       ││
phdr:                 ;                                             │             ┡━━━━━━━━━━││  """                             ││
  dd 1                ; 1c: .... .... .... .... .... .... 0100 0000 │ e_entry     │ p_type   ││  The message "Power down." is    ││
  dd phdr - $$        ; 20: 1c00 0000 .... .... .... .... .... .... │ e_phoff     │ p_flags  ││  printed, the system is stopped, ││
  dd 0                ; 24: .... .... 0000 0000 .... .... .... .... │ e_phoff     │ p_offset ││  and all power is removed from   ││
  dd 0                ; 28: .... .... .... .... 0000 0000 .... .... │ e_shoff     │ p_offset ││  the system, if possible.  If    ││
  dq $$               ; 2c: .... .... .... .... .... .... 0000 0000 │ e_shoff     │ p_vaddr  ││  not preceded by a sync(2), data ││
                      ; 30: 0100 0000 .... .... .... .... .... .... │ e_flags     │ p_vaddr  ││  will be lost.                   ││
  dw 0x40             ; 34: .... .... 4000 .... .... .... .... .... │ e_shsize    │ p_paddr  ││  """                             ││
  dw 0x38             ; 36: .... .... .... 3800 .... .... .... .... │ e_phentsize │ p_paddr  ││ For more info:                   ││
  dw 1                ; 38: .... .... .... .... 0100 .... .... .... │ e_phnum     │ p_paddr  ││     $ man 2 reboot               ││
  dw 2                ; 3a: .... .... .... .... .... 0200 .... .... │ e_shentsize │ p_paddr  │└──────────────────────────────────┘│
cya:                  ;                                             │             │          │                                    │
  mov al, 0xa9        ; 3c: .... .... .... .... .... .... b0a9 .... │ e_shnum     │ p_filesz │ Load reboot(2) syscall number      │
  syscall             ; 3e: .... .... .... .... .... .... .... 0f05 │ e_shstrndx  │ p_filesz │ Execute syscall                    │
  dd 0                ; 40: 0000 0000 .... .... .... .... .... .... └─────────────│ p_filesz │                                    │
  mov al, 0xa9        ; 44: .... .... b0a9 .... .... .... .... .... │             │ p_memsz  │ Keeping the values the same        │
  syscall             ; 46: .... .... .... 0f05 .... .... .... .... │             │ p_memsz  │ in p_memsz to keep loader happy    │
  dd  0               ; 48: .... .... .... .... 0000 0000 .... .... │             │ p_memsz  │                                    │
reeb:                 ; 4c: .... .... .... .... .... .... bfad dee1 │             │          │                                    │
  mov edi, 0xfee1dead ; 50: fe.. ....                               │             │ p_align  │ Load "LINUX_REBOOT_CMD_POWER_OFF"  │
  jmp short cya       ; 51: ..eb e9..                               │             │ p_align  │ Short jump e_shnum/p_filesz @0x3C  │
  nop                 ; 53: .... ..90                               │             │ p_align  │ Filler to keep file size 84 bytes  │
;─────────────────────┴─────────────────────────────────────────────┘             └──────────└────────────────────────────────────┘
; Build:
; nasm -f bin -o bye bye.nasm
;
; One Liner:
; base64 -d <<< f0VMRrrc/iFDvmkZEijrPAIAPgABAAAABAAAAAEAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAEAAOAABAAIAsKkPBQAAAACwqQ8FAAAAAL+t3uH+6+mQ > bye;chmod +x bye;sudo ./bye
;
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
;
; Syscall reference: http://man7.org/linux/man-pages/man2/reboot.2.html
;
; [ Full breakdown ]
; --- Elf Header 
; Offset  #  Value             Purpose
; 0-3     A  7f454c46          Magic number - 0x7F, then 'ELF' in ASCII
; 4       B  ba                1 = 32 bit, 2 = 64 bit
; 5       C  dc                1 = little endian, 2 = big endian
; 6       D  fe                ELF Version
; 7       E  21                OS ABI - usually 0 for System V
; 8-F     F  43be69191228eb3c  Unused/padding 
; 10-11   G  0200              1 = relocatable, 2 = executable, 3 = shared, 4 = core
; 12-13   H  3e00              Instruction set
; 14-17   I  01000000          ELF Version
; 18-1F   J  0400000001000000  Program entry position
; 20-27   K  1c00000000000000  Program header table position - This is actually in the middle of J.
; 28-2f   L  0000000000000000  Section header table position (Don't have one here so whatev)
; 30-33   M  01000000          Flags - architecture dependent
; 34-35   N  4000              Header size
; 36-37   O  3800              Size of an entry in the program header table
; 38-39   P  0100              Number of entries in the program header table
; 3A-3B   Q  0200              Size of an entry in the section header table
; 3C-3D   R  b0a9              Number of entries in the section header table [holds mov al, 0xa9 load syscall]
; 3E-3F   S  0f05              Index in section header table with the section name [holds syscall opcodes]
;
; --- Program Header
; OFFSET  #   Value            Purpose 
; 1C-1F   PA  01000000         Type of segment
;                                0 = null - ignore the entry
;                                1 = load - clear p_memsz bytes at p_vaddr to 0, then copy p_filesz bytes from p_offset to p_vaddr 
;                                2 = dynamic - requires dynamic linking
;                                3 = interp - contains a file path to an executable to use as an interpreter for the following segment
;                                4 = note section
; 20-23   PB  1c000000         Flags 
;                                1 = PROT_READ  readable
;                                2 = PROT_WRITE writable
;                                4 = PROT_EXEC  executable
;                                In this case the flags are 1c which is 00011100
;                                The ABI only pays attention to the lowest three bits, meaning this is marked "PROT_EXEC"
; 24-2B   PC 0000000000000000   The offset in the file that the data for this segment can be found (p_offset)
; 2C-33   PD 0000000001000000   Where you should start to put this segment in virtual memory (p_vaddr)
; 34-3B   PE 4000380001000200   Physical Address 
; 3C-43   PF b0a90f0500000000   Size of the segment in the file (p_filesz) | NOTE: Can store string here and p_memsz as long as they
; 44-4B   PG b0a90f0500000000   Size of the segment in memory (p_memsz)    | are equal and not over 0xffff - holds mov al, 0xa9 and syscall 
; 4C-43   PH bfaddee1feebe990   The required alignment for this section (must be a power of 2)  Well... supposedly, because you can write code here.
