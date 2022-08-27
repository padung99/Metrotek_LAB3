import avl_st_pkg::*;

module ast_width_extender_tb;

parameter DATA_IN_W_TB   = 64;
parameter DATA_OUT_W_TB  = 256;
parameter CHANNEL_W_TB   = 10;
parameter EMPTY_IN_W_TB  = $clog2(DATA_IN_W_TB/8) ?  $clog2(DATA_IN_W_TB/8) : 1;
parameter EMPTY_OUT_W_TB = $clog2(DATA_OUT_W_TB/8) ?  $clog2(DATA_OUT_W_TB/8) : 1;

parameter WORD_OUT = ( DATA_OUT_W_TB/8 );
parameter WORD_IN  = ( DATA_IN_W_TB/8 );


parameter MAX_PKT = 5;

bit       clk_i_tb;
logic     srst_i_tb;

int k;

int min_assert;
int max_assert;
int min_deassert;
int max_deassert;

int byte_send;

initial
  forever
    #5 clk_i_tb = !clk_i_tb;

default clocking cb
  @( posedge clk_i_tb );
endclocking

avalon_st #(
  .DATA_W ( DATA_IN_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB )
) ast_snk_if (
  .clk( clk_i_tb )
);

avalon_st #(
  .DATA_W    ( DATA_OUT_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB )
) ast_src_if (
  .clk( clk_i_tb )
);

ast_width_extender #(
  .DATA_IN_W   ( DATA_IN_W_TB   ),
  .EMPTY_IN_W  ( EMPTY_IN_W_TB  ),
  .CHANNEL_W   ( CHANNEL_W_TB   ),
  .DATA_OUT_W  ( DATA_OUT_W_TB  ),
  .EMPTY_OUT_W ( EMPTY_OUT_W_TB )
) dut (
  .clk_i  ( clk_i_tb  ),
  .srst_i ( srst_i_tb ),

  .ast_data_i          ( ast_snk_if.data    ),
  .ast_startofpacket_i ( ast_snk_if.sop     ),
  .ast_endofpacket_i   ( ast_snk_if.eop     ),
  .ast_valid_i         ( ast_snk_if.valid   ),
  .ast_empty_i         ( ast_snk_if.empty   ),
  .ast_channel_i       ( ast_snk_if.channel ),
  .ast_ready_o         ( ast_snk_if.ready   ),

  .ast_data_o          ( ast_src_if.data    ),
  .ast_startofpacket_o ( ast_src_if.sop     ),
  .ast_endofpacket_o   ( ast_src_if.eop     ),
  .ast_valid_o         ( ast_src_if.valid   ),
  .ast_empty_o         ( ast_src_if.empty   ),
  .ast_channel_o       ( ast_src_if.channel ),
  .ast_ready_i         ( ast_src_if.ready   )
);

//Declare object
ast_class # (
  .DATA_W      ( DATA_IN_W_TB   ),
  .CHANNEL_W   ( CHANNEL_W_TB   ),
  .EMPTY_OUT_W ( EMPTY_OUT_W_TB )
) ast_send_pkt;

ast_class # (
  .DATA_W      ( DATA_OUT_W_TB  ),
  .CHANNEL_W   ( CHANNEL_W_TB   ),
  .EMPTY_OUT_W ( EMPTY_OUT_W_TB )
) ast_receive_pkt;

typedef logic [DATA_OUT_W_TB-1:0] pkt_receive_t [$];


task assert_ready_1clk();

@( posedge clk_i_tb )

ast_src_if.ready <= 1'b1;

endtask

task deassert_ready_1clk();

@( posedge clk_i_tb )

ast_src_if.ready <= 1'b0;
endtask


task assert_ready();

int random_assert;
int random_deassert;

forever
  begin
    random_assert   = $urandom_range( min_assert, max_assert );
    random_deassert = $urandom_range( min_deassert, max_deassert );
    repeat( random_assert )
      assert_ready_1clk();
    repeat( random_deassert )
      deassert_ready_1clk();
  end
endtask

task set_assert_range( input int _min_assert, _max_assert,
                             int _min_deassert, _max_deassert
                     );

min_assert   = _min_assert;
max_assert   = _max_assert;
min_deassert = _min_deassert;
max_deassert = _max_deassert;

endtask

task test_data( pkt_t _pkt_send,
                pkt_t _pkt_receive
              );

int size_pkt_send;
int size_pkt_receive;

logic [7:0] byte_send;
logic [7:0] byte_receive;
bit data_err;

size_pkt_send    = _pkt_send.size();
size_pkt_receive = _pkt_receive.size();

if( size_pkt_send != size_pkt_receive )
  $display("Packet size mismatch: send: %0d, receive: %0d", size_pkt_send, size_pkt_receive );
else
  begin
    for( int i = 0; i < size_pkt_send; i++ )
      begin
        if( _pkt_send[i] != _pkt_receive[i] )
          begin
            $display("Data error: Byte %0d error\nsend: %x, receive: %x", i, _pkt_send[i], _pkt_send[i] );
            data_err = 1'b1;
          end
      end
    if( data_err == 1'b0 )
      $display("Data correct!!!");
  end

endtask


task reset();

srst_i_tb <= 1'b1;
@( posedge clk_i_tb );
srst_i_tb <= 1'b0;

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

pkt_t                    pkt_send;
pkt_t                    pkt_receive;
logic [CHANNEL_W_TB-1:0] tx_channel;
logic [CHANNEL_W_TB-1:0] rx_channel;

task check_data_received();

if( ast_receive_pkt.tx_fifo.num() != 0 )
  begin
    ast_receive_pkt.tx_fifo.get( pkt_receive );
    test_data( pkt_send, pkt_receive );
  end
else
  $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

endtask

task check_tx_channel();

if( ast_receive_pkt.tx_fifo_channel.num() != 0 )
  begin
    ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    if( tx_channel != rx_channel )
      $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    else
      $display("Channel correct!!!");
  end
else
  $display("tx_channel error because of 'sop' error");

endtask

initial
  begin
    
    ast_src_if.ready <= 1'b1;
    srst_i_tb        <= 1'b1; 
    @( posedge clk_i_tb );
    srst_i_tb        <= 1'b0;
    
    // // // **********************TEST CASE 1*************************
    ast_send_pkt    = new( ast_snk_if );
    ast_receive_pkt = new( ast_src_if );
    set_assert_range( 2*(WORD_OUT*4)/8+5,2*(WORD_OUT*4)/8+5,0,0 );

    $display("TEST CASE 1: Number of bytes = [WORD_OUT*k] = 32 * 4 = 128");

    pkt_send   = gen_1_pkt( 128 );
    rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );

    fork
      ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
      ast_receive_pkt.receive_pkt();
      assert_ready();
    join_any

    check_tx_channel();
    check_data_received();
    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());
    
    $display("\n");

    // // // // **********************TEST CASE 2*************************
    // // // // Use reset to make it easier to see when a new packet is sent
    reset();
    pkt_send   = gen_1_pkt( 132 );
    rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );

    set_assert_range( 2*(132)/8+5,2*(132)/8+5,0,0 );

    $display("TEST CASE 2: Number of bytes = [WORD_OUT*k + N] = 32*4 + 4 = 132");

    ast_send_pkt.send_pkt( pkt_send, rx_channel, 1 );

    check_tx_channel();
    check_data_received();

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    $display("\n");

    // // // // **********************TEST CASE 3*************************
    reset();
    pkt_send   = gen_1_pkt( WORD_IN );
    rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    
    set_assert_range( 2*(WORD_IN)/8+5,2*(WORD_IN)/8+5,0,0 );

    $display("TEST CASE 3: Number of bytes = [WORD_IN] = 8");

    ast_send_pkt.send_pkt( pkt_send, rx_channel, 1 );

    check_tx_channel();
    check_data_received();

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());
    
    $display("\n");
  
    // // // // // **********************TEST CASE 4*************************
    reset();

    pkt_send   = gen_1_pkt( WORD_IN*1+5 );
    rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );

    set_assert_range( 1,3,1,3 );
    $display("TEST CASE 4: Number of bytes = [WORD_IN*k + N (k <8)] = 8*1 + 5 = 13");

    ast_send_pkt.send_pkt( pkt_send, rx_channel, 1 );

    check_tx_channel();
    check_data_received();
 
    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    $display("\n");
  
    // // // // **********************TEST CASE 5*************************
    reset();
    pkt_send   = gen_1_pkt( WORD_OUT*1 );
    rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    set_assert_range( 2*(WORD_OUT*1)/8+5,2*(WORD_OUT*1)/8+5,0,0 );

    $display("TEST CASE 5: Number of bytes = [WORD_OUT*k] = 32*1 = 32");

    ast_send_pkt.send_pkt( pkt_send, rx_chann el, 3 );

    check_tx_channel();
    check_data_received();

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    $display("\n");

  
    // // // // // **********************TEST CASE 6*************************
    // reset();

    // pkt_send   = gen_1_pkt( WORD_IN - 6 );
    // rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    
    // set_assert_range( 2*(WORD_IN - 6)/8+5,2*(WORD_IN - 6)/8+5,0,0 );

    // $display("TEST CASE 6: Number of bytes = [WORD_IN - k (0 < k < 8)] = 8 - 6 = 2");

    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());
    
    // $display("\n");

    // // // // // **********************TEST CASE 7*************************
    // reset();
    // pkt_send   = gen_1_pkt( WORD_IN*3 );
    // rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    // set_assert_range( 2*(WORD_IN*3)/8+5,2*(WORD_IN*3)/8+5,0,0 );

    // $display("TEST CASE 7: Number of bytes = [WORD_IN*k(k > 1)] = 8*3");

    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    // $display("\n");   

    // // // // // **********************TEST CASE 8*************************
    // reset();
    // pkt_send   = gen_1_pkt( 1 );
    // rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    // set_assert_range( 4,4,0,0 );

    // $display("TEST CASE 8: Number of bytes = 1 ");

    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    // $display("\n");  

    // // // // // **********************TEST CASE 9*************************
    // reset();
    // pkt_send   = gen_1_pkt( WORD_IN*3 );
    // rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );
    
    // set_assert_range( 1,3,1,3 );

    // $display("TEST CASE 9 : Send multiple packets ( random ready, only 1 word output )");

    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    // $display("\n");
  
    // // // // // **********************TEST CASE 10*************************
    // reset();
    // pkt_send   = gen_1_pkt( WORD_OUT*3+2 );
    // rx_channel = $urandom_range( 2**CHANNEL_W_TB,0 );

    // set_assert_range( 1,3,1,3 );

    // $display("TEST CASE 10 : Send multiple packets ( random ready, 4 words output )");

    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );
    // ast_send_pkt.send_pkt( pkt_send, rx_channel, 3 );

    // ast_receive_pkt.tx_fifo_channel.get( tx_channel );
    // if( tx_channel != rx_channel )
    //   $display("Channel error, send: channel %0d, received: channel %0d",rx_channel, tx_channel );
    // else
    //   $display("Channel correct!!!");

    // if( ast_receive_pkt.tx_fifo.num() != 0 )
    //   begin
    //     ast_receive_pkt.tx_fifo.get( pkt_receive );
    //     test_data( pkt_send, pkt_receive );
    //   end
    // else
    //   $display("Sended: %0d bytes, No data received!!!", pkt_send.size());

    // $display("\n");

  
    $display("Test done!!");
    $stop();

  end

endmodule