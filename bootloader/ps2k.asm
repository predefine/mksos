; is extended?
ps2k_extended: db 0
ps2k_data: db 0
ps2k_key: db 0
ps2k_ready: db 0

ps2k_read:
    push ax
    in ax, 0x60
    mov [ps2k_data], al
    pop ax
    ret

ps2k_irq_handler:
    push ax

    call ps2k_read
    mov al, [ps2k_data]
    cmp al, 0xE0 ; is extended?
    je .extended

    mov [ps2k_key], al

    ;call ps2k_handler
    mov ah, 1
    mov [ps2k_ready], ah

    jmp .done
.extended:
    mov ah, 1
    mov [ps2k_extended], ah
.done:
    pop ax
    ret

ps2k_irq:
    call ps2k_irq_handler
    push ax
    mov ax, 1
    call pic_send_eoi
    pop ax
    iret

; ret: ah = extended, al = char
ps2k_get_scancode:
    mov al, [ps2k_ready]
    cmp al, 1
    jne ps2k_get_scancode ; while(!ps2k_ready);

    mov al, 0
    mov [ps2k_ready], al ; ps2k_ready = 0

    mov ah, [ps2k_extended]
    mov al, [ps2k_key] ; return (ps2k_extended << 8) | ps2k_key;

    ret

put_ex:
    push si
    mov si, exmsg
    call puts
    pop si
    ret

ps2k_init:
    push ax
    push dx
    mov al, IRQ_KEYBOARD
    mov dx, ps2k_irq
    call pic_add_interrupt
    pop dx
    pop ax
    ret

exmsg: db "[EX]",0
