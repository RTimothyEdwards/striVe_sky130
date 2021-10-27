set ::env(DESIGN_NAME) "striVe_soc"

set script_dir [file dirname [file normalize [info script]]]
set ::env(VERILOG_FILES) $script_dir/../../../verilog/rtl/striVe_soc.v

set ::env(CLOCK_PERIOD) "10"
# which clock port ??
set ::env(CLOCK_PORT) "clk"

set ::env(SYNTH_MAX_FANOUT)  7
set ::env(SYNTH_STRATEGY)    2
set ::env(PL_TARGET_DENSITY) 0.4
set ::env(FP_CORE_UTIL)      50
set ::env(FP_PDN_VPITCH)     153.6
set ::env(FP_PDN_HPITCH)     153.18
set ::env(FP_ASPECT_RATIO)   1
set ::env(GLB_RT_ADJUSTMENT) 0.2
set ::env(CELL_PAD) 8


set ::env(CLOCK_NET) "clk"

set ::env(SYNTH_NO_FLAT) 1
set ::env(RUN_MAGIC) 1
set ::env(MAGIC_ZEROIZE_ORIGIN) 1
