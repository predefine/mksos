org 0x7e00

%include "_entry.asm" ; Should be before any code/asm file

%include "io.asm"
%include "init_table_loader.asm"
%include "pic.asm"
%include "ps2k.asm"

init_table:
    dw pic_init
    dw ps2k_init
    ;dw add_timer
    dw 0

;dw aadd_timer

add_timer:
    push ax
    push dx
    mov al, IRQ_TIMER
    mov dx, irq0
    call pic_add_interrupt
    pop dx
    pop ax
    ret

irq0:
    call put_dot
    push ax
    xor ax,ax
    call pic_send_eoi
    pop ax
    iret

put_dot:
    push ax
    mov al, '.'
    call putc
    pop ax
    ret

load_init_table:
    push si
    mov si, init_table
    call init_table_loader
    pop si
    ret

mloop:
    push ax
    call ps2k_get_scancode
    call putc
    pop ax
    jmp mloop

main:
    call load_init_table
    push si
    mov si, himsg
    call puts
    pop si
    jmp mloop
    ret

himsg: db "Hello, bootloader world(just like mbr but bigger xd)!", 10, 13, 0
hmm: db "Hmm, init table working, nice", 10, 13, 0
