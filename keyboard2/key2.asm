    .model small
    .stack 1024
    .code
start:
    mov ax, @code
    mov ds, ax
    in al, 21h
    or al, 02h    ; keyboard uses IRQ1
    out 21h, al
@@: in al, 64h
    test al, 01h
    jz @B
    in al, 60h
    mov buf, al
    push ax
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    call disp_al;
    pop ax
    call disp_al
    cmp buf, 1
    jnz @B
    in al, 21h
    and al, 11111101b
    out 21h, al
    mov ax, 4c00h
    int 21h         ; return to dos

buf db 0

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
