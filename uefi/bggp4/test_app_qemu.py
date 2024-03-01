import socket
import time
import re
import subprocess

HOST = "127.0.0.1" 
PORT = 55555 

cmd_qemu = [ '/usr/bin/qemu-system-x86_64',
             '-drive','if=pflash,format=raw,file=./OVMF.fd',
             '-drive','format=raw,file=fat:rw:./root',
             '-net','none',
             '-nographic',
             '-monitor', 'tcp:127.0.0.1:55555,server,nowait',
             '-serial', 'file:./log.txt'
           ]

def escape_ansi(line):
    ansi_escape =re.compile(r'(\x9B|\x1B\[)[0-?]*[ -\/]*[@-~]')
    return ansi_escape.sub('', line)

def runCompare():
  # This compares the file a with 4 after creation
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        s.sendall(b"sendkey ret\r\n")
        time.sleep(0.3)
        s.sendall(b"sendkey a\r\n")
        s.sendall(b"sendkey ret\r\n")
        time.sleep(0.3)
        s.sendall(b"sendkey c\r\n")
        s.sendall(b"sendkey o\r\n")
        s.sendall(b"sendkey m\r\n")
        s.sendall(b"sendkey p\r\n")
        s.sendall(b"sendkey spc\r\n")
        s.sendall(b"sendkey a\r\n")
        s.sendall(b"sendkey spc\r\n")
        s.sendall(b"sendkey 4\r\n")
        s.sendall(b"sendkey ret\r\n")
        time.sleep(0.3)
        s.sendall(b"quit\r\n")
        time.sleep(0.3)

def justRun():
  # This one just tests whether or not it actually runs
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        s.sendall(b"sendkey ret\r\n")
        time.sleep(0.3)
        s.sendall(b"sendkey a\r\n")
        s.sendall(b"sendkey ret\r\n")
        time.sleep(0.5) # for whatever reason if this doesn't wait long enough it doesn't finish
        s.sendall(b"quit\r\n")
        time.sleep(0.3)

def checkLog():
  # could put something in here that hashes the output so we don't even have to read
    skiplines = 15 # number of lines I don't care about
    linenum = 0
    with open("./log.txt") as f:
        loglinez = f.readlines()
        for l in loglinez:
            linenum = linenum + 1
            cleaned = escape_ansi(l)
            if linenum > skiplines:
                print(cleaned, end="")

if __name__ == "__main__":
    print("[+] Starting QEMU")
    p = subprocess.Popen(cmd_qemu)
    time.sleep(3.5)
    print("[+] Sending HMP commands")
    runCompare()
    #justRun()
    print("[+] Reading output")
    checkLog()

