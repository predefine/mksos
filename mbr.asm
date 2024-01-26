org 0x7c00

_start:
    push cs
    pop ds
    mov sp, 0x7C00
    call main

halt:
    cli
    hlt
    jmp halt
    ret

puts:
    push ax
    push bx
    push si
    cld
.loop:
    lodsb ; al = si[x], x++
    or al, al ; is al == 0?
    jz .end ; yes

    mov ah, 0eh
    xor bl, bl

    int 10h

    jmp .loop

.end:
    pop si
    pop bx
    pop ax
    ret

load_error:
    mov si, dload_error_msg
    call puts
    jmp halt
    ret

bl_dap:
    dw 10h           ; DAP size
    dw 2             ; sectors to read
    dw load_addr     ; offset
DAP_segment:    dw 0 ; segment
    dd 1,0           ; lba

load_bl:
    push ax
    push dx
    push si

    mov ax, ds
    mov [DAP_segment], ax

    mov ah, 42h
    mov si, bl_dap
    mov dl, [BOOTDISK]
    int 13h

    jb load_error

    pop si
    pop dx
    pop si
    ret

main:
    push ax
    push bx
    push cx
    push dx
    push si

    mov [BOOTDISK], dl ; save boot disk

    mov si, msg
    call puts

    call load_bl

    mov si, jumping
    call puts


    pop si
    pop dx
    pop cx
    pop bx
    pop ax

    jmp load_addr

    call unknown_error
    ret

unknown_error:
    push si
    mov si, WHAT
    call puts
    pop si
    jmp halt

msg: db "tinyMbr!", 10, 13, 0
dload_error_msg: db "Load from disk error, halting", 10, 13, 0
jumping: db "Jumping to main bootloader", 10, 13, 0
WHAT: db "UNKNOWN ERROR!!!", 10, 13, 0
BOOTDISK: db 0

times 510-($-$$) db 0
db 0x55, 0xaa

load_addr:
