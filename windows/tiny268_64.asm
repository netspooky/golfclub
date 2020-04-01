BITS 32
;--- Smallest possible Win10 binary that execs calc.exe --------------------\\--
;
; Compile:
;   nasm -f bin -o tiny268_64.exe tiny268_64.asm
; Notice: You might get an error like "Cannot be started 0xc000000005",
;         this is fine, just run it again.
; Versions:
;   Size: 268 bytes (SHA1) 60e2c89d391052cc00145d277883e7feb6b67dd0 
;   Size: 304 bytes (SHA1) bb59448a94acee171ea574e3a50dd6a2b75f4965 
;
; Breakdown of Sections - Listed in comments of the header 0x00:0x7C
;
;                     MC-- MD-- ME-- MF-- MG-- MH--
;           MA-- MB-- PA------- PB-- PC-- PD-------
; 00000000: 4d5a 0000 5045 0000 4c01 0000 31f6 83ec  MZ..PE..L...1...
;           MI-- MJ-- MK-- ML-- MM-- MN-- MO-------
;           PE------- PF------- PG-- PH-- OA-- OBOC
; 00000010: 1856 6a63 9090 eb06 6000 0301 0b01 6668  .Vjc....`.....fh
;           MO------- MP-- MQ-- MR-----------------
;           OD------- OE------- OF------- OG-------
; 00000020: 7865 6857 696e 4589 65fc eb22 7c00 0000  xehWinE.e.."|...
;           MR--------------------------- MS-------
;           OH------- OI------- OJ------- OK-------
; 00000030: 0000 0000 0000 0000 0000 4000 0400 0000  ..........@.....
;           OL------- OM-- ON-- OO-- OP-- OQ-- OR--
; 00000040: 0400 0000 8b5b 0c8b 5b14 eb10 0500 648b  .....[..[.....d.
;           OS------- OT------- OU------- OV-------
; 00000050: 5e30 ebf0 8000 0000 7c00 0000 8b1b eb10  ^0......|.......
;           OW-- OX-- OY------- OZ------- O1-------
; 00000060: 0200 0004 0000 1000 0010 0000 0000 1000  ................
;           O2------- O3------- O4------- CK-------
; 00000070: 8b1b 8b5b 10eb 07c3 0000 0000 eb8e 895d  ...[...........]
; 00000080: f88b 433c 01d8 8b40 7801 d88b 4824 01d9  ..C<...@x...H$..
; 00000090: 894d f48b 7820 01df 897d f08b 501c 01da  .M..x ...}..P...
; 000000a0: 8955 ec8b 5814 31c0 8b55 f88b 7df0 8b75  .U..X.1..U..}..u
; 000000b0: fc31 c9fc 8b3c 8701 d766 83c1 08f3 a674  .1...<...f.....t
; 000000c0: 0a40 39d8 72e5 83c4 26eb ac8b 4df4 89d3  .@9.r...&...M...
; 000000d0: 8b55 ec66 8b04 418b 0482 01d8 31d2 5268  .U.f..A.....1.Rh
; 000000e0: 2e65 7865 6863 616c 6368 6d33 325c 6879  .exehcalchm32\hy
; 000000f0: 7374 6568 7773 5c53 6869 6e64 6f68 433a  stehws\ShindohC:
; 00000100: 5c57 89e6 6a0a 56ff d083 c446            \W..j.V....F
; 
; Places code could be executed ------------------------------------------------
; Range       Len  Note
; 0x0C:0x18    12  jump0
; 0x1E:0x2C    14  jump1
; 0x44:0x4C     8  jump3
; 0x4E:0x54     6  jump2
; 0x5C:0x60     4  jump4 
; 0x70:0x78     8  jump5 + endy
;--- Start of MZ Header --------------------------------------------------------
mzhdr:
  dw "MZ"       ; 0x00 ; [MA] e_magic
  dw 0x100      ; 0x02 ; [MB] e_cblp This value will bypass TinyPE detections!
;--- Start of PE Header --------------------------------------------------------
pesig:
  dd "PE"       ; 0x04 ; [MC] e_cp [MD] e_crlc [PA] PE Signature
pehdr:
  dw 0x014C     ; 0x08 ; [ME] e_cparhdr [PB] Machine (Intel 386)
  dw 0          ; 0x0A ; [MF] e_minalloc [PC] NumberOfSections (0 haha)
jump0: ; WinExec Setup Part 1 --------------------------------------------------
  xor  esi,esi  ; 0x0C ; 31f6   ; Clear ESI [MG] e_maxalloc [PD] TimeDateStamp 
  sub  esp,0x18 ; 0x0E ; 83ec18 ; Make room for our bullshit [MH] e_ss [MI] e_sp
  push esi      ; 0x11 ; 56     ; Null   [PE] PointerToSymbolTable
  push 0x63     ; 0x12 ; 6a63   ; "c"    [MJ] e_csum 
  nop           ; 0x14 ; 90     ; spacer [MK] e_ip [PF] NumberOfSymbols 
  nop           ; 0x15 ; 90     ; spacer 
  jmp jump1     ; 0x16 ; eb06   ; [ML] e_cs
  dw 0x60       ; 0x18 ; [MM] e_lsarlc [PG] SizeOfOptionalHeader
  dw 0x103      ; 0x1A ; [MN] e_ovno [PH] Characteristics
;--- Start of Optional Header --------------------------------------------------
  dw 0x10B      ; 0x1C ; [MO] e_res [OA] Magic (PE32)
jump1: ; WinExec Setup Part 2 --------------------------------------------------
  push word 0x6578 ;0x1E; 66687865   ; "ex" [OB] MajorLinkerVersion 
                                     ; [OC] MinorLinkerVersion [OD] SizeOfCode
  push 0x456e6957  ;0x22; 6857696e45 ; "EniW"
                        ; [MP] e_oemid [MQ] e_oeminfo [OE] SizeOfInitializedData
  mov dword [ebp-4], esp ;0x27; 8965fc; Save our stack pointer addr for later 
                                      ; [MR] e_res2 [OF] SizeOfUninitializedData
  jmp jump2     ; 0x2A ; eb22 
  dd 0x7C       ; 0x2C ; [OG] AddressOfEntryPoint (Could make a label pointer)
  dd 0          ; 0x30 ; [OH] BaseOfCode
  dd 0          ; 0x34 ; [OI] BaseOfData
  dd 0x400000   ; 0x38 ; [OJ] ImageBase
  dd 4          ; 0x3C ; [MS] e_lfanew [OK] SectionAlignment
  dd 4          ; 0x40 ; [OL] FileAlignment
jump3: ; PEB Parse Part 2 ------------------------------------------------------
  mov  ebx, [ebx+0xc]  ; 0x44 ; 8b5b0c ; Get addr of PEB_LDR_DATA
                              ; [OM] MajorOperatingSystemVersion
                              ; [ON] MinorOperatingSystemVersion
  mov  ebx, [ebx+0x14] ; 0x47 ; 8b5b14 ; InMemoryOrderModuleList first entry
                              ; [OO] MajorImageVersion
  jmp  jump4           ; 0x4A ; eb10
                              ; [OP] MinorImageVersion
  dw 5          ; 0x4C ; [OQ] MajorSubsystemVersion
jump2: ; PEB Parser Part 1 -----------------------------------------------------
  mov  ebx, [fs:0x30+esi] ; 0x4E ; 648b5e30 ; Get PEB addr, FS holds TEB address
                                 ; [OR] MinorSubsystemVersion
                                 ; [OS] Win32VersionValue
  jmp jump3     ; 0x52 ; ebf0
  dd 0x80       ; 0x54 ; [OT] SizeOfImage
  dd 0x7C       ; 0x58 ; [OU] SizeOfHeaders
jump4: ; PEB Parser Part 3 -----------------------------------------------------
  mov  ebx, [ebx] ; 0x5C ; 8b1b ; Get address of ntdll.dll entry [OV] CheckSum
  jmp jump5       ; 0x5E ; eb10 
  dw 2          ; 0x60 ; [OW] Subsystem (Win32 GUI)
  dw 0x400      ; 0x62 ; [OX] DllCharacteristics   
  dd 0x100000   ; 0x64 ; [OY] SizeOfStackReserve   
  dd 0x1000     ; 0x68 ; [OZ] SizeOfStackCommit    
  dd 0x100000   ; 0x6C ; [O1] SizeOfHeapReserve    
jump5: ; PEB Parser Part 4 -----------------------------------------------------
  mov  ebx, [ebx]      ; 0x70 ; 8b1b   ; Get address of kernel32.dll list entry
                                       ; [O2] SizeOfHeapCommit 
  mov  ebx, [ebx+0x10] ; 0x72 ; 8b5b10 ; Get kernel32.dll base address 
                                       ; [O3] LoaderFlags 
  jmp jump6            ; 0x75 ; eb07
endy:
  ret                  ; 0x77 ; c3  ; Used to end the program    
  dd 0          ; 0x78 ; [O4] NumberOfRvaAndSizes  ; Note - this is touchy 
codesec:        ; 0x7C - Start of code -----------------------------------------
                       ; MachineCode ; Description 
  jmp jump0            ; eb8e        ; Jump back to header to begin execution
jump6:
;--- Grab kernel32.dll base addr -----------------------------------------------
; This piece of code grabs the Thread Environment Block structure's address from
; the FS segment register to locate the Process Environment Block structure 
; stored inside.
; Then it grabs the pointer to the PEB_LDR_DATA structure so it can grab the 
; InMemoryOrderModuleList, which tells us about DLLs in memory.
; Then it grabs the ntdll.dll entry in this list which helps us find the next
; entry, kernel32.dll. The base address of kernel32.dll is stored at 0x10 in 
; the entry.
; 
; [WORKFLOW]
; TEB
; @0x30 PEB
;   --> 0x0C PEB_LDR_DATA
;        --> 0x14 InMemoryOrderModuleList
;             --> 0x00 ntdll.dll entry address
;                  --> 0x00 kernel32.dll list entry address
;                       --> 0x10 kernel32.dll base address !!
; Note that most of this is done in the header, see jump2 - jump5
; PEB Parser Part 5 ------------------------------------------------------------
  mov  [ebp-0x8], ebx     ; 895df8   ; kernel32.dll base address
;--- Finding WinExec address
; This section weaves it's way through the headers of kernel32.dll. 
; Based on a non-fucky PE like this one, we can sort of rely on certain things
; being where we expect them.
; First, the Relative Virtual address of the PE signature is loaded from ebx.
; EAX then becomes the address that we're calculating from.
; 
; The addresses of our structures are calculated using the base address of the 
; PE signature in EAX + it's offset within that structure, and then added to the
; base address stored in EBX. These are then moved to the stack.
; 
  mov  eax,dword [ebx+0x3c] ; 8b433c  ; RVA of PE signature
  add  eax,ebx              ; 01d8    ; PE sig addr = base addr + RVA of PE sig
  mov  eax,dword [eax+0x78] ; 8b4078  ; RVA of Export Table
  add  eax,ebx              ; 01d8    ; Address of Export Table

  mov  ecx,dword [eax+0x24] ; 8b4824  ; RVA of Ordinal Table
  add  ecx,ebx              ; 01d9    ; Address of Ordinal Table
  mov  dword [ebp-0xc],ecx  ; 894df4  ; Put on the stack

  mov  edi,dword [eax+0x20] ; 8b7820  ; RVA of Name Pointer Table
  add  edi,ebx              ; 01df    ; Address of Name Pointer Table
  mov  dword [ebp-0x10],edi ; 897df0  ; Put on the stack

  mov  edx,dword [eax+0x1c] ; 8b501c  ; RVA of Address Table
  add  edx,ebx              ; 01da    ; Address of Address Table
  mov  dword [ebp-0x14],edx ; 8955ec  ; Put on the stack

  mov  ebx,dword [eax+0x14] ; 8b5814  ; Number of exported functions
;--- Using the Name Pointer Table
; This part loops through the Name Pointer Table and compares entries to what
; we're looking for: "WinExec".
; The number of entries is counted using EAX, and once the WinExec entry is 
; found, the entry in the ordinal table is found using the count. See 'locate'
  xor  eax,eax              ; 31c0    ; EAX will be our entry counter
  mov  edx, dword [ebp - 8] ; 8b55f8  ; EDX = kernel32.dll base address
loopy:
  mov  edi,dword [ebp-0x10] ; 8b7df0  ; edi = Address of Name Pointer Table
  mov  esi,dword [ebp-4]    ; 8b75fc  ; esi = "WinExec\x00"
  xor  ecx,ecx              ; 31c9    ; ECX = 0
  cld                       ; fc      ; Clear direction flag 
                                      ; Strings now go left->right
  mov  edi,dword [edi+eax*4] ; 8b3c87 ; Name Pointer Table entries are 4 bytes,
                                      ; edi (NPT addr) + eax (num entries) * 4
  add  edi,edx             ; 01d7     ; EDI = NPT addr + kernel32.ddl base addr
  add  cx,0x8              ; 6683c108 ; Length of "WinExec"
  repe cmpsb               ; f3a6     ; Compare the first 8 bytes in esi and edi
  jz locate                ; 740a     ; Jump if there's a match.

  inc  eax                 ; 40       ; Increment entry counter
  cmp  eax,ebx             ; 39d8     ; Check if the last function was reached
  jb   loopy               ; 72e5     ; If not the last one, continue
  add  esp,0x26            ; 83c426   ; Move stack away from our mess
  jmp  endy                ; eb41     ; If nothing found, return
;--- Executing our function
; Once we're here, we know the position of WinExec within the ordinal table
; of kernel32.dll, so now all that's left is to call the function.
; We use all of our saved addresses on the stack for this.
locate:
  mov  ecx, [ebp-0xc]       ; 8b4df4  ; ECX = Address of Ordinal Table
  mov  ebx, edx             ; 89d3    ; EBX = kernel32.dll base address
  mov  edx, [ebp-0x14]      ; 8b55ec  ; EDX = Address of Address Table
  mov  ax, [ecx+eax*2]      ; 668b0441; AX  = ordinal addr + (ordinal num * 2)
  mov  eax, [edx+eax*4]     ; 8b0482  ; EAX = Addr table addr + (ordinal * 4)
  add  eax,ebx              ; 01d8    ; EAX = WinExec Addr = 
                            ; = kernel32.dll base address + RVA of WinExec
  xor  edx,edx              ; 31d2       ; We need a 0...
  push edx                  ; 52         ; ...for the end of our string
  push 0x6578652e           ; 682e657865 ;
  push 0x636c6163           ; 6863616c63 ;
  push 0x5c32336d           ; 686d33325c ;
  push 0x65747379           ; 6879737465 ;
  push 0x535c7377           ; 6877735c53 ;
  push 0x6f646e69           ; 68696e646f ;
  push 0x575c3a43           ; 68433a5c57 ;
  mov  esi,esp              ; 89e6       ; ESI="C:\Windows\System32\calc.exe"
  push 0xa                  ; 6a0a       ; window state SW_SHOWDEFAULT
  push esi                  ; 56         ; "C:\Windows\System32\calc.exe"
  call eax                  ; ffd0       ; WinExec
  add  esp,0x46             ; 83c446     ; Clear the stack
