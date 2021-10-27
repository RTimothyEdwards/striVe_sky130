package require openlane
set script_dir [file dirname [file normalize [info script]]]
set design_name striVe_spi
prep -design $script_dir -tag $design_name -run_path $script_dir/../../runs/ -overwrite
set save_path $script_dir/../../../

run_synthesis
run_floorplan
run_placement
#run_cts
gen_pdn
run_routing
run_magic    
run_magic_drc

save_magic_views -full_lef_path $::env(magic_result_file_tag).full.lef \
		 -abstract_lef_path $::env(magic_result_file_tag).lef \
		 -gds_path $::env(magic_result_file_tag).gds \
		 -mag_path $::env(magic_result_file_tag).mag \
		 -save_path $save_path \
		 -tag $::env(RUN_TAG)


