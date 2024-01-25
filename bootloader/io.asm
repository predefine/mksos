; al = char
putc:
    push ax
    push bx

    mov ah, 0eh
    xor bl,bl
    int 10h

    pop bx
    pop ax
    ret

; si = ptr to string
puts:
    push ax
    push bx
    push si
    cld
.loop:
    lodsb ; al = si[x], x++
    or al, al ; is al == 0?
    jz .end ; yes

    call putc

    jmp .loop

.end:
    pop si
    pop bx
    pop ax
    ret

; ax = number
put_int:
    push ax
    push bx
    push cx
    xor cx, cx
.L1:
    mov bl, 10
    div bl ; ah = ax % 10, al = ax / 10

    xchg ah, al
    mov bh, ah
    xor ah,ah
    push ax
    inc cx
    mov al, bh

    cmp ax, 0
    jne .L1

.L2:
    pop ax
    add al, '0'
    call putc
    loop .L2

    mov al, 13
    call putc
    mov al, 10
    call putc

    pop cx
    pop bx
    pop ax
    ret

io_wait:
    push ax
    mov ax, 0
    out 0x80, ax
    pop ax
    ret
