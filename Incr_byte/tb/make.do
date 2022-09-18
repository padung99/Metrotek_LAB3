vlib work

set source_file {
  "../rtl/byte_inc.sv"
  "amm_pkg.sv"
  "../bfm_slave/synthesis/submodules/verbosity_pkg.sv"
  "../bfm_slave/synthesis/submodules/avalon_mm_pkg.sv"
  "../bfm_slave/synthesis/submodules/avalon_utilities_pkg.sv"

  "../bfm_master/synthesis/submodules/altera_avalon_mm_master_bfm.sv"
  "../bfm_master/synthesis/bfm_master.v"
  "../bfm_master/bfm_master_bb.v"

  "../bfm_slave/synthesis/submodules/altera_avalon_mm_slave_bfm.sv"
  "../bfm_slave/synthesis/bfm_slave.v"
  "../bfm_slave/bfm_slave_bb.v"

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

add wave -hex -r *

view -undock wave
run -all