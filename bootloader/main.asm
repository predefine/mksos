org 0x7e00

%include "_entry.asm" ; Should be before any code/asm file

%include "io.asm"
%include "init_table_loader.asm"
%include "pic.asm"
%include "ps2k.asm"

init_table:
    dw enable_a20
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
    call getch
    call putc
    pop ax
    jmp mloop

enable_a20:
    push ax
    in al, 0x92
    test al, 2
    jnz .done ; a20 is enabled
    or al, 2
    out 0x92, al
.done:
    pop ax
    ret

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
