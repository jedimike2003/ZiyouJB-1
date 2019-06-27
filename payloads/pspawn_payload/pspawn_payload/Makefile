GO_EASY_ON_ME=1
TARGET  = pspawn_payload.dylib
OUTDIR ?= .
SRC     = $(wildcard *.c) $(wildcard *.m)

CC      = xcrun -sdk iphoneos gcc -arch arm64 -arch arm64e
LDID    = ldid
CFLAGS  = -dynamiclib -IcallJBD.h -Isubstitute.h -framework Foundation

all: $(OUTDIR)/$(TARGET)

$(OUTDIR)/$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $^
	$(LDID) -S $@

install: all

clean:
	rm $(TARGET)
