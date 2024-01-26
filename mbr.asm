org 0x7C00

jmp short start
nop
bdb_oem:                    db 'MKS OS  '
bdb_bytes_per_sector:       dw 512
bdb_sectors_per_cluster:    db 1
bdb_reserved_sectors:       dw 1
bdb_fat_count:              db 2
bdb_dir_entries_count:      dw 0E0h
bdb_total_sectors:          dw 2880
bdb_media_descriptor_type:  db 0F0h
bdb_sectors_per_fat:        dw 9
bdb_sectors_per_track:      dw 18
bdb_heads:                  dw 2
bdb_hidden_sectors:         dd 0
bdb_large_sector_count:     dd 0

ebr_drive_number:           db 0
bootldr_cluster:            db 0
ebr_signature:              db 29h
ebr_volume_id:              db 'bugs'
ebr_volume_label:           db 'MKS OS     '
ebr_system_id:              db 'FAT12   '

start:
    push cs
    pop ds

    mov [ebr_drive_number], dl

    mov si, msg_loading
    call puts

    and cl, 0x3F                        ; remove top 2 bits
    xor ch, ch
    mov [bdb_sectors_per_track], cx     ; sector count

    inc dh
    mov [bdb_heads], dh                 ; head count

    ; compute LBA of root directory = reserved + fats * sectors_per_fat
    ; note: this section can be hardcoded
    mov ax, [bdb_sectors_per_fat]
    mov bl, [bdb_fat_count]
    xor bh, bh
    mul bx                              ; ax = (fats * sectors_per_fat)
    add ax, [bdb_reserved_sectors]      ; ax = LBA of root directory
    push ax

    ; compute size of root directory = (32 * number_of_entries) / bytes_per_sector
    mov ax, [bdb_dir_entries_count]
    shl ax, 5                           ; ax *= 32
    xor dx, dx                          ; dx = 0
    div word [bdb_bytes_per_sector]     ; number of sectors we need to read

    test dx, dx                         ; if dx != 0, add 1
    jz .root_dir_after
    inc ax                              ; division remainder != 0, add 1
                                        ; this means we have a sector only partially filled with entries
.root_dir_after:

    ; read root directory
    mov cl, al                          ; cl = number of sectors to read = size of root directory
    pop ax                              ; ax = LBA of root directory
    mov dl, [ebr_drive_number]          ; dl = drive number (we saved it previously)
    mov bx, buffer                      ; es:bx = buffer
    call disk_read

    ; search for kernel.bin
    xor bx, bx
    mov di, buffer

.search_kernel:
    mov si, bootldr_file
    mov cx, 11                          ; compare up to 11 characters
    push di
    repe cmpsb
    pop di
    je .found_kernel

    add di, 32
    inc bx
    cmp bx, [bdb_dir_entries_count]
    jl .search_kernel

    ; kernel not found
    jmp kernel_not_found_error

.found_kernel:

    ; di should have the address to the entry
    mov ax, [di + 26]                   ; first logical cluster field (offset 26)
    mov [bootldr_cluster], ax

    ; load FAT from disk into memory
    mov ax, [bdb_reserved_sectors]
    mov bx, buffer
    mov cl, [bdb_sectors_per_fat]
    mov dl, [ebr_drive_number]
    call disk_read

    mov bx, BOOTLOADER_OFFSET

.load_kernel_loop:
    
    ; Read next cluster
    mov ax, [bootldr_cluster]
    
    ; not nice :( hardcoded value
    add ax, 31                          ; first cluster = (stage2_cluster - 2) * sectors_per_cluster + start_sector
                                        ; start sector = reserved + fats + root directory size = 1 + 18 + 134 = 33
    mov cl, 1
    mov dl, [ebr_drive_number]
    call disk_read

    add bx, [bdb_bytes_per_sector]

    ; compute location of next cluster
    mov ax, [bootldr_cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx                              ; ax = index of entry in FAT, dx = cluster mod 2

    mov si, buffer
    add si, ax
    mov ax, [ds:si]                     ; read entry from FAT table at index ax

    or dx, dx
    jz .even

.odd:
    shr ax, 4
    jmp .next_cluster_after

.even:
    and ax, 0x0FFF

.next_cluster_after:
    cmp ax, 0x0FF8                      ; end of chain
    jae .read_finish

    mov [bootldr_cluster], ax
    jmp .load_kernel_loop

.read_finish:
    
    ; jump to our kernel
    mov dl, [ebr_drive_number]          ; boot device in dl

    jmp 0:BOOTLOADER_OFFSET

    jmp halt


;
; Error handlers
;

kernel_not_found_error:
    mov si, msg_bootloader_not_found
    call puts
    jmp halt

halt:
    cli
    hlt
    jmp halt

;
; ds:si str
;
puts:
    push si
    push ax
    push bx

.loop:
    lodsb               ; loads next character in al
    or al, al           ; verify if next character is null?
    jz .done

    mov ah, 0x0E        ; call bios interrupt
    mov bh, 0           ; set page number to 0
    int 0x10

    jmp .loop

.done:
    pop bx
    pop ax
    pop si
    ret

;
; Disk routines
;

;
; Reads sectors from a disk
; Parameters:
;   - ax: LBA address
;   - cl: number of sectors to read (up to 128)
;   - dl: drive number
;   - es:bx: memory address where to store read data
;

bl_dap:
    dw 10h                  ; DAP size
DAP_SR:    dw 1                    ; sectors to read
DAP_offset:dw 0     ; offset
DAP_segment:    dw 0        ; segment
DAP_LBA:        dw 0        ;
    dw 0,0,0                ; lba

disk_read:
    push ax
    push dx
    push si

.start:
    mov [DAP_segment], es
    mov [DAP_offset],  bx
    mov [DAP_LBA],     ax
    mov [DAP_SR],      cl

    push ax
    mov ah, 42h
    mov si, bl_dap
    int 13h
    pop ax

    jnb .done
.load_error:
    push ax
    xor ah,ah
    int 13h
    pop ax
    jmp .start
.done:
    pop si
    pop dx
    pop si
    ret


msg_loading:            db 'tinyFat!', 10, 13, 0
msg_bootloader_not_found:   db 'bootldr.bin file not found!', 0
bootldr_file:        db 'BOOTLDR BIN'

BOOTLOADER_OFFSET      equ 0x8000


times 510-($-$$) db 0
dw 0AA55h

buffer:
