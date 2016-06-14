bl.bin: bl.asm
	jwasm -bin -Fo bl.bin bl.asm
emu:
	qemu-system-i386 -drive file=bl.bin,format=raw
clean:
	rm bl.bin -f
