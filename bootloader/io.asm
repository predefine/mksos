%include "ps2k_scancodes.asm" ; 256 bytes of scancodes

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

keyboard_last_char: db 0
keyboard_flags: db 0
%define KEYBOARD_RIGHT_SHIFT 2
%define KEYBOARD_LEFT_SHIFT 1
; bit 1: right shift
; bit 0: left shift

; al = ascii key
getch:
    push ax
    push bx
.loop:
    call ps2k_get_scancode ; ah = extended, al = scancode
    ;call put_int
    cmp ah, 1
    je .loop

; Right shift checks
.rshift_flags:
    cmp al, 36h ; rshift press
    jne .rshift_flags_2
    mov ah, [keyboard_flags]
    or ah, KEYBOARD_RIGHT_SHIFT
    mov [keyboard_flags], ah
    jmp .loop
.rshift_flags_2:
    cmp al, 0b6h ; rshift release
    jne .lshift_flags
    mov ah, [keyboard_flags]
    xor ah, KEYBOARD_RIGHT_SHIFT
    mov [keyboard_flags], ah
    jmp .loop
.lshift_flags:
    cmp al, 2ah ; rshift press
    jne .lshift_flags_2
    mov ah, [keyboard_flags]
    or ah, KEYBOARD_LEFT_SHIFT
    mov [keyboard_flags], ah
    jmp .loop
.lshift_flags_2:
    cmp al, 0aah ; rshift release
    jne .ascii
    mov ah, [keyboard_flags]
    xor ah, KEYBOARD_LEFT_SHIFT
    mov [keyboard_flags], ah
    jmp .loop
.ascii:
    test al, 80h
    jne .loop ; while(extended || scancode >= 0x80) ps2k_get_scancode();

    mov ah, 0
    mov bx, ax

    mov al, [keyboard_flags]
    cmp al, 0
    je .ascii_2
    add bx, 128 ; use kbd_shift_case
.ascii_2:
    mov ah, [kbd_normal_case+bx]

    cmp ah, 0
    je .loop ; if(kbd_chars[scancode] == 0) goto .loop;

    mov [keyboard_last_char], ah

    pop bx
    pop ax
    mov al, [keyboard_last_char]
    ret

io_wait:
    push ax
    mov ax, 0
    out 0x80, ax
    pop ax
    ret
