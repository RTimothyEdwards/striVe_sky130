yosys -import
for { set i 0 } { $i < [llength $::env(VERILOG_FILES)] } { incr i } {
  read_verilog [lindex $::env(VERILOG_FILES) $i]
}
synth -top $::env(DESIGN_NAME)
dfflibmap -liberty $::env(LIB_SYNTH)
abc -liberty $::env(LIB_SYNTH)
write_verilog  -noattr -noexpr -nohex -nodec $::env(yosys_result_file_tag).v
