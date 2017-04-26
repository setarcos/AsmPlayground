    .model small
    .386
    .stack 1024
    .code
irq proc far
    cmp ax, 0b102h
    jnz pass_on
    push eax
    push dx
    mov eax, 80040000h   ; 4.0.0
    mov dx, 0cf8h
    out dx, eax
    mov dx, 0cfch
    in eax, dx
    pop dx
    cmp ax, dx
    push dx
    jnz no_found
    shr eax, 16
    cmp ax, cx
    jnz no_found
    mov bx, 400h
    clc
    pop dx
    pop eax
    mov ah, 0
    iret
no_found:
    pop dx
    pop eax
pass_on:
    jmp cs:oldirq   ; jump to oldirq, which will 'iret' back
irq endp
oldirq dd ?        ; old int8 vector
msg db "TSR already installed!", 0ah, 0dh, '$'

start:
    mov ax, @code
    mov ds, ax
    mov ax, 0
    mov es, ax          ; set es to zero
    mov bx, 4 * 1Ah     ; offset of INT1A vector
    mov ax, es:[bx + 2]
    test ah, 80h
    jz ex
    mov word ptr [oldirq + 2], ax  ; save old vector
    mov ax, es:[bx]
    mov word ptr [oldirq], ax
    cli
    mov ax, offset irq  ; set new vector
    mov word ptr es:[bx], ax
    mov ax, seg irq
    mov word ptr es:[bx + 2], ax
    sti
    lea dx, msg;
    mov cl, 4
    shr dx, cl
    add dx, 11h ; add 1 for remainder and 10 for PSP 
    mov ax, 3100h
    int 21h
ex:
    lea dx, msg
    mov ah, 09h
    int 21h
    mov ax, 4c00h
    int 21h         ; return to dos

end start
