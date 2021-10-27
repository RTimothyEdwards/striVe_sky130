set script_dir [file dirname [file normalize [info script]]]

# User config
set ::env(DESIGN_NAME) striVe_spi
set ::env(VERILOG_FILES) "$script_dir/../../../verilog/rtl/striVe_spi.v"

# Fill this
set ::env(CLOCK_PERIOD) "10"
set ::env(CLOCK_PORT) "SCK"

set ::env(FP_CORE_UTIL)      50
set ::env(CELL_PAD) 8

set ::env(CLOCK_NET) $::env(CLOCK_PORT)
set ::env(RUN_MAGIC) 1
