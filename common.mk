$(PROG).exe: $(PROG).asm
ifeq "$(USELIB)" ""
	jwasm -mz -Fo $(PROG).exe $(PROG).asm
else
	jwasm -Fo $(PROG).obj $(PROG).asm
	wlink format dos option map name $(PROG).exe file $(PROG).obj file ../libs/mylib.lib
endif
emu:
	qemu-system-i386 ../../dos.cow -hdb fat:.
clean:
	rm *.exe *.obj *.err *.map -f
