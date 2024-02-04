CPU = 65816
AS = ca65
ASFLAGS = --cpu $(CPU) --create-dep $(<:.s=.d) --list-bytes 0 --include-dir inc

LD = ld65
LDFLAGS = -m $@.map -Ln $@.debug

SOURCES = src/bootstrap/bootstrap.s src/bootstrap/hardware_vectors.s \
		  src/kernel/kernel.s src/kernel/scratch.s src/kernel/post.s \
		  src/kernel/memory.s src/tests/memory_tests.s \
		  src/monitor/display.s
PROGRAM = rom

.SUFFIXES:
.PHONY: all clean
all: $(PROGRAM) install

%.o : %.s
	$(AS) $(ASFLAGS) -l $*.lst -o $@ $<

$(PROGRAM): $(SOURCES:.s=.o)
	$(LD) $(LDFLAGS) -C gw816_kernel.cfg -o $@ $^

install:
	cp *.bin ../clio/

clean:
	$(RM) $(SOURCES:.s=.o) $(SOURCES:.s=.d) $(SOURCES:.s=.lst) *.bin *.map