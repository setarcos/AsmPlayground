; List all pci devices

stck segment para stack
    dw 128h dup(0)
stck ends
dseg segment
    count1 db ?        ;Bus NO.
    count2 db ?        ;Func NO.
    count3 db ?        ;Dev NO.
    str0 db 'PCI BIOS do not exists.$'
    str1 db 'BusNo   DevNo   FuncNo  VendorID  DeviceID', 0dh, 0ah, '*********************************************', 0dh, 0ah, '$'
    str2 db '      $'
    dseg ends
cseg segment
assume cs:cseg,ss:stck,ds:dseg
start:
    mov ax, dseg
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
    or   ah,al
    mov bl,ah	; BL: 高5 位为设备号，低 3 位为功能号
    mov cx, 0ffffh	; 初始化CX为ffff
    mov ax,0b109h	; 9号调用
    mov bh,count1	; BH: 总线号
    mov di,0		; 偏移地址为0
    int 1ah		; 读取配置空间字
    jc kk3		; CF置位表示出错
    jmp kk4		; 无错
kk3:jmp cont
kk4:cmp cx, 0ffffh	; 比较cx是否为FFFF
    jz kk1		; 是FFFF表示没有查找到设备
    jmp kk2		; 查找到了
kk1:jmp cont1		; 二级跳转是由于jz跳转不到cont1

kk2:mov  al,count1 ; 显示配置信息
    mov cx, 2
    call disp	; 显示总线号
    mov dx,offset str2	
    mov ah,9
    int 21h		; 显示一串空格
    mov  al,count3
    mov cx, 2
    call disp	; 显示设备号
    mov dx,offset str2
    mov ah,9
    int 21h
    mov  al,count2
    mov cx, 2
    call disp	; 显示功能号
    mov dx,offset str2
    mov ah,9
    int 21h
    mov ax, 0b109h
    mov di,0h
    int 1ah		; 读取厂商ID
    mov ax, cx
    mov cx, 4
    call disp	; 显示
    mov ah,9
    int 21h
    mov ax,0b109h
    mov di,2
    int 1ah		; 读取设备ID
    mov ax,cx
    mov cx,4
    call disp	; 显示
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
disp proc near		;将AX寄存器里的数据转化为ASC码并显示, cx=2,显示低8位, cx=4, 显示全部16位
    push dx
    push bx
    push cx
    mov bx, ax
    mov dx, cx
lp1:mov ax, bx
    and ax, 0fh
    push ax
    push cx
    mov cl, 4
    shr bx, cl
    pop cx
    loop lp1
    mov cx, dx
lp2:pop ax
    call disp2
    loop lp2
    pop cx
    pop bx
    pop dx
    ret
disp endp
disp2  proc near	; 显示al的低四位
    push   dx 
    push   bx
    and al,0fh
    mov dl,al
    cmp dl,9
    jle num 
    add dl,7
num:add dl,30h
    mov ah,02h
    int 21h
    pop bx
    pop dx
    ret
disp2 endp
cseg ends
end start

