    .model small
    .stack 1024
    .code
start:
    mov ax, @code
    mov ds, ax
    mov ax, 0
    mov es, ax          ; set es to zero
    mov bx, 4 * 8       ; offset of INT8 vector
    mov ax, es:[bx]
    mov word ptr [oldirq], ax  ; save old vector
    mov ax, es:[bx + 2]
    mov word ptr [oldirq + 2], ax
    cli
    mov ax, offset irq  ; set new vector
    mov word ptr es:[bx], ax
    mov ax, seg irq
    mov word ptr es:[bx + 2], ax
    sti
    mov cx, 18
wait5s:
    cmp cs:count, cx
    jb wait5s
    lea dx, msg
    mov ah, 09h
    int 21h         ; display a message
    add cx, 18
    cmp cx, 91
    jb wait5s
    cli
    mov ax, word ptr oldirq     ; restore old vector
    mov word ptr es:[bx], ax
    mov ax, word ptr [oldirq + 2]
    mov word ptr es:[bx + 2], ax
    sti
    mov ax, 4c00h
    int 21h         ; return to dos

oldirq dd ?        ; old int8 vector
count dw 0
msg db "int 08 issued 18 times", 0ah, 0dh, '$'

irq proc far
    inc cs:count
    jmp cs:oldirq   ; jump to oldirq, which will 'iret' back
irq endp

end start
