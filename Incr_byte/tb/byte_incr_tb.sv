import amm_pkg::*;

module byte_incr_tb;

parameter int DATA_WIDTH_TB = 64;
parameter int ADDR_WIDTH_TB = 10;
parameter int BYTE_CNT_TB   = DATA_WIDTH_TB/8;

logic srst_i_tb;
bit clk_i_tb;

initial
  forever
    #5 clk_i_tb = !clk_i_tb;

default clocking cb
  @( posedge clk_i_tb );
endclocking

avalon_mm_if #( 
  .ADDR_WIDTH( ADDR_WIDTH_TB ),
  .DATA_WIDTH( DATA_WIDTH_TB )
) amm_read_if (
  .clk ( clk_i_tb )
) ;

avalon_mm_if #( 
  .ADDR_WIDTH( ADDR_WIDTH_TB ),
  .DATA_WIDTH( DATA_WIDTH_TB )
) amm_write_if (
  .clk ( clk_i_tb )
);

amm_setting_if #( 
  .ADDR_WIDTH( ADDR_WIDTH_TB )
) amm_set_if ();

amm_control_class #(
  .DATA_W ( DATA_WIDTH_TB ),
  .ADDR_W ( ADDR_WIDTH_TB ),
  .BYTE_CNT ( BYTE_CNT_TB )
) amm_read_data;

byte_inc #(
  .DATA_WIDTH ( DATA_WIDTH_TB ),
  .ADDR_WIDTH ( ADDR_WIDTH_TB ),
  .BYTE_CNT   ( BYTE_CNT_TB )
) dut (
  .clk_i ( clk_i_tb ),
  .srst_i ( srst_i_tb ),

  .base_addr_i ( amm_set_if.base_addr ),
  .length_i ( amm_set_if.length ),
  .run_i ( amm_set_if.run ),
  .waitrequest_o ( amm_set_if.waitrequest ),

  .amm_rd_address_o ( amm_read_if.address ),
  .amm_rd_read_o ( amm_read_if.read ),
  .amm_rd_readdata_i ( amm_read_if.readdata ),
  .amm_rd_readdatavalid_i ( amm_read_if.readdatavalid ),
  .amm_rd_waitrequest_i ( amm_read_if.waitrequest ),

  .amm_wr_address_o ( amm_write_if.address ),
  .amm_wr_write_o ( amm_write_if.write ),
  .amm_wr_writedata_o ( amm_write_if.writedata ),
  .amm_wr_byteenable_o ( amm_write_if.byteenable ),
  .amm_wr_waitrequest_i ( amm_write_if.waitrequest )
);

logic  [ADDR_WIDTH_TB-1:0] base_addr_tb;
logic  [ADDR_WIDTH_TB-1:0] length_tb;

initial
  begin
    srst_i_tb <= 1'b1;
    @( posedge clk_i_tb );
    srst_i_tb <= 1'b0;
    amm_write_if.waitrequest <= 1'b0;
    
    base_addr_tb = 10'h10;
    length_tb    = 10'd6;
    
    amm_read_data = new( amm_read_if, amm_set_if );
    fork
        amm_read_data.setting( base_addr_tb, length_tb );
        amm_read_data.read();
    join_any
    ##15;
    $stop();
  end

endmodule