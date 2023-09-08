CPU = 65816
AS = ca65
ASFLAGS = --cpu $(CPU) --create-dep $(<:.s=.d) --list-bytes 0

LD = ld65
LDFLAGS = -m bios.map

SOURCES = hardware_vectors.s bootstrap.s bios.s serial.s console.s monitor.s
PROGRAM = bios

.SUFFIXES:
.PHONY: all clean
all: $(PROGRAM)

%.o : %.s
	$(AS) $(ASFLAGS) -l $*.lst -o $@ $<

$(PROGRAM): $(SOURCES:.s=.o)
	$(LD) $(LDFLAGS) -C gw816_bios.cfg -o $@ $^

clean:
	$(RM) $(SOURCES:.s=.o) $(SOURCES:.s=.d) $(SOURCES:.s=.lst) bios.bin bootstrap.bin bios.map