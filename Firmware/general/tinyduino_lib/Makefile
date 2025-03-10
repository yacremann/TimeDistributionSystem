CFLAGS :=  -I./include -Werror -nostdlib -march=rv32im_zicsr -mabi=ilp32 -O0 -fno-builtin -ffreestanding -ffunction-sections -fdata-sections -fno-inline -fno-common  -fomit-frame-pointer
#-fomit-frame-pointer -ffreestanding
# -ffunction-sections -fdata-sections -fno-inline -fno-common -ffunction-sections -fdata-sections
#  -nostdlib
	
#-ffunction-sections -fdata-sections -fno-inline -fno-common -ffreestanding -fno-builtin  

CC = /opt/rv32im/bin/riscv32-unknown-elf-gcc
AR = /opt/rv32im/bin/riscv32-unknown-elf-ar

all:	tinyduino.a

bin/init.o:	src/init.c
	$(CC) $(CFLAGS)  -c src/init.c -o bin/init.o
		
bin/prescaler.o:	src/prescaler.c
	$(CC) $(CFLAGS) -c src/prescaler.c -o bin/prescaler.o
	
bin/printf.o:	src/printf.c
	$(CC) $(CFLAGS) -O3  -c src/printf.c -o bin/printf.o

	
bin/uart.o:	src/uart.c
	$(CC) $(CFLAGS) -O0 -c src/uart.c -o bin/uart.o
	
bin/timer.o:	src/timer.c
	$(CC) $(CFLAGS) -c src/timer.c -o bin/timer.o
	
bin/spi.o:	src/spi.c
	$(CC) $(CFLAGS) -c src/spi.c -o bin/spi.o

#bin/start.o: src/start.S
#	$(CC) -DCOPY_DATA_TO_RAM -c -o $@ $(TARGET_CFLAGS) $<
	

tinyduino.a: bin/init.o bin/prescaler.o bin/printf.o bin/uart.o bin/timer.o bin/spi.o
	$(AR) -rc tinyduino.a bin/init.o bin/prescaler.o bin/printf.o bin/uart.o bin/timer.o bin/spi.o


clean:
	rm -f bin/*.o
	rm -f tinyduino.a
