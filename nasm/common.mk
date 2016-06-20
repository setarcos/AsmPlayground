$(PROG).com: $(PROG).asm
	nasm $(PROG).asm -fbin -o $(PROG).com -l $(PROG).lst
emu:
	qemu-system-x86_64 ../../../dos.cow -hdb fat:. $(QEMUFLAG)
bin:
	qemu-system-x86_64 -drive file=$(PROG).com,format=raw $(QEMUFLAG)
clean:
	rm *.com *.exe *.obj *.err *.map *.lst *.bin -f
