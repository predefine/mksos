; pic for real mode(based on interrupts)

%define PIC1_COMMAND 0x20
%define PIC2_COMMAND 0xA0

%define PIC_CMD_EOI 0x20

%define IRQ_TIMER 0x00
%define IRQ_KEYBOARD 0x01

; al = irq
; dx = handler pointer
pic_add_interrupt:
    push ax
    push bx
    push dx
    cmp al, 8h
    jl .pic1
.pic2:
   add al, 0x60 ; 0x8-0xf -> 0x70-0x77
.pic1:
    add al, 0x08
    mov bl, 4
    mul bl
    mov bx, ax
    mov ax, cs
    ;
    push es
    push ax
    mov ax, 0
    mov es, ax
    pop ax
    ;
    mov [es:bx], dx
    mov [es:bx+2], ax
    ;
    pop es
    ;
.end:
    pop dx
    pop bx
    pop ax
    sti
    ret

; dx = irq
pic_send_eoi:
    pushf
    push ax
    push dx

    mov dx, ax
    mov ax, PIC_CMD_EOI

    cmp dx, 0x08
    jge .pic2
.pic1:
    out PIC1_COMMAND, ax
    jmp .end
.pic2:
    out PIC2_COMMAND, ax
    jmp .end
.end:
    pop dx
    pop ax
    popf
    ret

pic_init:
    ret
