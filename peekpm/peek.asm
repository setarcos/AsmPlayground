;----
;    Example program switching to Protected and back to Real Mode
;    Jerzy Tarasiuk                    8-Jun-1995
;    Revised by Setarcos               18-Jun-2016
    .model small
    .386p

    .stack 512
    .code
;-
;    GDT to be used in Protected Mode
;
mygdt   dq    0                     ; null descriptor
gdtcd   dw    -1, 0, 9A00h, 0       ; 64kB code segment, base to be set
        dw    -1, 0, 9200h, 008Fh   ; 4GB R/W segment, base=0
        dw    -1, 0, 9200h, 0       ; 64kB R/W segment, base=0
badcpum db    "Not 80386+ CPU!", 0Dh, 0Ah, '$'
inpmerm db    "Already in Protected Mode!", 0Dh, 0Ah, '$'
bada20m db    "Address line A20 disabled!", 0Dh, 0Ah, '$'

;---
;    pm_mem    - access memory (peek/poke a byte) in Protected Mode
;
;    entry     EBX=address, CX=0 for peek to ECX or CX!=0 for poke ECX
;    changes   EAX, EDX, GDTR, CL
;
;    requires A20 to be enabled if to be used on a PC compatible
;    (A20 is usually enabled if DOS is loaded into HMA)
;
pm_mem    proc
    pushf
    push ds
    mov ax, cs
    movzx eax, ax
    shl eax, 4                 ; eax=base for code segment
    mov dword ptr gdtcd[2], eax
    mov byte ptr gdtcd[5], 9Ah ; set segment attribute
    mov dx, offset mygdt
    movzx edx, dx
    add eax, edx               ; eax=base for GDT
    push eax
    push 20h
    movzx eax, sp        
    cli                       ; make sure no ISR will interfere now
    lgdt fword ptr ss:[eax]   ; LGDT is necessary before switch to PM
    add sp, 6
    mov eax, cr0
    or al, 1
    mov cr0, eax         ; sets Protected Mode
    db 0eah              ; far jump to set CS & clear prefetch queue
    dw pm_in
    dw 8
pm_in:
    mov dx, 10h
    mov ds, dx           ; load 4G segment descriptor from GDT into DS
    jcxz pm_get
    mov [ebx], ecx
pm_get:
    mov ecx, [ebx]
    mov dl, 18h
    mov ds, dx           ; load 64kB segment descriptor from GDT into DS
    and al, not 1
    mov cr0, eax         ; sets Real Mode
    db 0eah              ; far jump to restore CS & clear prefetch queue
    dd pm_out            ; it MUST be jump - far return crashed!
pm_out:
    pop ds
    popf
    ret
pm_mem endp

;---
;    vfycpu    - make sure have proper CPU, in Real Mode, and A20 enabled
;
;    changes    AX, DX
;    returns    AL=error code if anything wrong
;    error codes:
;            040h    - not 32-bit CPU (PM, A20 not tested)
;            001h    - already in PM (386+, A20 not tested)
;            0FFh    - A20 disabled (32-bit CPU in RM)
;
vfycpu proc
    pushf               ; save flags
    cli                 ; make sure no ISR will interfere now
;
    pushf               ; 1. make sure have at least 386
    pop ax              ; AX=flags
    xor ah, 40h         ; toggle NT
    push ax             ; stack: modified_flags, original_flags
    popf
    pushf               ; stack: modified_flags_from_cpu, original_flags
    pop dx              ; DX=flags passed via CPU
    mov al, dh
    xor al, ah
    jnz vcfail          ; improper CPU
;
    smsw ax             ; 2. make sure are in Real Mode
    and al, 1
    jnz vcfail          ; if already in PM (maybe VM86)
;
    push ds             ; 3. make sure A20 is enabled
    push es
    push bx
    xor bx, bx
    mov ds, bx
    mov ax, -1
    mov es, ax
    xor [bx], ah         ; change byte[000000h]
    mov al, es:[bx+10h]  ; get byte[100000h]
    xor [bx], ah         ; change byte[000000h]
    xor al, es:[bx+10h]  ; compare byte[100000h] with its previous value
                         ; 0 if unchanged, -1 means [000000h]==[100000h]
    pop bx
    pop es
    pop ds
vcfail:
    popf                ; restore flags
    test al, al         ; test error code
    ret
vfycpu endp

;---
;    disp_al - use int 21h to display low part of al
;
disp_al  proc near
    push dx
    push bx
    and al,0fh
    add al,90h ; Al is from 90h to 09Fh.
    daa        ; Al is from 90h to 99h (carry clear) or 00h to 06h (carry set).
    adc al,40h ; Al is from 0D0h to 0D9h or 41h to 46h.
    daa        ; Al is from 30h to 39h ("0" to "9") or 41h to 46h ("A" to "F").
    mov dl, al
    mov ah, 02h
    int 21h
    pop bx
    pop dx
    ret
disp_al endp

;---
;    sample program
;    - check if have proper CPU, exit with error message if bad
;    - peek byte[0FFFFFFF0h] in PM
;    - peek byte[0FFFEFFF0h] in PM
;    - exit (status = byte obtatained)
;
start:
    in al, 92h
    or al, 02h
    out 92h, al      ; enable a20
    call vfycpu      ; make sure having proper CPU and mode
    add al, al
    jz cpuok         ; .. OK
    lea dx, bada20m
    jc error
    lea dx, badcpum
    js error
    lea dx, inpmerm
error:
    push cs          ; not proper - error message and exit
    pop ds
    mov ah, 9
    int 21h
    mov ax, 4cffh    ; exit, status=-1
    int 21h

cpuok:
    xor cx, cx        ; peek a byte
    mov ebx, 0fea00000h ; pci-edu mem, should return 010000ed
    call pm_mem
    mov ebx, ecx
    mov cx, 8
@@:
    rol ebx, 4
    mov eax, ebx
    call disp_al
    loop @B
exit:
    mov ah, 4ch       ; exit
    mov al, cl        ; status = the byte
    int 21h

end start

