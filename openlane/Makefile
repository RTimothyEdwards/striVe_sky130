BLOCKS = striVe_spi striVe_clkrst digital_pll striVe_soc striVe
INTERACTIVE = $(foreach block,$(BLOCKS), input/$(block)/interactive.tcl)
CLEAN = $(foreach block,$(BLOCKS), clean-$(block))

all: $(BLOCKS)

$(INTERACTIVE) :
	@echo "Missing $@. Please create an interactive script for that design"
	@exit 1

$(BLOCKS) : % : input/%/interactive.tcl 
ifeq ($(OPENLANE_ROOT),)
	@echo "Please export OPENLANE_ROOT"
	@exit 1
endif
	@echo "Executing ${OPENLANE_ROOT}/flow.tcl -interactive -file ./input/$*/interactive.tcl"
	@echo "###############################################"
	@sleep 1
	@${OPENLANE_ROOT}/flow.tcl -interactive -file ./input/$*/interactive.tcl

clean: 
	@echo "Use clean_all to clean everything :)"

clean_all: $(CLEAN)

$(CLEAN): clean-% :
	rm -rf runs/$*
	rm -rf ../gds/$**
	rm -rf ../mag/$**
	rm -rf ../lef/$**
