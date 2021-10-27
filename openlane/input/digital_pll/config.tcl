set script_dir [file dirname [file normalize [info script]]]
# User config
set ::env(DESIGN_NAME) digital_pll

# Change if needed
set ::env(VERILOG_FILES) $script_dir/../../../verilog/rtl/digital_pll.v
set ::env(SYNTH_READ_BLACKBOX_LIB) 1

# Fill this
set ::env(CLOCK_PERIOD) "100000"
set ::env(CLOCK_PORT) "w"

set ::env(SYNTH_BUFFERING) 0
set ::env(SYNTH_SIZING) 0

set ::env(FP_CORE_UTIL)      50
set ::env(CELL_PAD) 8

set ::env(RUN_SIMPLE_CTS) 0



set ::env(RUN_MAGIC) 1
set ::env(FP_IO_VEXTEND) 2
set ::env(FP_IO_HEXTEND) 2
set ::env(FP_IO_VTHICKNESS_MULT) 5
set ::env(FP_IO_HTHICKNESS_MULT) 5
