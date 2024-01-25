; si = init table
init_table_loader:
    push si
    push ax

.loop:
    lodsw
    or ax, ax
    jz .end
    call ax

    jmp .loop
.end:
    pop ax
    pop si
    ret
