import amm_pkg::*;

module byte_incr_tb;

parameter int DATA_WIDTH_TB = 64; /////
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
int                        cnt_waiting;
int                        cnt_word;
int                        int_part;
int                        mod_part;
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
    // $display("setting 1");
    if( waitrequest_o_tb == 1'b1 )
      break;
    if( waitrequest_o_tb != 1'b1 )
      begin
        base_addr_i_tb <= base_addr;
        length_i_tb    <= length;
        run_i_tb       <= 1'b1;
      end
    // $display("setting 2");
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
int ind_power;
for( int i = 0; i < number_of_word; i++ )
  begin
    gen_word[31:0] = $urandom_range( 2**DATA_WIDTH_TB-1, 0);
    gen_word[63:32] = $urandom_range( 2**DATA_WIDTH_TB-1, 0);  
    // $display("gen_word: %0d bit: %x ", $size(gen_word), gen_word);
    for( int j = 0; j < BYTE_WORD; j++  )
      begin
        new_pkt.push_back( gen_word[7:0] );
        // $display("rd_byte: %x", gen_word[7:0]);
        gen_word = gen_word >> 8;
      end
  end
return new_pkt;

endfunction

assign int_part  = length / BYTE_WORD;
assign mod_part  = length % BYTE_WORD;

assign cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;

task gen_addr_length( input logic  [ADDR_WIDTH_TB-1:0] _base_addr,
                            logic  [ADDR_WIDTH_TB-1:0] _length
                    );

base_addr             = _base_addr;
length                = _length;
amm_write_data.length = length;
endtask

task wait_until_wr_done();

while( waitrequest_o_tb == 1'b1 )
  begin
    @( posedge clk_i_tb );
    cnt_waiting++;
    if( cnt_waiting >= length )
      break; 
  end


if( cnt_waiting >= length )
  $display(" !!!! Error Can't stop signal waitrequest_o !!!! ");
endtask

task test_data();

pkt_t new_wr_pkt;
pkt_t new_rd_pkt;

$display("#####Testing data begin#####");
while( amm_write_data.write_data_fifo.num() != 0 )
  begin
    amm_write_data.write_data_fifo.get( new_wr_pkt );
    amm_read_data.read_data_fifo.get( new_rd_pkt );
    for( int i = 0; i < length; i++ )
      begin
        if( ( new_wr_pkt[i] ) == ( new_rd_pkt[i] + 8'h1 ) )
          $display("Word %0d - Byte %0d correct", i/8, i%8 );
        else
          $display("Word %0d - Byte %0d error, byte correct: %x, byte written: %x ", i/8, i%8, new_rd_pkt[i] + 8'h1, new_wr_pkt[i] );
      end
  end
$display("\n");
endtask

task test_addr();

logic  [ADDR_WIDTH_TB-1:0] wr_addr;
logic  [ADDR_WIDTH_TB-1:0] max_addr;

logic  [ADDR_WIDTH_TB-1:0] cnt_addr;
int addr_size;

cnt_addr = {(ADDR_WIDTH_TB){1'b0}};

max_addr  = base_addr + cnt_word - 1;
addr_size = amm_write_data.write_addr_fifo.num();

$display("#####Testing addr begin#####");
while( amm_write_data.write_addr_fifo.num() != 0 )
  begin
    amm_write_data.write_addr_fifo.get( wr_addr );
    if( wr_addr != base_addr + cnt_addr )
      $display("Addr %0d error: rd: %x, wr: %x", cnt_addr, base_addr + cnt_addr,wr_addr );
    else
      $display("Addr %0d correct: rd: %x, wr: %x", cnt_addr, base_addr + cnt_addr,wr_addr );
    cnt_addr++;
  end
// if( addr_size < max_addr )
//   $display("Not enough address written, %0d more data has not been written!!!", max_addr - addr_size);
$display("\n");
endtask

task reset();

srst_i_tb <= 1'b1;
@( posedge clk_i_tb );
srst_i_tb <= 1'b0;
cnt_waiting = 0;
amm_read_if.readdatavalid <= 1'b0;
amm_read_if.waitrequest <= 1'b0;
amm_write_data.cnt_byte = 0;
@( posedge clk_i_tb );

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


    fork 
      assign_wr_wait_rq();
      amm_write_data.write_data();
    join_none
    $display("----------Test case 1: 20 bytes-----------");
    gen_addr_length( 10'h10, 10'd20 );
    // amm_write_data.length = length;
    setting();
    amm_read_data.read_data( gen_1_pkt( cnt_word ), 0, 0 );
    
    wait_until_wr_done();
    test_data();
    test_addr();

    reset();
    $display("---------Test case 2: 6 bytes-------------");
    gen_addr_length( 10'h10, 10'd6 );
    // amm_write_data.length = length;
    setting();
    amm_read_data.read_data( gen_1_pkt( cnt_word ),0, 0 );

    wait_until_wr_done();
    test_data();
    test_addr();

    reset();
    $display("---------Test case 3: 50 bytes-------------");
    gen_addr_length( 10'h10, 10'd50 );
    // amm_write_data.length = length;
    setting();
    amm_read_data.read_data( gen_1_pkt( cnt_word ),1, 1 );

    wait_until_wr_done();
    test_data();
    test_addr();

    reset();
    $display("---------Test case 4: 8 bytes-------------");
    gen_addr_length( 10'h10, 10'd6 );
    // amm_write_data.length = length;
    setting();
    amm_read_data.read_data( gen_1_pkt( cnt_word ),0, 0 );

    wait_until_wr_done();
    test_data();
    test_addr();

    $stop();

  end

endmodule