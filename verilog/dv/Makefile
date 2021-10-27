# ---- Test patterns for project striVe ----

.SUFFIXES:
.SILENT: clean all

PATTERNS = striVe_gpio  striVe_gpio_gl  striVe_mem striVe_mem_gl striVe_uart striVe_uart_gl striVe_perf striVe_perf_gl striVe_hkspi

all:  ${PATTERNS}
	for i in ${PATTERNS}; do \
		( cd $$i && make -f Makefile $${i}.vcd &> verify.log && grep Monitor verify.log) ; \
	done

clean:  ${PATTERNS}
	for i in ${PATTERNS}; do \
		( cd $$i && make clean ) ; \
	done

.PHONY: clean all
