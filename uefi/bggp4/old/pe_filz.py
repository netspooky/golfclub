import struct
import sys
import hashlib

# Last Working
# c4016c43.bin - 416 bytes - Removed .reloc section header alltogether and moved .text to 0x170
# 131972b8.bin - 464 bytes - Moved .text up further into the header at 0x1a0
# c93c8959.bin - 560 bytes - Removed dos stub and moved pe header up
# 6829707e.bin - 560 bytes - Resized the padding in PeSections, now .text is at 0x200
# ed663bef.bin - 1072 bytes - Truncated .text right after the last instruction, adjusted SizeOfRawData in section
# 40f2882a.bin - 1280 bytes - .reloc overlap with .text, no relocs
# afd07e12.bin - 1296 bytes - Reloc section size is 0x10 bytes now
# 9dded7ac.bin - 1536 bytes - Size of headers is 0x200 instead of 0x400
# 68f174ba.bin - 1792 bytes -
# cf407d30.bin - 2048 bytes -

peSectionSize = 0x28 # original is 0xb8 to line it up to 0x200, should be 0x58 to get .text to 0x1a0
textLocation = 0x170 # Use this to adjust where .text is

# dHex - Dump Hex
# inBytes = byte array to dump
# baseAddr = the base address
def dHex(inBytes,baseAddr=0):
    offs = 0
    while offs < len(inBytes):
        bHex = ""
        bAsc = ""
        bChunk = inBytes[offs:offs+16]
        for b in bChunk:
            bAsc += chr(b) if chr(b).isprintable() and b < 0x7f else '.'
            bHex += "{:02x} ".format(b)
        sp = " "*(48-len(bHex))
        print("{:08x}: {}{} {}".format(baseAddr + offs, bHex, sp, bAsc))
        offs = offs + 16

def writeBin(b,h):
    outfile = h + ".bin"
    f = open(outfile,'wb')
    f.write(b)
    f.close()
    print(outfile)

# Convenience functions for struct
def gu64(v64):
    return struct.pack('<Q', v64)

def gu32(v32):
    return struct.pack('<I', v32)

def gu16(v16):
    return struct.pack('<H', v16)

class DosHeader():
    def __init__(self):
        self.e_magic    = b"\x4d\x5a"
        self.e_cblp     = b"\x90\x00"
        self.e_cp       = b"\x03\x00"
        self.e_crlc     = b"\x00\x00"
        self.e_cparhdr  = b"\x04\x00"
        self.e_minalloc = b"\x00\x00"
        self.e_maxalloc = b"\xff\xff"
        self.e_ss       = b"\x00\x00"
        self.e_sp       = b"\xb8\x00" # 0x10
        self.e_csum     = b"\x00\x00" # 0x12
        self.e_ip       = b"\x00\x00" # 0x14
        self.e_cs       = b"\x00\x00" # 0x16
        self.e_lfarlc   = b"\x40\x00" # 0x18
        self.e_ovno     = b"\x00\x00" # 0x1A
        self.e_res      = b"\x00"*8   # 0x1C
        self.e_oemid    = b"\x00\x00" # 0x24
        self.e_oeminfo  = b"\x00\x00" # 0x26
        self.e_res2     = b"\x00"*20  # 0x28
        self.e_lfanew   = gu32(0x40) # 0x3C - Address of PE Header
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.e_magic
        outbuf += self.e_cblp
        outbuf += self.e_cp
        outbuf += self.e_crlc
        outbuf += self.e_cparhdr
        outbuf += self.e_minalloc
        outbuf += self.e_maxalloc
        outbuf += self.e_ss
        outbuf += self.e_sp
        outbuf += self.e_csum
        outbuf += self.e_ip
        outbuf += self.e_cs
        outbuf += self.e_lfarlc
        outbuf += self.e_ovno
        outbuf += self.e_res
        outbuf += self.e_oemid
        outbuf += self.e_oeminfo
        outbuf += self.e_res2
        outbuf += self.e_lfanew
        #outbuf += self.dos_stub
        return outbuf

class PeHeader():
    def __init__(self):
        self.Signature            = b"\x50\x45\x00\x00" # 0x80
        self.Machine              = gu16(0x8664) # 0x84
        self.NumberOfSections     = gu16(1) # 0x86 - CHANGED - OK
        self.TimeDateStamp        = gu32(0) # 0x88
        self.PointerToSymbolTable = gu32(0) # 0x8C - CHANGED - OK
        self.NumberOfSymbols      = gu32(0) # 0x90 - CHANGED - OK
        self.SizeOfOptionalHeader = gu16(0xf0) # 0x94 - This is used in calculating SectionHeaderOffset in BasePeCoff.c
        self.Characteristics      = gu16(0x0206) # 0x96
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.Signature
        outbuf += self.Machine
        outbuf += self.NumberOfSections
        outbuf += self.TimeDateStamp
        outbuf += self.PointerToSymbolTable
        outbuf += self.NumberOfSymbols
        outbuf += self.SizeOfOptionalHeader
        outbuf += self.Characteristics
        return outbuf

class OptionalHeader():
    def __init__(self):
        self.Magic                   = gu16(0x020b) # 0x98
        self.MajorLinkerVersion      = b"\x02" # 0x9A
        self.MinorLinkerVersion      = b"\x22" # 0x9B
        self.SizeOfCode              = gu32(0x100) #b"\x00\x01\x00\x00" # 0x9C - CHANGED
        self.SizeOfInitializedData   = gu32(0) # 0xA0 - CHANGED
        self.SizeOfUninitializedData = gu32(0) # 0xA4
        self.AddressOfEntryPoint     = gu32(0x3000) # 0xA8
        self.BaseOfCode              = gu32(0x3000) # 0xAC
        self.ImageBase               = gu64(0) # 0xB0
        self.SectionAlignment        = gu32(0x10) # 0xB8
        self.FileAlignment           = gu32(0x10) # 0xBC
        self.MajorOSVersion          = gu16(0) # 0xC0
        self.MinorOSVersion          = gu16(0) # 0xC2
        self.MajorImageVer           = gu16(0) # 0xC4
        self.MinorImageVer           = gu16(0) # 0xC6
        self.MajorSubsystemVer       = gu16(0) # 0xC8
        self.MinorSubsystemVer       = gu16(0) # 0xCA
        self.Reserved1               = gu32(0) # 0xCC
        self.SizeOfImage             = gu32(0xf000) #0xD0 - This must be larger than the section header offset (0x188 in the default case)
        self.SizeOfHeaders           = gu32(textLocation) #0xD4 - CHANGED - I made this textLocation but it can be changed if needed
        self.CheckSum                = gu32(0xcd12) #0xD8
        self.Subsystem               = gu16(0x0a) #0xDC
        self.DllCharacteristics      = gu16(0) #0xDE
        self.SizeOfStackReserve      = gu64(0) # 0xE0
        self.SizeOfStackCommit       = gu64(0) # 0xE8
        self.SizeOfHeapReserve       = gu64(0) # 0xF0
        self.SizeOfHeapCommit        = gu64(0) # 0xF8
        self.LoaderFlags             = gu32(0) # 0x100
        self.NumberOfRvaAndSizes     = gu32(0x10) # 0x104
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.Magic
        outbuf += self.MajorLinkerVersion
        outbuf += self.MinorLinkerVersion
        outbuf += self.SizeOfCode
        outbuf += self.SizeOfInitializedData
        outbuf += self.SizeOfUninitializedData
        outbuf += self.AddressOfEntryPoint
        outbuf += self.BaseOfCode
        outbuf += self.ImageBase
        outbuf += self.SectionAlignment
        outbuf += self.FileAlignment
        outbuf += self.MajorOSVersion
        outbuf += self.MinorOSVersion
        outbuf += self.MajorImageVer
        outbuf += self.MinorImageVer
        outbuf += self.MajorSubsystemVer
        outbuf += self.MinorSubsystemVer
        outbuf += self.Reserved1
        outbuf += self.SizeOfImage
        outbuf += self.SizeOfHeaders
        outbuf += self.CheckSum
        outbuf += self.Subsystem
        outbuf += self.DllCharacteristics
        outbuf += self.SizeOfStackReserve
        outbuf += self.SizeOfStackCommit
        outbuf += self.SizeOfHeapReserve
        outbuf += self.SizeOfHeapCommit
        outbuf += self.LoaderFlags
        outbuf += self.NumberOfRvaAndSizes
        return outbuf

class Directories():
    def __init__(self):
        # Can I make this smaller? I don't know if I need this, I can probably stop at basereloc
        self.e_export_addr       = gu32(0) # 0x108
        self.e_export_size       = gu32(0) # 0x10C
        self.e_import_addr       = gu32(0) # 0x110
        self.e_import_size       = gu32(0) # 0x114
        self.e_resource_addr     = gu32(0) # 0x118
        self.e_resource_size     = gu32(0) # 0x11C
        self.e_exception_addr    = gu32(0) # 0x120
        self.e_exception_size    = gu32(0) # 0x124
        self.e_security_addr     = gu32(0) # 0x128
        self.e_security_size     = gu32(0) # 0x12C
        self.e_basereloc_addr    = gu32(0) #b"\x00\x90\x00\x00" # 0x130 Only one we use -- Changed
        self.e_basereloc_size    = gu32(0) #b"\x0c\x00\x00\x00" # 0x134 -- Changed
        self.e_debug_addr        = gu32(0) # 0x138
        self.e_debug_size        = gu32(0) # 0x13C
        self.e_copyright_addr    = gu32(0) # 0x140
        self.e_copyright_size    = gu32(0) # 0x144
        self.e_globalptr_addr    = gu32(0) # 0x148
        self.e_globalptr_size    = gu32(0) # 0x14C
        self.e_tls_addr          = gu32(0) # 0x150
        self.e_tls_size          = gu32(0) # 0x154
        self.e_load_config_addr  = gu32(0) # 0x158
        self.e_load_config_size  = gu32(0) # 0x15C
        self.e_bound_import_addr = gu32(0) # 0x160
        self.e_bound_import_size = gu32(0) # 0x164
        self.e_iat_addr          = gu32(0) # 0x168
        self.e_iat_size          = gu32(0) # 0x16C
        self.e_delay_import_addr = gu32(0) # 0x170
        self.e_delay_import_size = gu32(0) # 0x174
        self.e_com_desc_addr     = gu32(0) # 0x178
        self.e_com_desc_size     = gu32(0) # 0x17C
        self.e_reserved_addr     = gu32(0) # 0x180
        self.e_reserved_size     = gu32(0) # 0x184
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.e_export_addr
        outbuf += self.e_export_size
        outbuf += self.e_import_addr
        outbuf += self.e_import_size
        outbuf += self.e_resource_addr
        outbuf += self.e_resource_size
        outbuf += self.e_exception_addr
        outbuf += self.e_exception_size
        outbuf += self.e_security_addr
        outbuf += self.e_security_size
        outbuf += self.e_basereloc_addr
        outbuf += self.e_basereloc_size
        outbuf += self.e_debug_addr
        outbuf += self.e_debug_size
        outbuf += self.e_copyright_addr
        outbuf += self.e_copyright_size
        outbuf += self.e_globalptr_addr
        outbuf += self.e_globalptr_size
        outbuf += self.e_tls_addr
        outbuf += self.e_tls_size
        outbuf += self.e_load_config_addr
        outbuf += self.e_load_config_size
        outbuf += self.e_bound_import_addr
        outbuf += self.e_bound_import_size
        outbuf += self.e_iat_addr
        outbuf += self.e_iat_size
        outbuf += self.e_delay_import_addr
        outbuf += self.e_delay_import_size
        outbuf += self.e_com_desc_addr
        outbuf += self.e_com_desc_size
        outbuf += self.e_reserved_addr
        outbuf += self.e_reserved_size
        return outbuf

class ImageSectionHeader():
    def __init__(self, name=b"NULLNULL", misc=0, va=0, sord=0, ptrd=0, ptrel=0, ptln=0, nrelo=0, nln=0, characteristics=0):
        self.Name = name + (b"\x00"*(8-len(name))) # +0x00
        self.Misc                 = gu32(misc) # +0x08
        self.VirtualAddress       = gu32(va) # +0x0C
        self.SizeOfRawData        = gu32(sord) # +0x10
        self.PointerToRawData     = gu32(ptrd) # +0x14
        self.PointerToRelocations = gu32(ptrel) # +0x18
        self.PointerToLineNumbers = gu32(ptln) # +0x1C
        self.NumberOfRelocations  = gu16(nrelo) # +0x20
        self.NumberOfLineNumbers  = gu16(nln) # +0x22
        self.Characteristics      = gu32(characteristics) # +0x24
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.Name
        outbuf += self.Misc
        outbuf += self.VirtualAddress
        outbuf += self.SizeOfRawData
        outbuf += self.PointerToRawData
        outbuf += self.PointerToRelocations
        outbuf += self.PointerToLineNumbers
        outbuf += self.NumberOfRelocations
        outbuf += self.NumberOfLineNumbers
        outbuf += self.Characteristics
        return outbuf

class PeSections():
    def __init__(self):
        # This should start at 0x188 and go until 0x400 when text starts
        self.SectionNames = [".text", ".reloc"]
        self.text    = ImageSectionHeader(name=b".text",    misc=0x30, va=0x3000, sord=0x30,  ptrd=textLocation, characteristics=0x60500020 )
        #self.reloc   = ImageSectionHeader(name=b".reloc",   misc=0xC,  va=0x9000, sord=0x10,  ptrd=textLocation, characteristics=0x42100040 )
        self.TotalSectionsSize = 0x28# one section - uncomment if you need to put .reloc back # *2 # Only using two sections rn
        self.raw = self.getRaw()
        self.len = len(self.raw)
    def getRaw(self):
        outbuf = b""
        outbuf += self.text.raw
        #outbuf += self.reloc.raw
        outbuf += b"\x00"*(peSectionSize-self.TotalSectionsSize)
        return outbuf
# It's confirmed to be the same up til 0x400
totalSize = 0
fullBuf = b""
dosHdr = DosHeader()
fullBuf += dosHdr.raw
print(f"{totalSize:04x}: DosHeader")
totalSize = totalSize + dosHdr.len
peHdr = PeHeader()
fullBuf += peHdr.raw
print(f"{totalSize:04x}: PeHeader")
totalSize = totalSize + peHdr.len
optHdr = OptionalHeader()
fullBuf += optHdr.raw
print(f"{totalSize:04x}: OptionalHeader")
totalSize = totalSize + optHdr.len

directoriez = Directories()
fullBuf += directoriez.raw
print(f"{totalSize:04x}: Directories")
totalSize = totalSize + directoriez.len

peSecz = PeSections()
fullBuf += peSecz.raw
print(f"{totalSize:04x}: PeSections")
totalSize = totalSize + peSectionSize

print(f"{totalSize:04x}: .text - Len is 0x30")
b = b""
b += fullBuf # Combine both!
# .text Attempt 4 - This works
b += b"\x48\xC7\xC0\x18\xE0\xBE\x07" # mov rax,0x7bee018
b += b"\x48\x8B\x40\x40" # mov rax, QWORD PTR [rax+0x40]
b += b"\x48\x89\xC1"     # mov rcx, rax
b += b"\x48\x8B\x40\x08" # mov rax, QWORD PTR [rax+0x8]
b += b"\x48\x89\xC7"     # mov rdi, rax
b += b"\x48\xC7\xC2\x34\x00\x0A\x00" # mov rdx,0xa0034
b += b"\x52"             # push rdx
b += b"\x48\x89\xE2"     # mov rdx,rsp
b += b"\xFF\xD7"         # Call RDI
b += b"\x58\xc3" # pop rax and ret
b += b"\xc3"          # ret
#b += b"\x00"*0xd0 # padding in .text

m = hashlib.sha256()
m.update(b)
shorthash = m.digest().hex()[0:8]
writeBin(b,shorthash)
print(f"# {shorthash}.bin - {len(b)} bytes")