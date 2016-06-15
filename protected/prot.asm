; Try to demonstrate entering protected mode
    .386p
; This code will be located at 0000:7c00
_TEXT16 segment para use16 public 'CODE'
start:
    xor ax, ax
    mov ss, ax      ; SS
    mov sp, 7c00h

    mov ax, 0b800h  ; ES
    mov es, ax

    cld
    xor di, di
    mov cx, 25 * 80
    mov ah, 0fh    ; forground: White, background: Black
    mov al, ' '    ; use space to clear screen
    rep stosw      ; clear all
    lgdt fword ptr [gdt_size + 7c00h]
    in al, 92h
    or al, 00000010b
    out 92h, al    ; open A20 gate

    cli
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    ;jmp dword 0008:[flush]
    db 66h
    db 0eah         ; Opcode for jmp
    dd offset flush
    dw 08h          ; Code segment seletor

gdt_size label fword
    dw 39
gdt_base    dd offset gdt+7c00h
    align 8
gdt dq 0    ; Null descriptor
    dd 7c0001ffh, 00409800h ; GDT[1], CS
    dd 8000ffffh, 0040920bh ; GDT[2], ES
    dd 7c0001ffh, 00409200h ; GDT[3], DS
    dd 00007a00h, 00409600h ; GDT[4], SS
    align 16
end16 equ  $
_TEXT16 ENDS

_TEXT32 segment para flat public 'CODE'
    assume ds:FLAT, es:FLAT
org end16
flush:
    mov cx, 10h
    mov es, ecx
    mov cx, 18h
    mov ds, ecx
    mov esi, offset msg
    mov edi, (10 * 80 + 25) * 2
    mov cx, (msg_end - msg)
    cld
next:
    movsb          ; copy to frame buffer
    inc di         ; ignore the attribute part
    loop next
    hlt

msg db "Hello, Protected World!"
msg_end db 0
org 1feh    ; Make sure last word is 0aa55h
    db 55h,0aah
_TEXT32 ENDS

end
