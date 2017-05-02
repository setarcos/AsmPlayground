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
oldirq dd ?        ; old INT1A vector
msg db "TSR already installed!", 0ah, 0dh
msg1 db "Are you want to uninstall?(y/n)", '$'
msg2 db 0ah, 0dh, "TSR memory free failed!", 0ah, 0dh, '$'
msg3 db 0ah, 0dh, "TSR uninstalled!", 0ah, 0dh, '$'

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
    push ax
    lea dx, msg
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    cmp al, 'y'
    jnz keep
    pop ax
    mov es, ax  ; SEG of the resident code
    mov cx, word ptr es:[oldirq + 2] ; SEG of the old vector
    mov dx, word ptr es:[oldirq]     ; OFF of the old vector
    mov ax, 0
    push ds
    mov ds, ax
    cli
    mov [bx], dx
    mov [bx + 2], cx
    sti
    pop ds
    mov ax, es
    sub ax, 10h
    mov es, ax
    mov ah, 49h
    int 21h     ; free the program memory
    mov ax, es
    sub ax, 0Dh
    mov es, ax
    mov ah, 49h
    int 21h     ; free the enviorment memory
    jnc @F
    lea dx, msg2
    mov ah, 09h
    int 21h
    jmp keep
@@:
    lea dx, msg3
    mov ah, 09h
    int 21h
keep:
    mov ax, 4c00h
    int 21h         ; return to dos

end start
