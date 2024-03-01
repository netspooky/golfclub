[map all mybin.map]
BITS 64
;4444444444444444444444444444444444444444444444444444444444444444444444444444444
;4444444444444444444444444444444444444444444444444444444444444444444444444444444
;4444444444444444444444444444444444444444444444444444444444444444444444444444444
;┌        ┐┌────┐    ┌────────╴────┬────┌───────  ┌────────┐┌         ┌────────╴
;└────────┘└────────┘├───      ────┴────└────────┘└────────┘└────────┘├─── BGGP4
mzHdr: ; MZ Header ──┼─MZ─────────────────┐4444444444444444444444444444444444444
  dw "MZ"     ; 0x00 │ e_magic            │4444444444444444444444444444444444444
  dw 0x100    ; 0x02 │ e_cblp             │4444444444444444444444444444444444444
peHdr: ; PE Header ──┼──────────────────────PE───────────────────────┐┌┐┌┐┌─┐444
  dd "PE"     ; 0x04 │ e_cp, e_crlc       │ PE Signature             ││││││ │444
  dw 0x8664   ; 0x08 │ e_cparhdr          │ Machine (Intel 386)      └┘││││ │444
  dw 1        ; 0x0A │ e_minalloc         │ NumberOfSections           ││└┘ │444
; Header Code 1 ───────────────────────────────────────────────────────└┘──────┐
;                                                                              │
;  Here we are just setting up some pointers                                   │
;                                                                              │
;  Note that some register to register movs are using 32 bit form for space!!  │
;                                                                              │
;  We are overwriting the following MZ and PE header values:                   │
;                                                                              │
; ─────────────────────MZ───────────────────PE──────────────────────────────── │
;    dd 0     ; 0x0C │ e_maxalloc, e_ss   │ TimeDateStamp                      │
;    dd 0     ; 0x10 │ e_sp, e_csum       │ PointerToSymbolTable               │
;    dd 0     ; 0x14 │ e_ip, e_cs         │ NumberOfSymbols                    │
; ──────────────────────────────────────────────────────────────────────────── │
header1:      ; 0x0C ; Size: 12 bytes                                          │
  mov  eax, ecx      ;                                                         │
  mov  rdx, [rdx+EFI_SYSTEM_TABLE_BootServices] ;                              │
  mov  rax, [rax+EFI_SYSTEM_TABLE_ConOut_OutputString] ;                       │
  jmp header2 ;                                                                │
; ─────────────────────────────────────────────────────────────────────────────┘
  dw sH - oH  ; 0x18 │ e_lsarlc           │ SizeOfOptionalHeader            │444
  dw 0x0206   ; 0x1A │ e_ovno             │ Characteristics                 │444
oH: ; Optional Header ──────────────────────OPT─────────────────────────────┤444
  dw 0x20B    ; 0x1C │ e_res              │ Magic (PE64)                    │444
; Header Code 3 ───────────────────────────────────────────────────────────────┐
;                                                                              │
;  This chunk of code gets the address of HandleProtocol function into rax.    │
;                                                                              │
;  We are overwriting the following DOS and Optional header values:            │
;                                                                              │
; ─────────────────────MZ───────────────────OPT─────────────────────────────── │
;    dw 0     ; 0x1E │ e_res              │ Major/ MinorLinkerVersion          │
;    dd 0     ; 0x20 │ e_res              │ SizeOfCode                         │
;    dd 0     ; 0x24 │ e_oemid, e_oeminfo │ SizeOfInitializedData              │
;    dd 0     ; 0x28 │ e_res2             │ SizeOfUninitializedData            │
; ──────────────────────────────────────────────────────────────────────────── │
header3:      ; Size: 14 bytes                                                 │
  mov  rax, [rbp-EFI_SYSTEM_TABLE_BootServices_o] ; rax = BootServices         │
  mov  eax, [eax+EFI_BOOT_SERVICES_HandleProtocol] ;                           │
  nop         ;                                                                │
  jmp header4 ;                                                                │
; ─────────────────────────────────────────────────────────────────────────────┘
  dd 0xE4     ; 0x2C │ e_res2             │ AddressOfEntryPoint             │444
coolFile: ; This is a pointer to the file name "4". utf-16 string :P        │444
  dd 0x34     ; 0x30 │ e_res2             │ BaseOfCode                      │444
; NOTE: 0x34 could be something but it's kind of touchy.                    │444
; dq 0        ; 0x34 │ e_res2             │ ImageBase                       │444
createAttributes:    ;                                                      │444
  dq 0x5555555555555555 ;  Not using this anymore but it's fun.             │444
  dd 4        ; 0x3C │ e_lfanew           │ SectionAlignment                │444
  dd 4        ; 0x40 │                    │ FileAlignment                   │444
; Header Code 4 ───────────────────────────────────────────────────────────────┐
;                                                                              │
;  This chunk calls HandleProtocol and gets the Device handle.                 │
;                                                                              │
;  We are overwriting the following Optional header values:                    │
;                                                                              │
; ──────────────────────────────────────────OPT─────────────────────────────── │
;    dd 0     ; 0x44 │                    │ Major/Minor OS Version             │
;    dd 0     ; 0x48 │                    │ Major/Minor ImageVersion           │
;    dd 0     ; 0x4C │                    │ Major/Minor SubsystemVersion       │
;    dd 0     ; 0x50 │                    │ Win32VersionValue                  │
; ──────────────────────────────────────────────────────────────────────────── │
header4:      ; 0x44 │ Size: 16 bytes                                          │
  mov  rcx, [rbp-ImageHandle_o] ; rcx = Handle                                 │
  call rax    ; Call EFI_BOOT_SERVICES::HandleProtocol()                       │
              ;                                                                │
  mov  rcx, [rbp-LoadedImageProtocolInterface_o] ;                             │
  mov  rcx, [rcx+EFI_LOADED_IMAGE_PROTOCOL_DeviceHandle] ;                     │
  jmp header5 ;                                                                │
; ─────────────────────────────────────────────────────────────────────────────┘
  dd 0xf000   ; 0x54 │                    │ SizeOfImage                     │444
  dd cStart   ; 0x58 │                    │ SizeOfHeaders                   │444
; Header Code 2 ───────────────────────────────────────────────────────────────┐
;                                                                              │
;  Sets up the a string and prints it to ConOut, then starts setting up the    │
;  LoadedImageProtocol GUID.                                                   │
;                                                                              │
;  This one was tricky because Subsystem field needs to be 0xA. Otherwise      │
;  it throws a `Command Error Status: Unsupported` error.                      │
;                                                                              │
;  There's a utf-16 newline being pushed to the stack, so we can arrange it    │
;  carefully to line up with the value. This unlocks 44 contiguous bytes!      │
;                                                                              │
;  We are overwriting the following Optional header values:                    │
;                                                                              │
; ──────────────────────────────────────────OPT─────────────────────────────── │
;    dd 0     ; 0x5C │                    │ CheckSum                           │
;    dw 0xA   ; 0x60 │                    │ Subsystem                          │
;    dw 0     ; 0x62 │                    │ DllCharacteristics                 │
;    dq 0     ; 0x64 │                    │ SizeOfStackReserve                 │
;    dq 0     ; 0x6C │                    │ SizeOfStackCommit                  │
;    dq 0     ; 0x74 │                    │ SizeOfHeapReserve                  │
;    dq 0     ; 0x7c │                    │ SizeOfHeapCommit                   │
;    dd 0     ; 0x84 │                    │ LoaderFlags                        │
; ──────────────────────────────────────────────────────────────────────────── │
header2:      ; 0x5C │ Size: 44 bytes                                          │
  push rdx    ; [rbp+0x18] EFI_SYSTEM_TABLE::BootServices                      │
  mov  rdx, 0xa0034 ; rdx = String "4\n"                                       │
  push rdx          ; [rbp+0x20] String "4\n"                                  │
  mov  edx, esp     ; rdx = *String                                            │
  call rax ; Call SystemTable->ConOut->OutputString()                          │
  push rax           ;                                                         │
  mov  r8, rsp       ; r8 = *LoadedImageProtocolInterface                      │
  mov  rdx, 0x3b7269c9a0003f8e ;                                               │
  push rdx    ; [rbp-0x30] EFI_LOADED_IMAGE_PROTOCOL_GUID                      │
  mov  rdx, 0x11d295625b1b31a1  ;                                              │
  push rdx  ; [rbp-0x38] EFI_LOADED_IMAGE_PROTOCOL_GUID                        │
  mov  edx, esp  ; rdx = *Protocol = EFI_LOADED_IMAGE_PROTOCOL_GUID            │
  nop         ;                                                                │
  jmp header3 ;                                                                │
; ─────────────────────────────────────────────────────────────────────────────┘
; Header Code 0 ───────────────────────────────────────────────────────────────┐
;                                                                              │
;  This is here as a lil island to hop from code to header and back with.      │
;                                                                              │
;  Overwrites the last two bytes of LoaderFlags                                │
;                                                                              │
; ──────────────────────────────────────────────────────────────────────────── │
header0:      ;                                                                │
  jmp header1 ;                                                                │
; ─────────────────────────────────────────────────────────────────────────────┘
  dd 6        ; 0x88 │                    │ NumberOfRvaAndSizes             │444
iDirs: ; Image Directories - Need at least 6 ───────────────────────────────┤444
; Header Code 5 ───────────────────────────────────────────────────────────────┐
;                                                                              │
;  This is the final code chunk in the header. It saves some things and        │
;  starts setting up the next call to HandleProtocol.                          │
;                                                                              │
;  Only 4 of the 6 required Image Directory Entries can have junk data in      │
;  them. The SECURITY one throws a `Command Error Status: Unsupported` and     │
;  the BASERELOC one throws a `Load Error` when junk data is in them.          │
;                                                                              │
; We are overwriting the following Image Directory Entries:                    │
;                                                                              │
; ──────────────────────────────────────────────────────────────────────────── │
;    dq 0     ; 0x8C │ [IMAGE_DIRECTORY_ENTRY_EXPORT]  Cool Fact: A UEFI app   │
;    dq 0     ; 0x94 │ [IMAGE_DIRECTORY_ENTRY_IMPORT]   needs at least 6 of    │
;    dq 0     ; 0x9C │ [IMAGE_DIRECTORY_ENTRY_RESOURCE] these here img dirs.   │
;    dq 0     ; 0xA4 │ [IMAGE_DIRECTORY_ENTRY_EXCEPTION]                       │
; ──────────────────────────────────────────────────────────────────────────── │
header5:      ; 0x8C │ Size: 32 bytes                                          │
  push rcx    ; [rbp-0x40] EFI_LOADED_IMAGE_PROTOCOL::DeviceHandle             │
  mov  rdx, 0x300 ; The PE header is too unreliable for some reason...:))      │
  push rdx    ; [rbp-0x48] EFI_LOADED_IMAGE_PROTOCOL::ImageSize                │
  xor  r8, r8 ; r8 = SimpleFileSystemProtocolInterface                         │
  push r8     ; [rbp-0x50] SimpleFileSystemProtocolInterface                   │
  mov  r8, rsp ; r8 = *SimpleFileSystemProtocolInterface                       │
  mov  rax, [rbp-EFI_SYSTEM_TABLE_BootServices_o] ;                            │
  mov  rdx, 0x3b7269c9a000398e ;                                               │
  push rdx    ; [rbp-0x58] gEfiSimpleFileSystemProtocolGuid                    │
  jmp handleSimpleFileSystemProtocol ;                                         │
; ─────────────────────────────────────────────────────────────────────────────┘
  dq 0        ; 0xAC │ [IMAGE_DIRECTORY_ENTRY_SECURITY] <- This is checked  │444
  dq 0        ; 0xB4 │ [IMAGE_DIRECTORY_ENTRY_BASERELOC]                    │444
sH: ; Section Header @0xBC ─────────────────────────────────────────────────┤444
  db ".text",0,0,0 ; │ +0x00 Name                                           │444
  dd cEnd - cStart ; │ +0x08 Misc_VirtualSize                               │444
  dd 0xE4          ; │ +0x0C Virtual Address                                │444
  dd cEnd - cStart ; │ +0x10 SizeOfRawData                                  │444
  dd cStart        ; │ +0x14 PointerToRawData                               │444
  dd 0             ; │ +0x18 PointerToRelocations                           │444
  dd 0             ; │ +0x1C PointerToLinenumbers                      ┌┐   │444
  dw 0             ; │ +0x20 NumberOfRelocations                       ││┌┐ │444
  dw 0             ; │ +0x22 NumberOfLinenumbers                     ┌┐││││ │444
  dd 0x60500020    ; │ +0x24 Characteristics                         ││││││ │444
cStart: ; (.text) @0xE4 ─────────────────────────────────────────────┘└┘└┘└─┘444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
; 44444                                      44444444444444444444444444444444444
; 44444  420 Byte Self-Replicating UEFI App  44444444444444444444444444444444444
; 44444  Authors: netspooky, icequ33n        444444                          444
; 44444                                      444444            ┌Arg┬Reg──┐   444
; 4444444444444444444444444444444444444444444444444   UEFI     │  1│rcx  │   444
; 4444444444444444444444444444444444444444444444444            │  2│rdx  │   444
; 444                                           444  Calling   │  3│r8   │   444
; 444  Tested on QEMU with OVMF Ubuntu 22.04    444            │  4│r9   │   444
; 444                                           444 Convention │  5│stack│   444
; 444  Build: $ nasm -f bin uefi-golf.asm -o a  444            └───┴─────┘   444
; 444                                           444                          444
; 444  Run: Type "a" in UEFI shell.             44444444444444444444444444444444
; 444                                           44444444444444444444444444444444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
; 444444444444444444444444444444444444444444444444444444444444444444444444444444
;;; Stack Map ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These are offsets from rbp
ImageHandle_o                               equ 0x08
SystemTable_o                               equ 0x10
EFI_SYSTEM_TABLE_BootServices_o             equ 0x18
MessageOut_o                                equ 0x20
LoadedImageProtocolInterface_o              equ 0x28
EFI_LOADED_IMAGE_PROTOCOL_GUID1_o           equ 0x30
EFI_LOADED_IMAGE_PROTOCOL_GUID2_o           equ 0x38
EFI_LOADED_IMAGE_PROTOCOL_DeviceHandle_o    equ 0x40
ImageSize_o                                 equ 0x48
SimpleFileSystemProtocolInterface_o         equ 0x50
gEfiSimpleFileSystemProtocolGuid1_o         equ 0x58
gEfiSimpleFileSystemProtocolGuid2_o         equ 0x60
DeviceFSRoot_o                              equ 0x68
OriginalFileName_o                          equ 0x70
OriginalFileHandle_o                        equ 0x78
NewFileHandle_o                             equ 0x80
AllocatePoolBuffer_o                        equ 0xA0

;; Function Offsets
EFI_SYSTEM_TABLE_ConOut                     equ 0x40
EFI_SYSTEM_TABLE_ConOut_OutputString        equ 0x08
EFI_SYSTEM_TABLE_BootServices               equ 0x60

EFI_BOOT_SERVICES_AllocatePool              equ 0x40
EFI_BOOT_SERVICES_FreePool                  equ 0x48
EFI_BOOT_SERVICES_HandleProtocol            equ 0x98

EFI_LOADED_IMAGE_PROTOCOL_DeviceHandle      equ 0x18

EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_OpenVolume  equ 0x08

EFI_FILE_PROTOCOL_Open                      equ 0x08
EFI_FILE_PROTOCOL_Close                     equ 0x10
EFI_FILE_PROTOCOL_Read                      equ 0x20
EFI_FILE_PROTOCOL_Write                     equ 0x28

; Set up and grab BootServices
  mov  ebp, esp 
  push rcx ; [rbp+0x08] ImageHandle  
  push rdx ; [rbp+0x10] SystemTable 
  mov eax, edx ; rax = SystemTable
  mov rcx, [rax+EFI_SYSTEM_TABLE_ConOut] ; 4; rcx = *This  
  jmp header0

; The empty labels are for code in the header, presented in the correct order
print4: 
; https://uefi.org/specs/UEFI/2.10/12_Protocols_Console_Support.html#efi-simple-text-output-protocol-outputstring
; (EFIAPI *EFI_TEXT_STRING) (
;  IN EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL    *This, // rcx
;  IN CHAR16                             *String // rdx
;  );

handleLoadedImageProtocol:
; Calling so that we can get info about our current image using the EFI_LOADED_IMAGE_PROTOCOL
;   https://uefi.org/specs/UEFI/2.10/09_Protocols_EFI_Loaded_Image.html
;
; https://uefi.org/specs/UEFI/2.10/07_Services_Boot_Services.html#efi-boot-services-handleprotocol
;
; (EFIAPI *EFI_HANDLE_PROTOCOL) (
;    IN EFI_HANDLE                    Handle,     // rcx
;    IN EFI_GUID                      *Protocol,  // rdx
;    OUT VOID                         **Interface // r8
;    );

getDeviceHandle:
  ; This is just a cleanup function 

handleSimpleFileSystemProtocol:
; Calling this to get a file system interface
; https://uefi.org/specs/UEFI/2.10/07_Services_Boot_Services.html#efi-boot-services-handleprotocol
;
; (EFIAPI *EFI_HANDLE_PROTOCOL) (
;    IN EFI_HANDLE                    Handle,     // rcx
;    IN EFI_GUID                      *Protocol,  // rdx
;    OUT VOID                         **Interface // r8
;    );

  mov  rdx, 0x11d26459964e5b22 
  push rdx       ; [rbp-0x60] gEfiSimpleFileSystemProtocolGuid
  mov  edx, esp  ; rdx = *gEfiSimpleFileSystemProtocolGuid

  ; Note that rcx is already set from getDeviceHandle

  mov  rax, [rax+EFI_BOOT_SERVICES_HandleProtocol] 
  call rax  ; Call EFI_BOOT_SERVICES::HandleProtocol()

OpenVolume:
; https://wiki.osdev.org/Loading_files_under_UEFI
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-simple-file-system-protocol-openvolume
;
; (EFIAPI *EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_OPEN_VOLUME) (
;   IN EFI_SIMPLE_FILE_SYSTEM PROTOCOL                   *This, // rcx
;   OUT EFI_FILE_PROTOCOL                                **Root // rdx
;   );
; This is the EFI_SIMPLE_FILE_SYSTEM Interface
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-simple-file-system-protocol

; OPT(-3): Assuming that rax is 0
;  xor  rdx, rdx
;  push rdx       ; [rbp-0x68] Root
  push rax

  mov  edx, esp  ; rdx = *Root

  mov  rcx, [rbp-SimpleFileSystemProtocolInterface_o] ; rcx = SimpleFileSystemProtocolInterface 

  mov  eax, ecx
  mov  rax, [rax+EFI_SIMPLE_FILE_SYSTEM_PROTOCOL_OpenVolume]
  call rax ; Call EFI_SIMPLE_FILE_SYSTEM_PROTOCOL::OpenVolume()

OpenOriginalFile:
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-open
;
; (EFIAPI *EFI_FILE_OPEN) (
;   IN EFI_FILE_PROTOCOL                  *This, // rcx
;   OUT EFI_FILE_PROTOCOL                 **NewHandle, // rdx
;   IN CHAR16                             *FileName, // r8
;   IN UINT64                             OpenMode, // r9
;   IN UINT64                             Attributes // Stack
;   );
; This first call is different because it's not creating a file, so it doesn't need the Attributes arg

  mov  r9, 1        ; This is the mode

  mov  r8, 0x61005c ; "\a" - Our file name
  push r8           ; [rbp-0x70] CurrentFileName
  mov  r8, rsp      ; R8 = *CurrentFileName

; OPT(-3): Assuming that rax is 0, so using that for the constant
;  xor  rdx, rdx     ; rdx = 0
;  push rdx          ; [rbp-0x78] OriginalFileHandle
  push rax 

  mov  edx, esp     ; rdx = **NewFileHandle

  mov  rcx, [rbp-DeviceFSRoot_o] ; rcx = EFI_FILE_PROTOCOL::Root

  mov  eax, ecx
  mov  rax, [rax+EFI_FILE_PROTOCOL_Open] ; rax = EFI_FILE_PROTOCOL::Open
  call rax

OpenNewFile:
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-open
;
; (EFIAPI *EFI_FILE_OPEN) (
;   IN EFI_FILE_PROTOCOL                  *This, // rcx
;   OUT EFI_FILE_PROTOCOL                 **NewHandle, // rdx
;   IN CHAR16                             *FileName, // r8
;   IN UINT64                             OpenMode, // r9
;   IN UINT64                             Attributes // Stack
;   );

; OPT(-3) This is a fancy lil dumb trick that sets this value in r9. 
; In case of bug, uncomment the first line and comment out the next three.
  ;mov r9, 0x8000000000000003 ; r9 = OpenMode, with create and r/w
  push 7
  pop r9
  ror r9, 1 ; r9 = *OpenMode, with create and r/w ; OPT(-3)

  lea r8, [rel coolFile] ; r8 = *FileName

; OPT(-3): Assuming that rax is 0
;  xor rdx, rdx ;
;  push rdx     ; [rbp-0x80] NewFileHandle
  push rax

  mov rdx, rsp ; rdx = **NewFileHandle

  mov rcx, [rbp-DeviceFSRoot_o] ; rcx = Root

  ; Adding 0x20 bytes of 0 on the stack because this is the 5th argument and it needs this offset
  push rax  ; Create room for stack args
  push rax  ; Create room for stack args
  push rax  ; Create room for stack args
  push rax  ; Create room for stack args

  mov eax, ecx
  mov rax, [rax+EFI_FILE_PROTOCOL_Open]
  call rax     ; Call EFI_FILE_PROTOCOL::Open()

AllocatePool:
; https://uefi.org/specs/UEFI/2.10/07_Services_Boot_Services.html#efi-boot-services-allocatepool
; 
; (EFIAPI  *EFI_ALLOCATE_POOL) (
;    IN EFI_MEMORY_TYPE            PoolType, // rcx
;    IN UINTN                      Size, // rdx
;    OUT VOID                      **Buffer // r8
;    );

  mov  r8, rsp ; r8 = **Buffer 

  mov  rdx, [rbp-ImageSize_o] ; rdx = Size

; OPT(-1): Assuming rax is 0
  ;xor  rcx, rcx ; EFI_MEMORY_TYPE PoolType = EfiReservedMemoryType
  mov ecx, eax

  mov  rax, [rbp-EFI_SYSTEM_TABLE_BootServices_o]
  mov  rax, [rax+EFI_BOOT_SERVICES_AllocatePool] 
  call rax  ; Call EFI_BOOT_SERVICES::AllocatePool()

ReadOriginalFile:
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-read
; 
; (EFIAPI *EFI_FILE_READ) (
;   IN EFI_FILE_PROTOCOL           *This, // rcx 
;   IN OUT UINTN                   *BufferSize, // rdx
;   OUT VOID                       *Buffer // r8
;   );

; OPT(-4): rdx should contain this address already, but in case of bug, try swapping these lines.
  ;mov  r8,  [rbp-AllocatePoolBuffer_o] ; r8 = *Buffer
  mov r8, rdx ; r8 = *Buffer 

  lea  rdx, [rbp-ImageSize_o]          ; rdx = *BufferSize

  mov  rcx, [rbp-OriginalFileHandle_o] ; rcx = *This

  mov  eax, ecx
  mov  rax, [rax+EFI_FILE_PROTOCOL_Read]
  call rax  ; Call EFI_FILE_PROTOCOL::Read()

WriteNewFile:
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-write
; 
; (EFIAPI *EFI_FILE_WRITE) (
;   IN EFI_FILE_PROTOCOL              *This, // rcx
;   IN OUT UINTN                      *BufferSize, // rdx
;   IN VOID                           *Buffer // r8
;   );

; OPT(-4): r11 should contain this address already, but in case of bug, try swapping these lines.
  ;mov  r8,  [rbp-AllocatePoolBuffer_o] ; r8 = *Buffer
  mov r8, r11 ; r8 = *Buffer 

  lea  rdx, [rbp-ImageSize_o] ; rdx = *BufferSize

  mov  rcx, [rbp-NewFileHandle_o] ; rcx = *This

  mov  eax, ecx
  mov  rax, [rax+EFI_FILE_PROTOCOL_Write]
  call rax  ; Call EFI_FILE_PROTOCOL::Write()

CloseNewFile:
; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-close
; 
; (EFIAPI *EFI_FILE_CLOSE) (
;   IN EFI_FILE_PROTOCOL                     *This // rcx
;   );

  mov  rcx, [rbp-NewFileHandle_o]

  mov  eax, ecx
  mov  rax, [rax+EFI_FILE_PROTOCOL_Close]
  call rax ; Call EFI_FILE_PROTOCOL::Close()

;CloseOriginalFile:
;; https://uefi.org/specs/UEFI/2.10/13_Protocols_Media_Access.html#efi-file-protocol-close
;; 
;; (EFIAPI *EFI_FILE_CLOSE) (
;;   IN EFI_FILE_PROTOCOL                     *This // rcx
;;   );
;
;  mov  rcx, [rbp-OriginalFileHandle_o]
;
;  mov  eax, ecx
;  mov  rax, [rax+EFI_FILE_PROTOCOL_Close] 
;  call rax ; Call EFI_FILE_PROTOCOL::Close()

;FreePool:
;; https://uefi.org/specs/UEFI/2.9_A/07_Services_Boot_Services.html#efi-boot-services-freepool
;; 
;; (EFIAPI *EFI_FREE_POOL) (
;;    IN VOID           *Buffer // rcx
;;    );
;
;  mov  rcx, [rbp-AllocatePoolBuffer_o]
;
;  mov  rax, [rbp-EFI_SYSTEM_TABLE_BootServices_o]
;  mov  rax, [rax-EFI_BOOT_SERVICES_FreePool]
;  call rax ; Call EFI_BOOT_SERVICES::FreePool()

bail:
  add rsp, 0xa0
  ret

cEnd: