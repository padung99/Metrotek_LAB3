import amm_pkg::*;

module byte_incr_tb;

parameter int DATA_WIDTH_TB = 32; /////
parameter int ADDR_WIDTH_TB = 10;
parameter int BYTE_CNT_TB   = DATA_WIDTH_TB/8;

parameter BYTE_WORD = DATA_WIDTH_TB/8;
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
      end
    @( posedge clk_i_tb );

  end

endtask

task assert_wr_wait();

@( posedge clk_i_tb )
amm_write_if.waitrequest <= 1'b1;

endtask

task deassert_wr_wait();

@( posedge clk_i_tb )
amm_write_if.waitrequest <= 1'b0;

endtask

task assign_wr_wait_rq();

forever
  begin
    @( posedge clk_i_tb );
    repeat( 2 )
      assert_wr_wait();
    repeat( 2 )
      deassert_wr_wait();
  end

endtask

function automatic pkt_t gen_1_pkt ( int pkt_size );

pkt_t       new_pkt;
logic [7:0] gen_random_byte;

for( int i = 0; i < pkt_size; i++ )
  begin
    gen_random_byte = $urandom_range( 2**8,0 );
    new_pkt[i] = gen_random_byte;
  end

return new_pkt;

endfunction

int cnt_word;
int int_part;
int mod_part;

initial
  begin
    srst_i_tb <= 1'b1;
    amm_read_if.readdata <= '0; ///
    amm_read_if.readdatavalid <= 1'b0; //
    amm_read_if.waitrequest <= 1'b0; ///
    @( posedge clk_i_tb );
    srst_i_tb <= 1'b0;
    amm_write_if.waitrequest <= 1'b0;
       
    amm_read_data = new( amm_read_if );

    base_addr = 10'h10;
    length    = 10'd15;
    int_part  = length / BYTE_WORD;
    mod_part  = length % BYTE_WORD;
    cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;
    $display("cnt_word: %0d", cnt_word);

    setting();
    fork
      assign_wr_wait_rq();
      amm_read_data.read_data( gen_1_pkt( 16 ) );
    join_any

    while( !( ( amm_write_if.address == base_addr + cnt_word -1 ) && amm_write_if.write && amm_write_if.waitrequest == 1'b0 ) )
      @( posedge clk_i_tb );

    @( posedge clk_i_tb );


    $stop();
  end

endmodule