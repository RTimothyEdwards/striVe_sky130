# ---- Test patterns for project striVe ----

.SUFFIXES:

PATTERN = striVe_gpio_gl

all:  ${PATTERN:=.vcd}

hex:  ${PATTERN:=.hex}

%.vvp: %_tb.v %.hex
	iverilog -I .. -I ../../../ip -I ../../rtl \
	-o $@ $< 

%.vcd: %.vvp
	vvp $<

%.elf: %.c ../sections.lds ../start.s
	/ef/apps/bin/riscv32-unknown-elf-gcc -march=rv32imc -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ ../start.s $<

%.hex: %.elf
	/ef/apps/bin/riscv32-unknown-elf-objcopy -O verilog $< $@ 

%.bin: %.elf
	/ef/apps/bin/riscv32-unknown-elf-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd *.log

.PHONY: clean hex all

