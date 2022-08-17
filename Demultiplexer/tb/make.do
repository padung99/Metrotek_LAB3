vlib work

set source_file {
  "../rtl/ast_dmx.sv"
  "snk_avalon_st_if.sv"
  "src_avalon_st_if.sv"
  "ast_dmx_pkg.sv"
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

add wave "sim:/ast_dmx_tb/ast_src_if.data"
add wave "sim:/ast_dmx_tb/ast_src_if.sop"

add wave "sim:/ast_dmx_tb/ast_src_if.eop"
add wave "sim:/ast_dmx_tb/ast_src_if.valid"

add wave "sim:/ast_dmx_tb/ast_src_if.empty"
add wave "sim:/ast_dmx_tb/ast_src_if.channel"

view -undock wave
run -all