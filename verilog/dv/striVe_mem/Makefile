# ---- Test patterns for project striVe ----

.SUFFIXES:

PATTERN = striVe_mem

all:  ${PATTERN:=.vcd}

hex:  ${PATTERN:=.hex}

%.vvp: %_tb.v %.hex
	iverilog -o $@ -I ../../rtl -I ../../../ip $<

%.vcd: %.vvp
	vvp $<

%.elf: %.c ../sections.lds ../start.s
	/ef/apps/bin/riscv32-unknown-elf-gcc -march=rv32imc -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ ../start.s $<

%.hex: %.elf
	/ef/apps/bin/riscv32-unknown-elf-objcopy -O verilog $< $@ 
	#/dev/stdout | sed -e '1 s/@00000000/@00100000/; 2,65537 d;' > $@

%.bin: %.elf
	/ef/apps/bin/riscv32-unknown-elf-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd *.log

.PHONY: clean hex all

