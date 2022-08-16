import ast_dmx_pkg::*;

module ast_dmx_tb;

parameter int DATA_WIDTH_TB     = 64;
parameter int CHANNEL_WIDTH_TB  = 8;
parameter int EMPTY_WIDTH_TB    = $clog2( DATA_WIDTH_TB / 8 );
parameter int TX_DIR_TB         = 4;

parameter int DIR_SEL_WIDTH_TB = TX_DIR_TB == 1 ? 1 : $clog2( TX_DIR_TB );

bit clk_i_tb;
logic srst_i_tb;
logic dir_i_tb [DIR_SEL_WIDTH_TB - 1 : 0 ];

initial
  forever
    #5 clk_i_tb = !clk_i_tb;

default clocking cb
  @( posedge clk_i_tb );
endclocking

avalon_st_if #(
  .DATA_WIDTH ( DATA_WIDTH_TB ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH ( EMPTY_WIDTH_TB ),
  .TX_DIR ( TX_DIR_TB )
) ast_snk_if ( clk_i_tb );

avalon_st_if #(
  .DATA_WIDTH ( DATA_WIDTH_TB ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH ( EMPTY_WIDTH_TB ),
  .TX_DIR ( TX_DIR_TB )
) ast_src_if ( clk_i_tb );

ast_dmx_c #(
  .DATA_W ( DATA_WIDTH_TB ),
  .CHANNEL_W ( CHANNEL_WIDTH_TB ),
  .EMPTY_W ( EMPTY_WIDTH_TB ),
  .TX_DIR ( TX_DIR_TB )
) ast_send_pk;

ast_dmx_c #(
  .DATA_W ( DATA_WIDTH_TB ),
  .CHANNEL_W ( CHANNEL_WIDTH_TB ),
  .EMPTY_W ( EMPTY_WIDTH_TB ),
  .TX_DIR ( TX_DIR_TB )
) ast_receive_pk;

ast_dmx #(
  .DATA_WIDTH    ( DATA_WIDTH_TB ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH   ( EMPTY_WIDTH_TB ),

  .TX_DIR        ( TX_DIR_TB ),
  .DIR_SEL_WIDTH ( DIR_SEL_WIDTH_TB )
) dut (
  .clk_i ( clk_i_tb ),
  .srst_i ( srst_i_tb ),

  .dir_i ( dir_i_tb ),

  .ast_data_i ( ast_snk_if.data ),
  .ast_startofpacket_i ( ast_snk_if.sop ),
  .ast_endofpacket_i ( ast_snk_if.eop ),
  .ast_valid_i ( ast_snk_if.valid ),
  .ast_empty_i ( ast_snk_if.empty ),
  .ast_channel_i ( ast_snk_if.channel ) ,
  .ast_ready_o ( ast_snk_if.ready ),

  .ast_data_o ( ast_src_if.data ),
  .ast_startofpacket_o ( ast_src_if.sop ),
  .ast_endofpacket_o ( ast_src_if.eop ),
  .ast_valid_o ( ast_src_if.valid ),
  .ast_empty_o ( ast_src_if.empty ),
  .ast_channel_o ( ast_src_if.channel ),
  .ast_ready_i ( ast_src_if.ready )
);



endmodule