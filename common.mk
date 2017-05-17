OUTDIR=exe
ifneq "$(FLAT)" ""
$(PROG).bin: $(PROG).asm
	jwasm -bin -Fo $(PROG).bin $(PROG).asm
emu:
	qemu-system-x86_64 -drive file=$(PROG).bin,format=raw $(QEMUFLAG)
else
../$(OUTDIR)/$(PROG).exe: $(PROG).asm
	-@mkdir ../$(OUTDIR) 2>/dev/null || echo "" >/dev/null
ifeq "$(USELIB)" ""
	jwasm -mz -Fo ../$(OUTDIR)/$(PROG).exe $(PROG).asm
else
	jwasm -Fo $(PROG).obj $(PROG).asm
	wlink format dos option map name ../$(OUTDIR)/$(PROG).exe file $(PROG).obj file ../libs/mylib.lib
endif # USELIB
emu:
	qemu-system-x86_64 ../../dos.cow -drive file=fat:rw:../$(OUTDIR),format=raw $(QEMUFLAG)
endif # FLAT
$(PROG).obj: $(PROG).asm
	jwasm -omf -Zi -Fo $(PROG).obj $(PROG).asm
$(PROG).lst: $(PROG).obj
	wdis $(PROG).obj -l=$(PROG).lst
list: $(PROG).lst
clean:
	rm ../$(OUTDIR)/$(PROG).exe *.obj *.err *.map *.lst *.bin -f
