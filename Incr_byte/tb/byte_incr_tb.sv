import amm_pkg::*;

module byte_incr_tb;

parameter int DATA_WIDTH_TB = 32; /////
parameter int ADDR_WIDTH_TB = 10;
parameter int BYTE_CNT_TB   = DATA_WIDTH_TB/8;

logic srst_i_tb;
bit clk_i_tb;

logic                      run_i_tb;
logic                      waitrequest_o_tb;
logic  [ADDR_WIDTH_TB-1:0] base_addr_i_tb;
logic  [ADDR_WIDTH_TB-1:0] length_i_tb;

logic  [ADDR_WIDTH_TB-1:0] base_addr;
logic  [ADDR_WIDTH_TB-1:0] length;

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

// amm_setting_if #( 
//   .ADDR_WIDTH( ADDR_WIDTH_TB )
// ) amm_set_if ();

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

  .base_addr_i ( base_addr_i_tb ),
  .length_i ( length_i_tb ),
  .run_i ( run_i_tb ), 
  .waitrequest_o ( waitrequest_o_tb ),

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


task setting();

forever
  begin
    if( waitrequest_o_tb == 1'b1 )
      break;
    if( waitrequest_o_tb != 1'b1 )
      begin
        base_addr_i_tb <= base_addr;
        length_i_tb    <= length;
        run_i_tb       <= 1'b1;
      end

    if( run_i_tb == 1'b1 )
      begin
        run_i_tb       <= 1'b0;
        base_addr_i_tb <= 1'b0;
        length_i_tb    <= 1'b0;
        // repeat(10)
        //   @( posedge clk_i_tb );
        // break;
      end
    @( posedge clk_i_tb );

  end

endtask
 
initial
  begin
    srst_i_tb <= 1'b1;
    amm_read_if.readdata <= '0; ///
    amm_read_if.readdatavalid <= 1'b0; //
    amm_read_if.waitrequest <= 1'b0; ///
    @( posedge clk_i_tb );
    srst_i_tb <= 1'b0;
    amm_write_if.waitrequest <= 1'b0;
       
    // amm_read_data = new( amm_read_if );

    base_addr = 10'h10;
    length    = 10'd15;

    // amm_read_data.waitrequest = waitrequest_o_tb;
    // amm_read_data.base_addr = base_addr;
    // amm_read_data.length    = length;
    setting();
    // @( posedge clk_i_tb );
    
    // amm_read_if.waitrequest <= 1'b1;
    // @( posedge clk_i_tb );
    // amm_read_if.waitrequest <= 1'b0;

    // repeat(5)
    //   @( posedge clk_i_tb )
    // while( waitrequest_o_tb != 1'b0 )
    //   @( posedge clk_i_tb );
    // ##6;
    // @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 32'hd0;

    // @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // // amm_read_if.readdata <= 64'd0;

    // @( posedge clk_i_tb );
    @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 32'hd1;
 
    // @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // // amm_read_if.readdata <= 64'd0;

    // @( posedge clk_i_tb );
    @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 32'hd2;

    // @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // // amm_read_if.readdata <= 64'd0;

    // @( posedge clk_i_tb );
    @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 32'hd3;

    // @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // // amm_read_if.readdata <= 64'd0;

    // @( posedge clk_i_tb );
    @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 32'hd4;

    // @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // // amm_read_if.readdata <= 64'd0;
 
    // @( posedge clk_i_tb );
    @( posedge clk_i_tb );
    amm_read_if.readdatavalid <= 1'b1;
    amm_read_if.readdata <= 64'd45;

    repeat(5)
      @( posedge clk_i_tb );
    // amm_read_if.readdatavalid <= 1'b0;
    // amm_read_if.readdata <= 64'd0;

    //   amm_read_data.read();


    $stop();
  end

endmodule