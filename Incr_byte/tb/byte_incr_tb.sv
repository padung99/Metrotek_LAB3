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
  .ADDR_WIDTH ( ADDR_WIDTH_TB ),
  .DATA_WIDTH ( DATA_WIDTH_TB )
) amm_read_if (
  .clk ( clk_i_tb )
) ;
 
avalon_mm_if #( 
  .ADDR_WIDTH ( ADDR_WIDTH_TB ),
  .DATA_WIDTH ( DATA_WIDTH_TB )
) amm_write_if (
  .clk ( clk_i_tb )
);

amm_control #(
  .DATA_W   ( DATA_WIDTH_TB ),
  .ADDR_W   ( ADDR_WIDTH_TB ),
  .BYTE_CNT ( BYTE_CNT_TB   )
) amm_read_data;

amm_control #(
  .DATA_W   ( DATA_WIDTH_TB ),
  .ADDR_W   ( ADDR_WIDTH_TB ),
  .BYTE_CNT ( BYTE_CNT_TB   )
) amm_write_data;

byte_inc #(
  .DATA_WIDTH ( DATA_WIDTH_TB ),
  .ADDR_WIDTH ( ADDR_WIDTH_TB ),
  .BYTE_CNT   ( BYTE_CNT_TB   )
) dut (
  .clk_i                  ( clk_i_tb                  ),
  .srst_i                 ( srst_i_tb                 ),

  .base_addr_i            ( base_addr_i_tb            ),
  .length_i               ( length_i_tb               ),
  .run_i                  ( run_i_tb                  ), 
  .waitrequest_o          ( waitrequest_o_tb          ),

  .amm_rd_address_o       ( amm_read_if.address       ),
  .amm_rd_read_o          ( amm_read_if.read          ),
  .amm_rd_readdata_i      ( amm_read_if.readdata      ),
  .amm_rd_readdatavalid_i ( amm_read_if.readdatavalid ),
  .amm_rd_waitrequest_i   ( amm_read_if.waitrequest   ),

  .amm_wr_address_o       ( amm_write_if.address      ),
  .amm_wr_write_o         ( amm_write_if.write        ),
  .amm_wr_writedata_o     ( amm_write_if.writedata    ),
  .amm_wr_byteenable_o    ( amm_write_if.byteenable   ),
  .amm_wr_waitrequest_i   ( amm_write_if.waitrequest  )
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
    if( waitrequest_o_tb == 1'b0 )
      deassert_wr_wait();
    else
      begin
        repeat( 2 )
          assert_wr_wait();
        repeat( 2 )
          deassert_wr_wait();
      end
    
  end

endtask

function automatic pkt_t gen_1_pkt ( int number_of_word );

pkt_t                     new_pkt;
logic [DATA_WIDTH_TB-1:0] gen_word;

for( int i = 0; i < number_of_word; i++ )
  begin
    gen_word = $urandom_range( 2**DATA_WIDTH_TB-1,0 );
    for( int j = 0; j < BYTE_WORD; j++  )
      begin
        new_pkt.push_back( gen_word[7:0] );
        $display("rd_byte: %x", gen_word[7:0]);
        gen_word = gen_word >> 8;
      end
  end
$display("\n");
return new_pkt;

endfunction

int cnt_word;

task gen_addr_length( input logic  [ADDR_WIDTH_TB-1:0] _base_addr,
                            logic  [ADDR_WIDTH_TB-1:0] _length
                    );

base_addr = _base_addr;
length    = _length;

endtask

task wait_until_wr_done();

int int_part;
int mod_part;

int_part  = length / BYTE_WORD;
mod_part  = length % BYTE_WORD;

cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;

$display("cnt_word: %0d", cnt_word);

while( waitrequest_o_tb == 1'b1 )
  @( posedge clk_i_tb );

// @( posedge clk_i_tb );

endtask

task reset();

srst_i_tb <= 1'b1;
@( posedge clk_i_tb );
srst_i_tb <= 1'b0;
amm_read_if.readdatavalid <= 1'b0;
amm_read_if.waitrequest <= 1'b0;

endtask

initial
  begin
    srst_i_tb <= 1'b1;
    amm_read_if.readdata <= '0; 
    amm_read_if.readdatavalid <= 1'b0;
    amm_read_if.waitrequest <= 1'b0;
    @( posedge clk_i_tb );
    srst_i_tb <= 1'b0;
    amm_write_if.waitrequest <= 1'b0;

    amm_read_data  = new( amm_read_if  );
    amm_write_data = new( amm_write_if );

    // gen_addr_length( 10'h10, 10'd15 );
    // setting();

    fork
      assign_wr_wait_rq();
      amm_write_data.write_data();
    join_none
    
    gen_addr_length( 10'h10, 10'd15 );
    setting();
    amm_read_data.read_data( gen_1_pkt( 4 ), 0 );
    wait_until_wr_done();

    reset();
    gen_addr_length( 10'h10, 10'd6 );
    setting();
    amm_read_data.read_data( gen_1_pkt( 2 ),0 );
    wait_until_wr_done();


    $stop();
  end

endmodule