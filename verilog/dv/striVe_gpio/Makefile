# ---- Test patterns for project striVe ----

.SUFFIXES:

PATTERN = striVe_gpio

GCC_PATH=/ef/apps/bin

all:  ${PATTERN:=.vcd}

hex:  ${PATTERN:=.hex}

%.vvp: %_tb.v %.hex
	iverilog -I ../../rtl -I ../../../ip \
	$< -o $@

%.vcd: %.vvp
	vvp $<

%.elf: %.c ../sections.lds ../start.s
	${GCC_PATH}/riscv32-unknown-elf-gcc -march=rv32imc -Wl,-Bstatic,-T,../sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ ../start.s $<

%.hex: %.elf
	${GCC_PATH}/riscv32-unknown-elf-objcopy -O verilog $< $@ 

%.bin: %.elf
	${GCC_PATH}/riscv32-unknown-elf-objcopy -O binary $< /dev/stdout | tail -c +1048577 > $@

# ---- Clean ----

clean:
	rm -f *.elf *.hex *.bin *.vvp *.vcd *.log

.PHONY: clean hex all

