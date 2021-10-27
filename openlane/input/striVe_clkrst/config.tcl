set script_dir [file dirname [file normalize [info script]]]
# User config
set ::env(DESIGN_NAME) striVe_clkrst

# Change if needed
set ::env(VERILOG_FILES) $script_dir/../../../verilog/rtl/striVe_clkrst.v
set ::env(SYNTH_SCRIPT) $script_dir/synth.tcl

# Fill this
set ::env(CLOCK_PERIOD) "50"
set ::env(CLOCK_PORT) "ext_clk"

set ::env(CLOCK_NET) "clk"
set ::env(RUN_SIMPLE_CTS) 0
set ::env(PL_INITIAL_PLACEMENT) 1
#set ::env(FP_CORE_UTIL) 35
set ::env(FP_CORE_MARGIN) 0

set ::env(FP_PDN_VOFFSET) 4
set ::env(FP_PDN_VPITCH) 15
set ::env(FP_PDN_HOFFSET) 4
set ::env(FP_PDN_HPITCH) 15
