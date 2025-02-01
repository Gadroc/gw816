CPU = 65816
AS = ca65
ASFLAGS = --cpu $(CPU) --create-dep $(<:.s=.d) --list-bytes 0 --include-dir inc

LD = ld65
LDFLAGS = -m $@.map -Ln $@.debug

SOURCES = src/kernel/init.s src/kernel/registers.s src/kernel/irq.s \
		  src/kernel/monitor.s src/kernel/serial.s src/fonts/charset.s \
		  src/kernel/vectors.s src/kernel/print.s
.SUFFIXES:
.PHONY: all clean
all: kernel install

%.o : %.s
	$(AS) $(ASFLAGS) -l $*.lst -o $@ $<

kernel: $(SOURCES:.s=.o)
	$(LD) $(LDFLAGS) -C kernel.cfg -o $@.bin $^

install:
	cp *.bin ../clio/

clean:
	$(RM) $(SOURCES:.s=.o) $(SOURCES:.s=.d) $(SOURCES:.s=.lst) *.bin *.map