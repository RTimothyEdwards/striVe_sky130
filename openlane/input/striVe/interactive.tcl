package require openlane
set script_dir [file dirname [file normalize [info script]]]
prep -design $script_dir -tag striVe -run_path $script_dir/../../runs/ -overwrite

#config


set macros "digital_pll striVe_spi striVe_clkrst striVe_soc lvlshiftdown"
set lefs_root $script_dir/../../../lef/
set padframe_root $::env(TMP_DIR)/padframe/striVe/
set verilog_root $script_dir/../../../verilog/rtl/
set stubs_root $script_dir/../../../verilog/stubs/
set top_rtl $script_dir/../../../verilog/rtl/striVe.v
set lefs {}

exec mkdir -p $padframe_root/mag
exec mkdir -p $padframe_root/verilog
file copy -force $top_rtl $padframe_root/verilog/
puts "$macros"

set padframe_cfg $script_dir/padframe.cfg
if { [file exists $padframe_cfg] } {
	file copy -force $padframe_cfg $padframe_root/mag/
}
foreach macro "$macros" {
	file copy -force $lefs_root/${macro}_abstract.lef $padframe_root/mag/$macro.lef
	file copy -force $verilog_root/${macro}.v $padframe_root/verilog/
	lappend lefs $lefs_root/${macro}_abstract.lef
}
# need not to hard code this
lappend lefs $lefs_root/sky130_fd_sc_hd_conb_1.lef
file copy -force $lefs_root/sky130_fd_sc_hd_conb_1.lef $padframe_root/mag/

foreach stub "[glob $stubs_root/*.v]" {
	file copy -force $stub $padframe_root/verilog/
}

foreach lef $lefs {
	zeroize_origin_lef -file $lef
}

set padframe_cfg $padframe_root/mag/padframe.cfg
set padframe_def $padframe_root/mag/padframe.def
set core_def 	 $padframe_root/mag/core.def
padframe_gen -folder $padframe_root
set area [padframe_extract_area -cfg $padframe_cfg]
set ::env(DIE_AREA) $area
set ::env(CORE_AREA) $area
set ::env(FP_SIZING) absolute

add_lefs -src $lefs
verilog_elaborate
# verilog2def for nets
chip_floorplan
merge_components -input1 $padframe_def -input2 $core_def -output $::env(CURRENT_DEF)
run_routing
exit
set $::env(EXTRA_LEFS) $lefs
run_magic
run_magic_drc
