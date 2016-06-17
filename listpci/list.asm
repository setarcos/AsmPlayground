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
    mov ds, ax      ; ��ֵ DS
    mov ah,0b1h
    mov al,01h
    int 1ah		; ��� PCI Bios, 01 �ŵ���
    jnc scan		; PCI BIOS ��������ת
    mov dx, offset str0
    mov ah, 9
    int 21h		; ��ʾPCI BIOS������
    jmp mout
scan:
    mov count1,0	; ѭ������1, ���ߺ�
    mov count2,0	; ѭ������2, �豸��
    mov count3,0	; ѭ������3, ���ܺ�
    mov dx,offset str1
    mov ah,9
    int 21h		; ��ʾ��ͷ
lop:mov ah,count2    ;ȡ�ö�Ӧ��Bus NO.��Function NO. DevNO.��VendorID��DeviceID
    mov al,count3
    mov cl,3
    sal al,cl
    or ah,al
    mov bl,ah	; BL: ��5 λΪ�豸�ţ��� 3 λΪ���ܺ�
    mov cx, 0ffffh	; ��ʼ��CXΪffff
    mov ax,0b109h	; 9�ŵ���
    mov bh,count1	; BH: ���ߺ�
    mov di,0		; ƫ�Ƶ�ַΪ0
    int 1ah		; ��ȡ���ÿռ���
    jc mout		; CF��λ��ʾ����
    cmp cx, 0ffffh	; �Ƚ�cx�Ƿ�ΪFFFF
    jnz @F		; ��FFFF��ʾû�в��ҵ��豸
    cmp count2, 0
    jz cont1    ; ���ܺ� 0 ��ʱ��ֱ������һ���豸
    jmp cont    ; ��������һ������
@@: mov  al,count1 ; ��ʾ������Ϣ
    mov cx, 2
    call disp_ax	; ��ʾ���ߺ�
    mov dx,offset str2	
    mov ah,9
    int 21h		; ��ʾһ���ո�
    mov  al,count3
    mov cx, 2
    call disp_ax	; ��ʾ�豸��
    mov dx,offset str2
    mov ah,9
    int 21h
    mov  al,count2
    mov cx, 2
    call disp_ax	; ��ʾ���ܺ�
    mov dx,offset str2
    mov ah,9
    int 21h
    mov ax, 0b109h
    mov di,0h
    int 1ah		; ��ȡ����ID
    mov ax, cx
    mov cx, 4
    call disp_ax	; ��ʾ
    mov ah,9
    int 21h
    mov ax,0b109h
    mov di,2
    int 1ah		; ��ȡ�豸ID
    mov ax,cx
    mov cx,4
    call disp_ax	; ��ʾ
    mov ah,02
    mov dl,0dh
    int 21h		; �س�
    mov dl,0ah
    int 21h		; ����
    mov cl, count2
    cmp cl, 0	; �����ܺ��Ƿ�Ϊ0
    jnz cont		; ��Ϊ0�����ѭ��
    mov ax, 0b109h
    mov di, 0eh	; ��ȡ���ÿռ��ײ�����
    int 1ah
    test cx, 80h	; �鿴�๦���豸��־
    jz cont1		; �Ƕ๦��,����ѭ��
cont:
    cmp count2,7	; ���ܺ����Ϊ7
    je cont1
    inc count2	; ���ܺż�1��ѭ��
    jmp lop      
cont1:
    mov count2,0	; ���ܺ�����
    cmp count3,31	; �豸�����Ϊ31
    je cont2
    inc count3	
    jmp lop		; �豸�ż�1��ѭ��
cont2:
    mov count3,0	; �豸������
    cmp count1,3	; ���ߺ����Ϊ3(����С��)
    je mout		
    inc count1	; ���ߺż�1��ѭ��
    jmp lop
mout:
    mov ah,4ch	; ѭ�������˳�
    int 21h
end start

