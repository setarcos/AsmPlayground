; List PCI devices using IO
    .model small
    .stack 1024

    .data
header db 'BusNo   DevNo   FuncNo  VendorID  DeviceID', 0dh, 0ah, '*********************************************', 0dh, 0ah, '$'
space  db '      $'
bus    db ?        ;Bus NO.
func   db ?        ;Func NO.
dev    db ?        ;Dev NO.
index  dd ?
id     dd ?

    .code
start:
    mov ax, @data
    mov ds, ax
    mov bus, 0
    mov func, 0
    mov dev, 0
    mov dx,offset header
    mov ah,9
    int 21h        ; Display header
lop:
    mov al, dev
    .386
    shl al, 3
    or al, func
    mov ah, bus
    shl eax, 8
    or eax, 80000000h
    mov dx, 0cf8h
    out dx, eax
    mov index, eax
    mov dx, 0cfch
    in eax, dx
    cmp eax, 0ffffffffh
    jnz @F
    cmp func, 0
    jz cont1
    jmp cont
@@: mov id, eax
    mov al, bus
    mov cx, 2
    call disp_ax
    mov dx, offset space
    mov ah, 9
    int 21h
    mov al, dev
    mov cx, 2
    call disp_ax
    mov dx, offset space
    mov ah,9
    int 21h
    mov al, func
    mov cx, 2
    call disp_ax
    mov dx, offset space
    mov ah,9
    int 21h
    mov cx, 4
    mov eax, id
    call disp_ax
    mov dx, offset space
    mov ah, 9
    int 21h
    shr eax, 16
    mov cx,4
    call disp_ax
    mov ah,02
    mov dl, 0dh
    int 21h
    mov dl, 0ah
    int 21h
    mov cl, func
    cmp cl, 0
    jnz cont
    mov eax, index
    add ax, 0ch ; header type
    mov dx, 0cf8h
    out dx, eax
    mov dx, 0cfch
    in eax, dx
    test eax, 800000h
    jz cont1        ; not a multi-function device
cont:
    cmp func, 7
    je cont1
    inc func
    jmp lop
cont1:
    mov func, 0
    cmp dev, 31
    je cont2
    inc dev
    jmp lop
cont2:
    mov dev, 0
    cmp bus, 3
    je mout
    inc bus
    jmp lop
mout:
    mov ax, 4c00h
    int 21h

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
