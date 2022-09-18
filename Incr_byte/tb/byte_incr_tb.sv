import amm_pkg::*;
module byte_incr_tb;
parameter int DATA_WIDTH_TB = 64;
parameter int ADDR_WIDTH_TB = 10;
parameter int BYTE_CNT_TB   = DATA_WIDTH_TB/8;
parameter     BYTE_WORD     = DATA_WIDTH_TB/8;
logic                      srst_i_tb;
bit                        clk_i_tb;
logic                      run_i_tb;
logic                      waitrequest_o_tb;
logic  [ADDR_WIDTH_TB-1:0] base_addr_i_tb;
logic  [ADDR_WIDTH_TB-1:0] length_i_tb;
logic  [ADDR_WIDTH_TB-1:0] base_addr;
logic  [ADDR_WIDTH_TB-1:0] length;
int                        timeout_waiting;
int                        total_word;
int                        int_part;
int                        mod_part;
bit                        setting_error;
int                        timeout_setting;


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
    timeout_setting++;
    if( timeout_setting >= 5 )
      begin
        $display("waitrequest_o_tb error");
        setting_error = 1'b1;
        break;
      end
  end
endtask
assign int_part  = length / BYTE_WORD;
assign mod_part  = length % BYTE_WORD;
assign total_word  = ( mod_part == 0 ) ? int_part : int_part + 1;
task gen_addr_length( input logic  [ADDR_WIDTH_TB-1:0] _base_addr,
                            logic  [ADDR_WIDTH_TB-1:0] _length
                    );
base_addr = _base_addr;
length    = _length;
endtask
task test_data();
logic [7:0] new_wr_pkt;
logic [7:0] new_rd_pkt;
int         byte_read;
int         wr_byte_size;
wr_byte_size = amm_write_data.write_data_fifo.num();
byte_read    = ( base_addr + length/BYTE_WORD > 10'h3ff ) ? ( 10'h3ff - base_addr + 1 )*BYTE_WORD : length;
$display("#####Testing data begin#####");
while( amm_write_data.write_data_fifo.num() != 0 )
  begin
    amm_write_data.write_data_fifo.get( new_wr_pkt );
    amm_read_data.read_data_fifo.get( new_rd_pkt );
    if( new_wr_pkt == ( new_rd_pkt + 1 ) )
      begin
        $display("Byte %0d correct --- read: %x, write: %x", wr_byte_size -amm_write_data.write_data_fifo.num(),  new_rd_pkt, new_wr_pkt);
      end
    else
      begin
        $display("Byte %0d error --- read: %x, write: %x", wr_byte_size -amm_write_data.write_data_fifo.num(),  new_rd_pkt, new_wr_pkt);
      end
  end
if( wr_byte_size != byte_read )
  $display("Error: %0d bytes have not been written to memory", byte_read - wr_byte_size );
$display("\n");
endtask
task test_addr();
logic  [ADDR_WIDTH_TB-1:0] wr_addr;
logic  [ADDR_WIDTH_TB-1:0] cnt_addr;
cnt_addr = {(ADDR_WIDTH_TB){1'b0}};
$display("#####Testing addr begin#####");
while( amm_write_data.write_addr_fifo.num() != 0 )
  begin
    amm_write_data.write_addr_fifo.get( wr_addr );
    if( wr_addr != ( base_addr + cnt_addr ) )
      $display("Addr %0d error: rd: %x, wr: %x", cnt_addr, base_addr + cnt_addr,wr_addr );
    else
      $display("Addr %0d correct: rd: %x, wr: %x", cnt_addr, base_addr + cnt_addr,wr_addr );
    cnt_addr++;
  end
$display("\n");
endtask
task reset();
srst_i_tb <= 1'b1;
@( posedge clk_i_tb );
srst_i_tb                     <= 1'b0;
amm_read_if.readdatavalid     <= 1'b0;
amm_read_if.waitrequest       <= 1'b0;
amm_write_data.write_data_fifo = new();
amm_read_data.read_data_fifo   = new();
amm_write_data.write_addr_fifo = new();
amm_read_data.read_addr_fifo   = new();
timeout_waiting                = 0;
setting_error                  = 1'b0;
timeout_setting                = 0;
@( posedge clk_i_tb );
endtask

task stop_rq();
while( waitrequest_o_tb == 1'b1 )
  begin
    @( posedge clk_i_tb );
    timeout_waiting++;
    if( timeout_waiting >= 10*total_word )
      break;
  end
if( timeout_waiting >= 20*total_word )
  $display(" !!!! Error Can't stop signal waitrequest_o !!!! ");
endtask

task  setting_response( input int                       _delay,
                              logic [DATA_WIDTH_TB-1:0] _random_word
                     );
amm_read_data.delay        = _delay;
amm_read_data.random_word  = _random_word;
endtask
initial
  begin
    amm_read_data  = new( amm_read_if  );
    amm_write_data = new( amm_write_if );
  
    reset();
    gen_addr_length( 10'h10, 10'd20 );
    setting_response( 5, ( DATA_WIDTH_TB )'(0) );
    setting();
    fork
      amm_write_data.send_rq(0);
      amm_read_data.send_rq(0);
      amm_read_data.response_rd_rq();

      stop_rq();
    join_any
    // // // ***********************Testcase 1*******************************
    $display("----------Testcase 1: 20 bytes-----------");
    test_data(); 
    test_addr();


    // // // // ***********************Testcase 2*******************************
    reset();
    $display("---------Testcase 2: Write until max address-------------");
    gen_addr_length( 10'h3fc, 10'd45 );
    setting();
    stop_rq();
    test_data();
    test_addr();
    ##10;

    // // // // ***********************Testcase 3*******************************
    reset();
    $display("---------Testcase 3: 4 bytes-------------");
    gen_addr_length( 10'h10, 10'd4 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // // ***********************Testcase 4*******************************
    reset();
    $display("---------Testcase 4: 8 bytes-------------");
    gen_addr_length( 10'h10, 10'd8 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // // ***********************Testcase 5*******************************
    reset();
    $display("---------Testcase 5: 16 bytes-------------");
    gen_addr_length( 10'h10, 10'd16 );
    setting();
    stop_rq();
    test_data();
    test_addr();

    // // // // ***********************Testcase 6*******************************
    reset();
    $display("---------Testcase 6: 24 bytes-------------");
    gen_addr_length( 10'h10, 10'd24 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // // ***********************Testcase 7*******************************
    reset();
    $display("---------Testcase 7: 30 bytes-------------");
    gen_addr_length( 10'h10, 10'd30 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // // ***********************Testcase 8*******************************
    reset();
    $display("---------Testcase 8: 1 byte-------------");
    gen_addr_length( 10'h10, 10'd1 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // ***********************Testcase 9*******************************
    reset();
    $display("---------Testcase 9: add bytes until maximum address ( 29 bytes ) -------------");
    gen_addr_length( 10'h3fc, 10'd29 );
    setting();
    stop_rq();
    test_data();
    test_addr();


    // // // // ***********************Testcase 10*******************************
    reset();
    $display("---------Testcase 10: add bytes exceeded the maximum address by 1 byte ( total 33 bytes ) -------------");
    gen_addr_length( 10'h3fc, 10'd33 );
    setting();
    stop_rq();
    test_data();
    test_addr();

    // // // // ***********************Testcase 11*******************************
    reset();
    $display("---------Testcase 11: test overload byte ( 0xff + 0x01 = 0x00 )-------------");
    setting_response( 5, 64'h5624ff5863ff1f2e );
    gen_addr_length( 10'h10, 10'd7 );

    setting();
    stop_rq();
    test_data();
    test_addr();

    // // // // ***********************Testcase 12*******************************
    reset();
    setting_response( 5, 0 );
    $display("---------Testcase 12: add bytes from addr 0 to max addr ");
    gen_addr_length( 10'h0, 10'b1111111111 );
    setting();
    stop_rq();
    test_data();
    test_addr();
  
    $stop();
  end
endmodule