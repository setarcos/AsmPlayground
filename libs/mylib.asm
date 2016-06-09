    .model small
    .code
; Display AL when CX==2
; Display AX when CX==4
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
end
