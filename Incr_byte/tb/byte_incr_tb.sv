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
int                        cnt_waiting;
int                        cnt_word;
int                        int_part;
int                        mod_part;
bit                        setting_error;
int                        cnt_setting;
bit                        always_deassert;

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
  .BYTE_CNT ( BYTE_CNT_TB   ),
  .TYPE_RQ  ( "read"        )
) amm_read_data;

amm_control #(
  .DATA_W   ( DATA_WIDTH_TB ),
  .ADDR_W   ( ADDR_WIDTH_TB ),
  .BYTE_CNT ( BYTE_CNT_TB   ),
  .TYPE_RQ  ( "write"       )
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
    cnt_setting++;
    if( cnt_setting >= 5 )
      begin
        $display("waitrequest_o_tb error");
        setting_error = 1'b1;
        break;
      end
  end

endtask

// task assert_wr_wait();

// @( posedge clk_i_tb )
// amm_write_if.waitrequest <= 1'b1;

// endtask

// task deassert_wr_wait();

// @( posedge clk_i_tb )
// amm_write_if.waitrequest <= 1'b0;

// endtask

// task assert_wr_wait_rq( );

// forever
//   begin
//     if( always_deassert == 1'b0 )
//       begin
//         if( waitrequest_o_tb == 1'b0 )
//           deassert_wr_wait();
//         else
//           begin
//             repeat( 2 )
//               assert_wr_wait();
//             repeat( 2 )
//               deassert_wr_wait();
//           end
//       end
//     else
//       deassert_wr_wait();

//   end

// endtask

// function automatic pkt_t gen_1_pkt ( int                        _number_of_word,
//                                      bit                        _random_word,
//                                      logic [DATA_WIDTH_TB-1:0 ] _select_word );

// pkt_t                     new_pkt;
// logic [DATA_WIDTH_TB-1:0] gen_word;

// for( int i = 0; i < _number_of_word; i++ )
//   begin
//     if( _random_word == 1'b1 )
//       begin
//         gen_word[31:0]  = $urandom_range( 2**DATA_WIDTH_TB-1, 0);
//         gen_word[63:32] = $urandom_range( 2**DATA_WIDTH_TB-1, 0);
//       end
//     else
//       begin
//         gen_word[31:0]  = _select_word[31:0];
//         gen_word[63:32] = _select_word[63:32];
//       end

//     for( int j = 0; j < BYTE_WORD; j++  )
//       begin
//         new_pkt.push_back( gen_word[7:0] );
//         gen_word = gen_word >> 8;
//       end
//   end
// return new_pkt;

// endfunction

// assign int_part  = length / BYTE_WORD;
// assign mod_part  = length % BYTE_WORD;

// assign cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;

task gen_addr_length( input logic  [ADDR_WIDTH_TB-1:0] _base_addr,
                            logic  [ADDR_WIDTH_TB-1:0] _length
                    );
base_addr                = _base_addr;
length                   = _length;
amm_write_data.length    = length;
amm_read_data.length     = length;
amm_write_data.base_addr = base_addr;
amm_read_data.base_addr  = base_addr;


endtask

// task wait_until_wr_done();


// while( waitrequest_o_tb == 1'b1 )
//   begin
//     @( posedge clk_i_tb );
//     cnt_waiting++;
//     if( cnt_waiting >= 10*cnt_word ) 
//       break;
//   end

// if( cnt_waiting >= 10*cnt_word )
//   $display(" !!!! Error Can't stop signal waitrequest_o !!!! ");
// endtask

task test_data();

logic [7:0] new_wr_pkt;
logic [7:0] new_rd_pkt;
int   max_byte_read;
int   byte_read;
int   wr_byte_size;

wr_byte_size = amm_write_data.write_data_fifo.num();
byte_read = ( base_addr + length/BYTE_WORD > 10'h3ff ) ? ( 10'h3ff - base_addr + 1 )*BYTE_WORD : length;
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
    // for( int i = 0; i < new_wr_pkt.size(); i++ )
    //   begin
    //     if( ( new_wr_pkt[i] ) == ( new_rd_pkt[i] + 8'h1 ) )
    //       $display("Word %0d --- Byte %0d correct", i/8, i%8 );
    //     else
    //       $display("Word %0d --- Byte %0d error, byte correct: %x, byte written: %x ", i/8, i%8, new_rd_pkt[i] + 8'h1, new_wr_pkt[i] );
    //   end
  end

if( wr_byte_size != byte_read )
  $display("Error: %0d bytes have not been written to memory", byte_read - wr_byte_size );


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
amm_write_data.cnt_byte        = 0;
cnt_waiting                    = 0;
setting_error                  = 1'b0;
cnt_setting                    = 0;


@( posedge clk_i_tb );

endtask

task stop_rd();

forever
  begin
    @( posedge clk_i_tb );
    if( waitrequest_o_tb == 1'b0 )
      break;
  end

endtask

initial
  begin

    amm_read_data  = new( amm_read_if  );
    amm_write_data = new( amm_write_if );

    
    reset();
    gen_addr_length( 10'h10, 10'd20 );
    setting();

    fork
      // assert_wr_wait_rq();
      amm_write_data.send_rq( 0, 0 );
      amm_read_data.send_rq( 0, 0 );
      stop_rd();
    join_any

    // // // ***********************Testcase 1*******************************
    $display("----------Testcase 1: 20 bytes-----------");
    test_data();
    test_addr();
    // if( setting_error == 1'b0 )
    //   begin
    //     wait_until_wr_done();

    //     test_data();
    //     // test_addr();
    //     // @( posedge clk_i_tb );
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");


    // // // // ***********************Testcase 2*******************************
    $display("---------Testcase 2: Write until max address-------------");
    reset();
    gen_addr_length( 10'h3fc, 10'd45 );
    setting();
    stop_rd();
    test_data();
    test_addr();
    // reset();
    
    // gen_addr_length( 10'h10, 10'd6 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks");

    // // // // ***********************Testcase 3*******************************
    // reset();
    // $display("---------Testcase 3: Read 50 bytes-------------");

    // always_deassert = 1'b1;
    // gen_addr_length( 10'h10, 10'd50 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),1, 1 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 4*******************************
    // reset();
    // $display("---------Testcase 4: Read 8 bytes-------------");

    // always_deassert = 1'b0;
    // gen_addr_length( 10'h10, 10'd8 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 5*******************************
    // reset();
    // $display("---------Testcase 5: Read 16 bytes-------------");
    
    // gen_addr_length( 10'h10, 10'd16 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 6*******************************
    // reset();
    // $display("---------Testcase 6: Read 24 bytes-------------");
    
    // gen_addr_length( 10'h10, 10'd24 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 7*******************************
    // reset();
    // $display("---------Testcase 7: Read 30 bytes-------------");

    // gen_addr_length( 10'h10, 10'd30 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 8*******************************
    // reset();
    // $display("---------Testcase 8: Read 4 bytes-------------");

    // gen_addr_length( 10'h10, 10'd4 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 9*******************************
    // reset();
    // $display("---------Testcase 9: Read 1 bytes-------------");

    // gen_addr_length( 10'h10, 10'd1 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 10*******************************
    // reset();
    // $display("---------Testcase 10: add bytes exceeded the maximum address-------------");
    
    // gen_addr_length( 10'h3fc, 10'd45 ); //1111111100
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 11*******************************
    // reset();
    // $display("---------Testcase 11: add bytes until maximum address-------------");

    // gen_addr_length( 10'h3fc, 10'd29 ); 
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 12*******************************
    // reset();
    // $display("---------Testcase 12: add bytes exceeded the maximum address by 1 byte-------------");
    
    // gen_addr_length( 10'h3fc, 10'd33 ); 
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0 ),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 13*******************************
    // reset();
    // $display("---------Testcase 13: overload  byte ( +1 to ff )-------------");
    
    // gen_addr_length( 10'h10, 10'd7 ); 
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,0, 64'h2f1eff16ff12ffee),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    // // // // ***********************Testcase 14*******************************
    // reset();
    // $display("---------Testcase 14: add to full mem -------------");
    
    // gen_addr_length( 10'h0, 10'b1111111111 );
    // setting();
    // if( setting_error == 1'b0 )
    //   begin
    //     amm_read_data.read_data( gen_1_pkt( cnt_word,1, 0),0, 0 );

    //     wait_until_wr_done();
    //     test_data();
    //     test_addr();
    //   end
    // else
    //   $display("Setting error !!!! Can't run other tasks\n");

    $stop();
  end

endmodule