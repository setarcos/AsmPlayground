    .model tiny
    .code 
    org 7c00h
    jmp start
         
mytext db "Hello World!"
  
start:
    xor ax, ax      ; DS
    mov ds, ax
    
    mov ax, 0b800h  ; ES
    mov es, ax
    
    cld
    xor di, di
    mov cx, 25 * 80
    mov ah, 0fh    ; forground: White, background: Black
    mov al, ' '    ; use space to clear screen
    rep stosw      ; clear all

    mov si, offset mytext                 
    mov di, (10 * 80 + 35) * 2
    mov cx, (start - mytext)
next:
    movsb          ; copy to frame buffer
    inc di         ; ignore the attribute part
    loop next
 
    jmp $
    org 7dfeh
        db 55h,0aah
end start
