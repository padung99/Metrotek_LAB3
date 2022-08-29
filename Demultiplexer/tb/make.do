vlib work

set source_file {
  "../rtl/ast_dmx.sv"
  "../../Extender/tb/avalon_st_if.sv"
  "../../Extender/tb/avl_st_pkg.sv"
  "ast_dmx_tb.sv"
}


foreach files $source_file {
  vlog -sv $files
}

#Return the name of last file (without extension .sv)
set fbasename [file rootname [file tail [lindex $source_file end]]]

vsim $fbasename

add log -r /*

add wave -r *

add wave "sim:/ast_dmx_tb/dut/ast_data_o"
add wave "sim:/ast_dmx_tb/dut/ast_startofpacket_o"

add wave "sim:/ast_dmx_tb/dut/ast_endofpacket_o"
add wave "sim:/ast_dmx_tb/dut/ast_valid_o"

add wave "sim:/ast_dmx_tb/dut/ast_empty_o"
add wave "sim:/ast_dmx_tb/dut/ast_channel_o"

view -undock wave
run -all