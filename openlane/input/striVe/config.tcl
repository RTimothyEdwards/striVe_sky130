# User config
set script_dir [file dirname [file normalize [info script]]]
set ::env(DESIGN_NAME) striVe

set verilog_root $script_dir/../../../verilog/rtl/
# Change if needed
set ::env(VERILOG_FILES) $verilog_root/striVe_nopwr_nocorner.v
set ::env(VERILOG_FILES_BLACKBOX) "$verilog_root/striVe_soc.v $verilog_root/striVe_spi.v $verilog_root/digital_pll.v $verilog_root/striVe_clkrst.v $verilog_root/lvlshiftdown.v"
set ::env(SYNTH_DEFINES) "SYNTH_OPENLANE"

set ::env(SYNTH_READ_BLACKBOX_LIB) 1


# Fill this
set ::env(CLOCK_PERIOD) "50"
set ::env(CLOCK_PORT) "xclk"

set ::env(USE_GPIO_PADS) 1
set ::env(RUN_SIMPLE_CTS) 0
set ::env(FILL_INSERTION) 0
set ::env(SYNTH_TOP_LEVEL) 1
set ::env(CELL_PAD) 0
set ::env(MAGIC_PAD) 0
set ::env(MAGIC_ZEROIZE_ORIGIN) 0

#set ::env(EXTRA_LEFS) [glob $::env(DESIGN_DIR)/src/mag/*.lef]
#set ::env(EXTRA_GDS_FILES) [glob $::env(DESIGN_DIR)/src/mag/*.gds]
