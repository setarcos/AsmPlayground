    .model small
    .stack 128
    .data
save dw 25*80 dup(?)   ; Save buf
buf db "Hello, World!" ; String to display
len dw $-buf
    .code
start:
    mov ax, @data
    mov es, ax
    mov ax, 0b800h ; Video memory
    mov ds, ax
    lea di, save   ; save current video memory to buffer
    xor si, si     ; from begin
    mov cx, 25*80  ; to end
    rep movsw      ; start transfer
    push ds
    push es
    pop ds
    pop es         ; swap es,ds
    xor di, di
    mov cx, 25*80
    mov ah, 0fh    ; forground: White, background: Black
    mov al, ' '    ; use space to clear screen
    rep stosw      ; clear all
    mov cx, len    ; length of the string
    mov di, (10*80+35)*2 ; (35,10) of the screen
    lea si, buf    ; buffer address
next:
    movsb          ; copy to frame buffer
    inc di         ; ignore the attribute part
    loop next
    call hide_cursor
waitkey:
    mov ah, 1h
    int 16h
    jz waitkey     ; wait for user key stroke
    xor di, di     ; restore screen
    lea si, save
    mov cx, 25 * 80
    rep movsw
    call show_curosr
    mov ax, 4c00h  ; return to dos
    int 21h

hide_cursor proc near
	push ax
	push dx
	mov dx,03d4h   ; CRTC
	mov al,0ah     ; cursor-start VGA reg
	out dx,al
	inc dx
	in al,dx
	or al,0010000b ; cursor off
	out dx,al
	pop dx
	pop ax
    ret
hide_cursor endp

show_curosr proc near
	push ax
	push dx
	mov dx,003d4h      ; CRTC
	mov al,0ah         ; cursor-start VGA reg
	out dx,al
	inc dx
	in al,dx
	and al,11011111b   ; cursor on
	out dx,al
	pop dx
	pop ax
    ret
show_curosr endp
    end start
