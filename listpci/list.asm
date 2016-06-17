; List all pci devices
include ../libs/mylib.inc
    .model small
    .stack 128h
    .data
    count1 db ?        ;Bus NO.
    count2 db ?        ;Func NO.
    count3 db ?        ;Dev NO.
    str0 db 'PCI BIOS do not exists.$'
    str1 db 'BusNo   DevNo   FuncNo  VendorID  DeviceID', 0dh, 0ah, '*********************************************', 0dh, 0ah, '$'
    str2 db '      $'
    .code
start:
    mov ax, @data
    mov ds, ax      ; 赋值 DS
    mov ah,0b1h
    mov al,01h
    int 1ah		; 检查 PCI Bios, 01 号调用
    jnc scan		; PCI BIOS 存在则跳转
    mov dx, offset str0
    mov ah, 9
    int 21h		; 显示PCI BIOS不存在
    jmp mout
scan:
    mov count1,0	; 循环变量1, 总线号
    mov count2,0	; 循环变量2, 设备号
    mov count3,0	; 循环变量3, 功能号
    mov dx,offset str1
    mov ah,9
    int 21h		; 显示表头
lop:mov ah,count2    ;取得对应于Bus NO.、Function NO. DevNO.的VendorID、DeviceID
    mov al,count3
    mov cl,3
    sal al,cl
    or ah,al
    mov bl,ah	; BL: 高5 位为设备号，低 3 位为功能号
    mov cx, 0ffffh	; 初始化CX为ffff
    mov ax,0b109h	; 9号调用
    mov bh,count1	; BH: 总线号
    mov di,0		; 偏移地址为0
    int 1ah		; 读取配置空间字
    jc mout		; CF置位表示出错
    cmp cx, 0ffffh	; 比较cx是否为FFFF
    jnz @F		; 是FFFF表示没有查找到设备
    cmp count2, 0
    jz cont1    ; 功能号 0 的时候直接跳下一个设备
    jmp cont    ; 否则检查下一个功能
@@: mov  al,count1 ; 显示配置信息
    mov cx, 2
    call disp_ax	; 显示总线号
    mov dx,offset str2	
    mov ah,9
    int 21h		; 显示一串空格
    mov  al,count3
    mov cx, 2
    call disp_ax	; 显示设备号
    mov dx,offset str2
    mov ah,9
    int 21h
    mov  al,count2
    mov cx, 2
    call disp_ax	; 显示功能号
    mov dx,offset str2
    mov ah,9
    int 21h
    mov ax, 0b109h
    mov di,0h
    int 1ah		; 读取厂商ID
    mov ax, cx
    mov cx, 4
    call disp_ax	; 显示
    mov ah,9
    int 21h
    mov ax,0b109h
    mov di,2
    int 1ah		; 读取设备ID
    mov ax,cx
    mov cx,4
    call disp_ax	; 显示
    mov ah,02
    mov dl,0dh
    int 21h		; 回车
    mov dl,0ah
    int 21h		; 换行
    mov cl, count2
    cmp cl, 0	; 看功能号是否为0
    jnz cont		; 不为0则继续循环
    mov ax, 0b109h
    mov di, 0eh	; 读取配置空间首部类型
    int 1ah
    test cx, 80h	; 查看多功能设备标志
    jz cont1		; 非多功能,跳出循环
cont:
    cmp count2,7	; 功能号最大为7
    je cont1
    inc count2	; 功能号加1再循环
    jmp lop      
cont1:
    mov count2,0	; 功能号清零
    cmp count3,31	; 设备号最大为31
    je cont2
    inc count3	
    jmp lop		; 设备号加1再循环
cont2:
    mov count3,0	; 设备号清零
    cmp count1,3	; 总线号最大为3(可能小了)
    je mout		
    inc count1	; 总线号加1再循环
    jmp lop
mout:
    mov ah,4ch	; 循环结束退出
    int 21h
end start

