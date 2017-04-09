    .model small
    .stack 1024
    .code
start:
    mov al, 10110110B
    out 43h, al ; 8253, channel 2, mode 3
    mov ax, 1190; 1.19MHz/1kHz = 1190
    out 42h, al
    mov al, ah
    out 42h, al
    in al, 61h  ; 8255A PB
    mov ah, al
    or al, 03h
    out 61h, al
    mov cx, 0
    mov bl, 100
@@: loop @B
    dec bl
    jnz @B
    mov al, ah ; restore 8255A PB
    out 61h, al
    mov ax, 4c00h
    int 21h

    end start
