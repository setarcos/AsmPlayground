    .model small
    .stack 1024
    .code

start:
    mov al, 01110110B
    out 43h, al ; 8253, channel 1, mode 3
    mov ax, 1190; 1.19MHz/1kHz = 1190
    out 41h, al
    mov al, ah
    out 41h, al
    mov cx, 0
    mov bl, 100
@@: mov al, 01000110B
    out 43h, al  ; 8253 lantch
    in al, 41h
    xchg al, ah
    in al, 41h
    xchg al, ah
    call disp_ax
    mov dl, ','
    mov ah, 2
    int 21h
    mov ah, 01
    int 16h
    jnz @F
    loop @B
    dec bl
    jnz @B
@@: mov ax, 4c00h
    int 21h

disp_ax proc near
    push cx
    mov cx, 3
@@: push ax
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    loop @B
    mov cx, 3
@@: call disp_al
    pop ax
    loop @B
    call disp_al
    pop cx
    ret
disp_ax endp

disp_al  proc near
    push dx
    push bx
    and al,0fh
    add al,90h ; Al is from 90h to 09Fh.
    daa        ; Al is from 90h to 99h (carry clear) or 00h to 06h (carry set).
    adc al,40h ; Al is from 0D0h to 0D9h or 41h to 46h.
    daa        ; Al is from 30h to 39h ("0" to "9") or 41h to 46h ("A" to "F").
    mov dl, al
    mov ah, 02h
    int 21h
    pop bx
    pop dx
    ret
disp_al endp

    end start
