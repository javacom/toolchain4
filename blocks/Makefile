SDK=/toolchain4/sys42
CC=clang -ccc-host-triple arm-apple-darwin9
LD=arm-apple-darwin9-gcc

CFLAGS+=-I$(SDK)/usr/include
CFLAGS+= -fblocks

LDFLAGS+=-L$(SDK)/usr/lib

all : blocks.x

blocks.x : blocks.o
	$(LD) $(LDFLAGS) -o blocks.x blocks.o

blocks.o : blocks.c
	$(CC) $(CFLAGS) -c blocks.c

clean :
	rm -f blocks.x blocks.o

deploy :
	scp blocks.x $(IP):/tmp
