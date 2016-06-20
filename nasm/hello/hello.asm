org 100h

start:
    mov ah, 09h
    mov dx, text
    int 21h
    mov ax, 4c00h
    int 21h
text db "Hello, world!",13,10,'$'

