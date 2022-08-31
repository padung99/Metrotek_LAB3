vlib work

set source_file {
  "../rtl/byte_inc.sv"
  "amm_pkg.sv"
  "avalon_mm_if.sv"
  "byte_incr_tb.sv"
}


foreach files $source_file {
  vlog -sv $files
}

#Return the name of last file (without extension .sv)
set fbasename [file rootname [file tail [lindex $source_file end]]]

vsim $fbasename

add log -r /*
add wave -r *

view -undock wave
run -all