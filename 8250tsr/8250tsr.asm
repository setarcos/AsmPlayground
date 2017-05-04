    .model small
    .386
    .stack 1024
    .code
    BASE    equ 3f8h
    IER     equ  01h
    IIR     equ  02h
    LCR     equ  03h
    MCR     equ  04h
    LSR     equ  05h
    MSR     equ  06h
irq0c proc far
    push eax
    push bx
    push cx
    push dx
    push es
    push ds
    mov ax, cs
    mov ds, ax
    mov dx, BASE + IIR
    in al, dx
    test al, 04h        ; data ready?
    jnz rxrd
    test al, 02h        ; about to send next byte
    jnz txrd
    jmp eoi
txrd:
    cmp txptr, 0        ; tx interrupt fires upon program start
    jz eoi              ; don't know why, just ignore it
    mov bx, txptr
    cmp byte ptr [bx], 0
    jz eoi
    mov dx, BASE
    mov al, [bx]
    out dx, al
    inc txptr
    jmp eoi
rxrd:                   ; RX ready
    mov ax, 0b800h      ; video memory
    mov es, ax
    mov dx, BASE
    in al, dx           ; read the received data
    cmp rxptr, 40
    jl @F
    mov rxptr, 0
@@: lea bx, rxbuf
    add bx, rxptr
    mov ds:[bx], al     ; save it to buf
    inc rxptr
    mov cx, 0
@@: mov bx, offset rxbuf
    add bx, cx
    mov al, ds:[bx]
@1: mov bx, cx
    add bx, cx
    add bx, 40
    cmp al, 13
    jnz @2
    mov rxptr, 0        ; carry return
    mov al, ' '         ; don't show CR
@2: mov es:[bx], al     ; put it on screen
    mov byte ptr es:[bx + 1], 15h ; bg: blue, fg: magenta
    inc cx
    cmp cx, rxptr
    jl @B
    mov al, ' '         ; fill the rest with spaces
    cmp cx, 40
    jl @1
    cmp rxptr, 0        ; CR received (further check later)
    jnz eoi
    lea bx, rxbuf
    mov al, ds:[bx + 4]
    cmp al, 13          ; message length is 4
    jnz eoi
    mov eax, ds:[bx]
    cmp eax, 0314d5441h  ; ATM1
    jnz @F
    mov txptr, offset atm1
    jmp @3
@@: cmp eax, 0324d5441h  ; ATM2
    jnz eoi
    mov txptr, offset atm2
@3: mov bx, txptr
    mov al, [bx]
    inc txptr
    mov dx, BASE
    out dx, al
eoi:
    mov al, 20h
    out 20h, al
    pop ds
    pop es
    pop dx
    pop cx
    pop bx
    pop eax
    iret
irq0c endp
oldirq0c dd ?           ; old INT 0C vector
tsrseg  dw ?
magic dd 0ca1234cah     ; test the TSR's existence
rxbuf db 40 dup(?)
atm1  db "Hello from 8250!", 0dh, 0
atm2  db "This is a TSR program!", 0dh, 0
rxptr dw 0
txptr dw 0

msg db "TSR already installed!", 0ah, 0dh
msg1 db "Are you want to uninstall?(y/n)", '$'
msg2 db 0ah, 0dh, "TSR memory free failed!", 0ah, 0dh, '$'
msg3 db 0ah, 0dh, "TSR uninstalled!", 0ah, 0dh, '$'

start:
    mov ax, @code
    mov ds, ax
    mov ax, 0
    mov es, ax
    mov bx, 0ch * 4     ; INT 0C vector offset
    mov ax, es:[bx + 2] ; TSR segment
    mov tsrseg, ax      ; save the SEG
    mov ds, ax          ; SEG of the TSR
    mov eax, ds:[magic] ; offset of the TSR SEG
    cmp eax, 0ca1234cah
    jz tsr_ready
    mov ax, @code
    mov ds, ax          ; the real data segment
    call initialize
    call init8250
    lea dx, msg;
    mov cl, 4
    shr dx, cl
    add dx, 11h         ; add 1 for remainder and 10 for PSP
    mov ax, 3100h
    int 21h             ; resident and exit
tsr_ready:
    mov ax, @code
    mov ds, ax
    lea dx, msg
    mov ah, 09h
    int 21h
    mov ah, 01h
    int 21h
    cmp al, 'y'
    jnz keep
    call shut8250
    call remove_tsr
    jnc @F
    lea dx, msg2
    mov ah, 09h
    int 21h
    jmp keep
@@:
    lea dx, msg3        ; free memory sucess
    mov ah, 09h
    int 21h
keep:
    mov ax, 4c00h
    int 21h             ; return to dos

initialize proc near
    mov ax, 0
    mov es, ax
    mov ecx, es:[0ch * 4]   ; save the old vector
    mov oldirq0c, ecx
    cli
    mov ax, offset irq0c
    mov word ptr es:[0ch * 4], ax
    mov ax, seg irq0c
    mov word ptr es:[0ch * 4 + 2], ax
    sti
    ret
initialize endp

init8250 proc near
    mov dx, BASE + IIR
    in al, dx           ; clear pending flag
    mov dx, BASE + MSR
    in al, dx
    mov dx, BASE + LSR
    in al, dx
    mov dx, BASE
    in al, dx           ; clear pending data byte
    mov dx, BASE + LCR  ; Line Control Register
    in al, dx
    or al, 80h
    out dx, al          ; enable DLAB(Divisor Latch Access Bit)
    mov dx, BASE        ; 1200bps
    mov al, 60h
    out dx, al
    inc dx
    xor al, al
    out dx, al          ; baudrate 1200bps
    mov dx, BASE + LCR
    mov al, 03h         ; pattern: 8N1
    out dx, al          ; disable DLAB
    mov dx, BASE + IER  ; Interrupt Enable Register
    mov al, 03h         ; RX/TX interrupt enabled
    out dx, al
    mov dx, BASE + MCR
    mov al, 01011b      ; set out2 DTR,RTS
    out dx, al
    in al, 21h          ; 8059 OCW1
    and al, 11101111b   ; unmask IRQ4
    out 21h, al
    ret
init8250 endp

shut8250 proc near
    mov dx, BASE + IER  ; Interrupt Enable Register
    xor al, al
    out dx, al          ; disable all interrupt
    mov dx, BASE + MCR
    xor al, al
    out dx, al
    in al, 21h
    or al, 10h
    out 21h, al         ; mask IRQ4
    ret
shut8250 endp

remove_tsr proc near
    mov ax, tsrseg
    mov es, ax
    mov ecx, es:[oldirq0c]
    mov ax, 0
    mov es, ax
    cli
    mov es:[0ch * 4], ecx    ; restore the vector
    sti
    mov ax, tsrseg
    sub ax, 10h         ; the PSP
    mov es, ax
    push es
    mov ax, es:[2ch]    ; segment of the environment
    mov es, ax
    mov ah, 49h
    int 21h             ; free the environment
    pop es
    mov ah, 49h         ; free the program
    int 21h
    ret
remove_tsr endp

end start
