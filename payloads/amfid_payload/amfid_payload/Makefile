TARGET  = amfid_payload.dylib
OUTDIR ?= .
SRC     = $(wildcard *.c) $(wildcard *.m) $(wildcard */*.c) $(wildcard */*.m)

CC      = xcrun -sdk iphoneos gcc -arch arm64 -arch arm64e
LDID    = ldid
CFLAGS  = -dynamiclib -I. -I./helpers -framework Foundation -framework IOKit -lc++ -lmis

.PHONY: all install clean

all: $(OUTDIR)/$(TARGET)


$(OUTDIR)/$(TARGET): $(SRC) | $(OUTDIR)
	$(CC) $(CFLAGS) -o $@ $^
	$(LDID) -S $@

install: all

clean:
	rm amfid_payload.dylib
