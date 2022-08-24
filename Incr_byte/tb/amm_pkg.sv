package amm_pkg;

class amm_control_class #(
  parameter DATA_W   = 64,
  parameter ADDR_W   = 10,
  parameter BYTE_CNT = DATA_WIDTH/8
);

virtual avalon_mm_if #(
  .ADDR_WIDTH ( ADDR_W ),
  .DATA_WIDTH ( DATA_W )
) amm_if;

virtual amm_setting_if #(
  .ADDR_WIDTH ( ADDR_W )
) setting_if;

function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if,
              
              virtual amm_setting_if #(
                                    .ADDR_WIDTH ( ADDR_W )
                                  ) _setting_if
            );

this.amm_if     = _amm_if;
this.setting_if = _setting_if;

endfunction



endclass

endpackage