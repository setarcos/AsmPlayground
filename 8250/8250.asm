    .model small
    .stack 1024
    .data
Msg db "Hello, Serial!"
len equ $ - Msg
    .code
    BASE    equ 3f8h
    FCR     equ 02h
    LCR     equ 03h
    LSR     equ 05h
    Latch_L equ 00h
    Latch_H equ 01h
start:
    mov ax, @data
    mov ds, ax
    mov dx, BASE + LCR
    in al, dx
    or al, 80h
    out dx, al      ; Enable DLAB
    mov dx, BASE + Latch_L
    mov al, 1
    out dx, al
    inc dx
    xor al, al
    out dx, al      ; Baudrate 115200
    mov dx, BASE + LCR
    mov al, 03h     ; pattern: 8N1
    out dx, al      ; Disable DLAB
    mov cx, len
    lea bx, Msg
next:
    mov dx, BASE
    mov al, [bx]
    out dx, al
    mov dx, BASE
    inc bx
    mov dx, BASE + LSR
@@: in al, dx
    test al,20h     ; Empty Transmitter Holding Register
    jz @B
    loop next
input:
    mov dx, BASE + LSR
@@: in al, dx
    test al, 1      ; Data Ready
    jz @B
    mov dx, BASE
    in al, dx
    out dx, al      ; Echo
    mov dl, al
    mov ah, 02
    int 21h         ; display on VGA
    cmp al, '.'
    jnz input
    mov ax, 4c00h
    int 21h

end start
