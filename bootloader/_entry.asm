_start:
    push cs
    pop ds
    call main
    jmp halt

halt:
    cli
    hlt
    jmp halt
