    .386
STACK segment para stack 'STACK'
    db 512 dup(0)
STACK ends

BMCR_BASE       equ    0c040h       ; Bus Master Control Register base address
BM_COMMAND_REG  equ    BMCR_BASE    ; Command
BM_STATUS_REG   equ    BMCR_BASE + 2  ; Status
BM_PRD_ADDR_REG equ    BMCR_BASE + 4  ; Physical Region Descriptor address
PIO_BASE_ADDR1  equ    01f0h
PIO_BASE_ADDR2  equ    03f6h
SEC_NUM         equ    1
LBASECTOR       equ    0

DATA segment use16 para 'DATA'
    align 2
Buf         db      512 * SEC_NUM DUP (0)   ; DMA Buffer
BufLen      equ     $ - Buf
    align 4
PRD_Buf     dd      0           ; Physical Region Descriptor Buffer
            dd      0
DATA ends

EchoCH   macro   ascii
    mov     ah, 2
    mov     dl, ascii
    int     21h
endm

outx macro reg, val
    mov     dx, reg
    mov     al, val
    out     dx, al
endm

inx  macro reg
    mov     dx, reg
    in      al, dx
endm

CODE segment use16
    assume cs:CODE,ds:DATA,ss:STACK

start:
    mov     ax, DATA
    mov     ds, ax
    cli
    outx    BM_COMMAND_REG, 00h     ; start/STOP = 0, reset BM status
    outx    BM_STATUS_REG, 00000110B; clear interrupt and error flag
    ; create PRD
    mov     ax, ds
    movzx   eax, ax
    shl     eax, 4                  ; eax=base for data segment
    add     eax, offset Buf         ; eax=base for PRD_Bufj
    mov     PRD_Buf, eax               ; Physical address
    mov     word ptr [PRD_Buf+4], BufLen ; Byte count [15:1]
    mov     word ptr [PRD_Buf+6], 8000h  ; EOT=1
    mov     ax, ds
    movzx   eax, ax
    shl     eax, 4
    add     eax, offset PRD_Buf
    mov     dx, BM_PRD_ADDR_REG
    out     dx, eax                 ; PRD address
    outx    BM_COMMAND_REG, 08h     ; R/W=1, read from disk
    call    WaitDevice
    outx    PIO_BASE_ADDR1+6, 00h   ; Dev=0
    call    WaitDevice
    ;outx    PIO_BASE_ADDR2, 00      ; enable interrupt
    outx    PIO_BASE_ADDR1 + 1, 00h              ; =00
    outx    PIO_BASE_ADDR1 + 2, SEC_NUM          ; sector num
    outx    PIO_BASE_ADDR1 + 3, LBASECTOR
    outx    PIO_BASE_ADDR1 + 4, LBASECTOR/256
    outx    PIO_BASE_ADDR1 + 5, LBASECTOR/65536
    outx    PIO_BASE_ADDR1 + 6, 01000000B OR (LBASECTOR/256/256/256)
    outx    PIO_BASE_ADDR1 + 7, 0C8h             ; 0C8h=READ DMA
    outx    BM_COMMAND_REG, 09h     ; R/W=1, START/STOP=1, start DMA
@@:
    inx     BM_STATUS_REG
    and     al, 00000100B
    JZ      @B
    outx    BM_STATUS_REG, 00000100B
    outx    BM_COMMAND_REG, 00h     ; START/STOP = 0, stop DMA
    sti
    call    ShowBuf
    mov     ax,4C00h
    int     21h


    ; Wait until BSY=0,DRQ=0
WaitDevice  proc
@@:
    inx     PIO_BASE_ADDR1 + 7
    and     al, 10001000b
    jnz     @B
    ret
WaitDevice  endp

;Show what's in the buffer
ShowBuf     proc
    lea     si, Buf
    cld
    mov     bp, BufLen / 16
NextLine:
    mov     cx,16
NextCh:
    lodsb
    push    ax
    shr     al, 4
    call    ToAscii
    EchoCH  al
    pop     ax
    call    ToAscii
    EchoCH  al
    EchoCH  ' '
    loop    NextCh
    EchoCH  0dh
    EchoCH  0ah
    dec     bp
    jnz     NextLine
    ret
ShowBuf     endp

ToAscii     proc
    and     al, 0fh
    cmp     al, 10
    jae     @F
    add     al,'0'
    ret
@@: add     al,'A' - 10
    ret
ToAscii     endp

CODE ends
end start
