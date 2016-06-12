; Show PCI configration space of pci-edu in qemu
    .model small
    .stack 1024

    .data
pciid     dd 11e81234h
noedu   db 'pci-edu not installed, use -device edu.', 0ah, 0dh, '$'
    .code
start:
    mov ax, @data
    mov ds, ax
    mov bx, 0     ; bus/dev/fun combined
lop:
    cmp bx, 3ffh
    jg not_found
    .386
    mov cx, 0
    call conf_in  ; read vendor id and device id
    cmp eax, pciid
    jz found
    mov cx, bx
    and cx, 7h
    cmp cx, 0
    jz test_class
    inc bx
    jmp lop
test_class:
    mov cx, 0ch  ; header type
    call conf_in
    test eax, 800000h
    jz @F        ; not a multi-function device
    add bx, 8
    jmp lop
@@:
    inc bx
    jmp lop
    mov cx, 0
found:
    call conf_in
    push cx
    mov cx, 4
    call disp_ax
    shr eax, 16
    mov cx, 4
    call disp_ax
    pop cx
    add cx, 4
    cmp cx, 3Fh
    jb found
    jmp mout
not_found:
    lea dx, noedu
    mov ah, 09h
    int 21h
mout:
    mov ax, 4c00h
    int 21h

conf_in proc near
    push dx
    mov ax, bx
    shl eax, 8
    or eax, 80000000h
    add ax, cx;
    mov dx, 0cf8h
    out dx, eax
    mov dx, 0cfch
    in eax, dx
    pop dx
    ret
conf_in endp

disp_ax proc near
    push dx
    push bx
    mov bx, ax ; Save AX to BX
    mov dx, cx ; Save CX to DX
@@: mov ax, bx ; Restore shifted version of AX
    push ax    ; Save AX to stack
    push cx
    mov cl, 4
    shr bx, cl ; Shift saved AX
    pop cx
    loop @b
    mov cx, dx ; Restore CX
@@: pop ax     ; Restore AX from stack
    call disp_al
    loop @b
    mov dl, ' '; Add a space
    mov ah, 2
    int 21h
    pop bx
    pop dx
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
    mov ah,02h
    int 21h
    pop bx
    pop dx
    ret
disp_al endp

end start
