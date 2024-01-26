AS := nasm

PARTS := mbr.bin bootloader.bin

all: disk.img

test: disk.img
	qemu-system-i386 -hda $<

disk.img: $(PARTS)
	$(Q)cp $< $@
	truncate -s 1440K $@
	mcopy -i $@ bootloader.bin "::BOOTLDR.bin"

bootloader.bin: bootloader/main.asm $(wildcard bootloader/*.asm)
	$(Q)$(AS) -i bootloader -f bin -o $@ $<

%.bin: %.asm
	$(Q)$(AS) -f bin -o $@ $<

clean:
	$(Q)rm -f $(PARTS) disk.img
