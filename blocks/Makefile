CC=clang -ccc-host-triple arm-apple-darwin9
LD=arm-apple-darwin9-gcc
#CC=arm-apple-darwin9-gcc


all : blocks.x

blocks.x : blocks.o
	$(LD) -o blocks.x blocks.o

blocks.o : blocks.c
	$(CC) -c blocks.c

clean :
	rm blocks.x blocks.o

deploy :
	scp blocks.x $(IP):/tmp
