CC=cc
CFLAGS=-nostdlib -ffreestanding -I. -O2 -mno-red-zone -mno-sse -mno-sse2 -mno-80387 -mcmodel=kernel -fno-pic

LD=ld
LDFLAGS=-nostdlib -Tlink.ld -zmax-page-size=0x1000 -static --no-dynamic-linker

CSRCS=$(shell find . -name '*.c' | grep -v 'viper-boot')
ASSRCS=$(shell find . -name '*.asm')
OBJS:=${CSRCS:.c=.o} ${ASSRCS:.asm=.o}

KERNEL=kernel.elf
TARGET=fat.img

.PHONY: all
all: $(TARGET)

viper-boot:
	git clone https://github.com/viper-org/viper-boot
	make -C viper-boot

viper.h:
	curl -Lo $@ https://raw.githubusercontent.com/viper-org/viper-boot/master/include/viper.h

ovmf:
	mkdir -p $@
	cd ovmf && curl -Lo OVMF-X64.zip https://efi.akeo.ie/OVMF/OVMF-X64.zip && unzip OVMF-X64.zip

%.o: %.c viper.h
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL): $(OBJS)
	$(LD) $(LDFLAGS) $^ -o $@

$(TARGET): $(KERNEL) viper-boot
	cp viper-boot/BOOTX64.EFI viper-boot/build ./
	mkdir -p boot
	cp ./viper.cfg $< boot/
	./build boot

.PHONY: run clean distclean
run: $(TARGET) ovmf
	qemu-system-x86_64 -bios ovmf/OVMF.fd -net none -M q35 -M smm=off -d int -drive file=$<,format=raw,if=ide,index=0,media=disk

clean:
	rm -rf $(OBJS) $(KERNEL) $(TARGET) boot/

distclean: clean
	rm -rf ovmf viper-boot viper.h build BOOTX64.EFI