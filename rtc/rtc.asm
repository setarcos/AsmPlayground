    .model small
    .stack 1024
    .code
in_cmos macro reg
    mov al, reg
    out 70h, al
    in al, 71h
endm

disp_c macro char
    mov dl, char
    mov ah, 02
    int 21h
endm

start:
    in_cmos 0ah
    test al, 80h
    jz start       ; update not in progress
@@: in_cmos 0ah
    test al, 80h
    jnz  @B        ; udpate in progress
    in_cmos 09h
    call disp_al
    disp_c '-'
    in_cmos 08h
    call disp_al
    disp_c '-'
    in_cmos 07h
    call disp_al
    disp_c ' '
    in_cmos 04h
    call disp_al
    disp_c ':'
    in_cmos 02h
    call disp_al
    disp_c ':'
    in_cmos 00h
    call disp_al
    mov ax, 4c00h
    int 21h

disp_al proc near
    push cx
    push ax
    mov cl, 4
    shr al, cl
    call low_al
    pop ax
    call low_al
    pop cx
    ret
disp_al endp

low_al proc near
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
low_al endp
end start
