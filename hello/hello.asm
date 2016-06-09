; Sample program from JWasm distribution

    .model small
    .stack 1024

    .data

text db 13,10,"Hello, world!",13,10,'$'

    .code

start:
    mov ax, @data
    mov ds, ax
    mov ah, 09h
    mov dx, offset text
    int 21h
    mov ax, 4c00h
    int 21h

    end start
