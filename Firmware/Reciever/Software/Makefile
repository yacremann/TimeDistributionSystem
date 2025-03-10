# The Potato Processor Software Components
# (c) Kristian Klomsten Skordal 2015 <kristian.skordal@wafflemail.net>
# Report bugs and issues on <https://github.com/skordal/potato/issues>
# Adapted by Yves Acremann

.PHONY: all clean
include common.mk

#TARGET_LDFLAGS += -Wl,-Tvexriscv_new.ld -Wl,--Map,bootloader.map
TARGET_LDFLAGS =   -nostartfiles -Wl,--no-relax   -Tvexriscv_new.ld -Wl,--Map=bootloader.map
#   -Wl,--gc-sections -lc -fno-builtin  -fno-builtin -ffreestanding    -march=rv32im -mabi=ilp32

#TARGET_LDFLAGS = -nostartfiles --specs=nosys.specs -Wl,--no-relax -Wl,--gc-sections -lc -Tvexriscv_new.ld 
#TARGET_CFLAGS += -O3 -Itinyduino_lib/include
TARGET_CFLAGS :=  -nostdlib -Werror  -march=rv32im_zicsr -mabi=ilp32  -O0 -Itinyduino_lib/include -fno-builtin -ffreestanding -ffunction-sections -fdata-sections -fno-inline -fno-common  -fomit-frame-pointer
# -ffunction-sections -fdata-sections -fno-inline -fno-common -mabi=ilp32 -march=rv32im
# -fno-builtin -fomit-frame-pointer -ffunction-sections -fdata-sections -fno-inline -fno-common  
#-fomit-frame-pointer -ffreestanding

AS= /opt/riscv32/bin/riscv32-unknown-elf-as

OBJECTS :=  start.o main.o

all: bootloader.hex

bootloader.bin: $(OBJECTS)
	$(TARGET_LD) -o bootloader.elf $(TARGET_LDFLAGS) $(OBJECTS)  tinyduino_lib/tinyduino.a  
	$(TARGET_SIZE) bootloader.elf
	$(TARGET_OBJCOPY) -O binary bootloader.elf bootloader.bin
	
bootloader.hex: bootloader.bin
	bin2hex.py bootloader.bin bootloader.hex


clean:
	-$(RM) $(OBJECTS)
	-$(RM) bootloader.elf bootloader.bin bootloader.coe
	rm -f bootloader.mif
	rm -f bootloader.hex
	rm -f bootloader.map

# Object file rules:

main.o: main.c
	$(TARGET_CC) -c -o $@ $(TARGET_CFLAGS) $<
	
#start.o: start.S
#	$(TARGET_CC) $(TARGET_CFLAGS) -c start.S -o start.o

start.o: start.S
	$(TARGET_CC) -DCOPY_DATA_TO_RAM -c -o $@ $(TARGET_CFLAGS) $<

