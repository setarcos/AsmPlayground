    .model small
    .stack 1024
    .code
start:
    mov ax, @code
    mov ds, ax
    mov ax, 0
    mov es, ax          ; set es to zero
    mov bx, 4 * 9       ; offset of INT9 vector
    mov ax, es:[bx]
    mov word ptr [oldirq], ax  ; save old vector
    mov ax, es:[bx + 2]
    mov word ptr [oldirq + 2], ax
    cli
    mov ax, offset irq  ; set new vector
    mov word ptr es:[bx], ax
    mov ax, seg irq     ; segment of irq
    mov word ptr es:[bx + 2], ax
    sti
@@:
    mov al, buf
    cmp al, 0
    jz @B
    cmp al, 1
    jz exit
    push ax
    shr ax, 1
    shr ax, 1
    shr ax, 1
    shr ax, 1
    call disp_al;
    pop ax
    call disp_al
    mov buf, 0
    jmp @B
exit:
    cli
    mov ax, word ptr oldirq     ; restore old vector
    mov word ptr es:[bx], ax
    mov ax, word ptr [oldirq + 2]
    mov word ptr es:[bx + 2], ax
    sti
    mov ax, 4c00h
    int 21h         ; return to dos

oldirq dd ?        ; old int8 vector
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

irq proc far
    push ax
    in al, 60h
    mov buf, al
    in al, 61h
    out 61h, al     ; tell keyboard we've finished
    mov al, 20h
    out 20h, al
    pop ax
    iret
    ;jmp cs:oldirq
irq endp

end start
