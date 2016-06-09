$(PROG): $(PROG).asm
	jwasm -mz $(PROG).asm
emu:
	qemu-system-i386 ../../dos.cow -hdb fat:.
clean:
	rm $(PROG).EXE -f
