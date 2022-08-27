import ast_dmx_pkg::*;

module ast_dmx_tb;

parameter int DATA_WIDTH_TB     = 64;
parameter int CHANNEL_WIDTH_TB  = 8;
parameter int EMPTY_WIDTH_TB    = $clog2( DATA_WIDTH_TB / 8 );
parameter int TX_DIR_TB         = 4;

parameter int DIR_SEL_WIDTH_TB = TX_DIR_TB == 1 ? 1 : $clog2( TX_DIR_TB );

parameter MAX_PKT = 1;

parameter WORD_IN  = DATA_WIDTH_TB/8;
parameter WORD_OUT = WORD_IN;

bit                          clk_i_tb;
logic                        srst_i_tb;
logic [DIR_SEL_WIDTH_TB-1:0] dir_i_tb;

genvar i;

logic [DATA_WIDTH_TB-1:0]    ast_data_o_tb          [TX_DIR_TB-1:0];
logic                        ast_startofpacket_o_tb [TX_DIR_TB-1:0];
logic                        ast_endofpacket_o_tb   [TX_DIR_TB-1:0];
logic                        ast_valid_o_tb         [TX_DIR_TB-1:0];
logic [EMPTY_WIDTH_TB-1:0]   ast_empty_o_tb         [TX_DIR_TB-1:0];
logic [CHANNEL_WIDTH_TB-1:0] ast_channel_o_tb       [TX_DIR_TB-1:0];
logic                        ast_ready_i_tb         [TX_DIR_TB-1:0];

int min_assert;
int max_assert;
int min_deassert;
int max_deassert;

bit rand_dir;
int dir_select;

logic [DIR_SEL_WIDTH_TB-1:0] dir_tmp;

initial
  forever
    #5 clk_i_tb = !clk_i_tb;

default clocking cb
  @( posedge clk_i_tb );
endclocking

avalon_st_if #(
  .DATA_WIDTH    ( DATA_WIDTH_TB    ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH   ( EMPTY_WIDTH_TB   )
) ast_snk_if (
  .clk ( clk_i_tb )
);

avalon_st_if #(
  .DATA_WIDTH    ( DATA_WIDTH_TB    ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH   ( EMPTY_WIDTH_TB   )
) ast_src_if [TX_DIR_TB-1:0] (
  .clk ( clk_i_tb )
);


ast_dmx_c #(
  .DATA_W     ( DATA_WIDTH_TB    ),
  .CHANNEL_W  ( CHANNEL_WIDTH_TB ),
  .EMPTY_W    ( EMPTY_WIDTH_TB   )
) ast_send_pkt;

ast_dmx_c #(
  .DATA_W    ( DATA_WIDTH_TB    ),
  .CHANNEL_W ( CHANNEL_WIDTH_TB ),
  .EMPTY_W   ( EMPTY_WIDTH_TB   )
) ast_receive_pkt[TX_DIR_TB-1:0];

ast_dmx #(
  .DATA_WIDTH    ( DATA_WIDTH_TB    ),
  .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
  .EMPTY_WIDTH   ( EMPTY_WIDTH_TB   ),

  .TX_DIR        ( TX_DIR_TB ),
  .DIR_SEL_WIDTH ( DIR_SEL_WIDTH_TB )
) dut (
  .clk_i  ( clk_i_tb  ),
  .srst_i ( srst_i_tb ),

  .dir_i  ( dir_i_tb  ),

  .ast_data_i          ( ast_snk_if.data    ),
  .ast_startofpacket_i ( ast_snk_if.sop     ),
  .ast_endofpacket_i   ( ast_snk_if.eop     ),
  .ast_valid_i         ( ast_snk_if.valid   ),
  .ast_empty_i         ( ast_snk_if.empty   ),
  .ast_channel_i       ( ast_snk_if.channel ) ,
  .ast_ready_o         ( ast_snk_if.ready   ),

  .ast_data_o          ( ast_data_o_tb          ),
  .ast_startofpacket_o ( ast_startofpacket_o_tb ),
  .ast_endofpacket_o   ( ast_endofpacket_o_tb   ),
  .ast_valid_o         ( ast_valid_o_tb         ),
  .ast_empty_o         ( ast_empty_o_tb         ),
  .ast_channel_o       ( ast_channel_o_tb       ),
  .ast_ready_i         ( ast_ready_i_tb         )
);

typedef logic [DATA_WIDTH_TB-1:0] pkt_word_t [$];

mailbox #( pkt_t )      fifo_pkt_byte = new();
mailbox #( pkt_word_t ) fifo_pkt_word = new();


generate
  for( i = 0; i < TX_DIR_TB; i++ )
    begin
      assign ast_src_if[i].data    = ast_data_o_tb[i];
      assign ast_src_if[i].sop     = ast_startofpacket_o_tb[i];
      assign ast_src_if[i].eop     = ast_endofpacket_o_tb[i];
      assign ast_src_if[i].valid   = ast_valid_o_tb[i];
      assign ast_src_if[i].empty   = ast_empty_o_tb[i];
      assign ast_src_if[i].channel = ast_channel_o_tb[i];
      assign ast_src_if[i].ready   = ast_ready_i_tb[i];
    end
endgenerate


task assert_ready_1clk();

@( posedge clk_i_tb )

for( int i = 0; i < TX_DIR_TB; i++ )
  ast_ready_i_tb[i] <= 1'b1;

endtask

task deassert_ready_1clk();

@( posedge clk_i_tb )
for( int i = 0; i < TX_DIR_TB; i++ )
  ast_ready_i_tb[i] <= 1'b0;
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

task dir_setting( input bit _rand_dir, int _dir_select );

rand_dir   = _rand_dir;
dir_select = _dir_select;

endtask

task gen_dir();

forever
  begin
    @( posedge clk_i_tb );
    if( rand_dir == 1'b1 )
      dir_i_tb <= $urandom_range(TX_DIR_TB-1,0);
    else
      dir_i_tb <= dir_select;

  end

endtask

task reset();

srst_i_tb <= 1'b1;
@( posedge clk_i_tb )
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

task tx_dir();
forever
  begin
    @( posedge clk_i_tb );
    if( ast_snk_if.sop == 1'b1 && ast_snk_if.valid == 1'b1 )
      dir_tmp = dir_i_tb;
  end

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

task test_dir_tx_pkt();

for( int i = 0; i < TX_DIR_TB; i++ )
  begin
    if( ast_receive_pkt[i].tx_fifo.num() != 0 )
      begin
        if( i == dir_tmp )
          begin
            while( ast_receive_pkt[i].tx_fifo.num() != 0 )
              begin
                ast_receive_pkt[i].tx_fifo.get( pkt_receive );
                $display( "------tx dir: %0d------", i );
                test_data( pkt_send, pkt_receive );
              end
          end
        else
          $display( "data should be sended via dir  %0d, not dir %0d", dir_tmp, i );   
      end
    else
      begin
        if( i == dir_tmp )
          $display( "------tx dir: %0d------ \nNo packet received", i );
      end
  end
// $display("\n");

endtask

pkt_t                        pkt_send;
pkt_t                        pkt_receive;
logic [CHANNEL_WIDTH_TB-1:0] tx_channel;
logic [CHANNEL_WIDTH_TB-1:0] rx_channel;

initial
  begin
    for( int i = 0; i < TX_DIR_TB; i++ )
      ast_ready_i_tb[i] <= 1'b1;
    dir_i_tb  <= $urandom_range(TX_DIR_TB-1, 0);

    srst_i_tb <= 1'b1;
    @( posedge clk_i_tb )
    srst_i_tb <= 1'b0;

    // // // ********************Test case 1********************
    $display("TEST 1: [Random 'dir_i' -- 5 packet ( 70 bytes/packet ) --  Random 'ready']");
    ast_send_pkt       = new( ast_snk_if );
    ast_receive_pkt[0] = new( ast_src_if[0] );
    ast_receive_pkt[1] = new( ast_src_if[1] );
    ast_receive_pkt[2] = new( ast_src_if[2] );
    ast_receive_pkt[3] = new( ast_src_if[3] );

    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    fork
      ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
      ast_receive_pkt[0].receive_pkt();
      ast_receive_pkt[1].receive_pkt();
      ast_receive_pkt[2].receive_pkt();
      ast_receive_pkt[3].receive_pkt();
      assert_ready();
      gen_dir();
      tx_dir();
    join_any

    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n"); 

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    // // // // ********************Test case 2********************
    reset();
    $display("TEST 2: [dir_i = 3 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");

    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 0,3 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    // // // // ********************Test case 3********************
    reset();
    $display("TEST 3: [dir_i = 2 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");

    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 0,2 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    // // // // ********************Test case 4********************
    reset();
    $display("TEST 4: [dir_i = 1 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");

    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 0,1 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt(); 
    $display("\n");

    // // // // ********************Test case 5********************
    reset();
    $display("TEST 5: [dir_i = 0 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");

    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 0,0 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();  
    $display("\n");


    // // // // ********************Test case 6********************
    reset();
    $display("TEST 6: Test data: Number of byte = 8k \n[dir_i = 3 -- 5 packet ( 64 bytes/packet ) -- random 'ready']");
    set_assert_range( 1,3,1,3 ); 
    pkt_send   = gen_1_pkt( 64 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 0,3 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();  
    $display("\n");

    // // // // ********************Test case 7********************
    reset();
    $display("TEST 7: Test data: Number of bytes < 8 bytes \n[random dir_i -- 5 packet ( 6 bytes/packet ) -- random 'ready']");
    pkt_send   = gen_1_pkt( 6 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();  
    $display("\n");


    // // // // ********************Test case 8********************
    reset();
    $display("TEST 8: Test data: number of byte = 8 bytes \n[random dir_i -- 5 packet ( 8 bytes/packet ) -- random 'ready']");
    pkt_send   = gen_1_pkt( 8 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();  
    $display("\n");
 
    // // // // ********************Test case 9********************
    reset();
    $display("TEST 9: Test data: number of byte = 9 bytes \n[random dir_i -- 5 packet ( 9 bytes/packet ) -- random 'ready']");
    pkt_send   = gen_1_pkt( 9 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();  
    $display("\n");


    // // // // ********************Test case 10********************
    reset();
    $display("TEST 10: [RANDOM dir_i -- 5 packet ( 70 bytes/packet ) -- ready = 1]");
    pkt_send   = gen_1_pkt( 70 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 100,100,0,0 );
    dir_setting( 1,100 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");


    // // // // ********************Test case 11********************
    reset();
    $display("TEST 11: [RANDOM dir_i -- 5 packet ( 1 bytes/packet ) -- ready = 1]");
    pkt_send   = gen_1_pkt( 1 );
    rx_channel = $urandom_range( 2**CHANNEL_WIDTH_TB,0 );

    set_assert_range( 100,100,0,0 );
    dir_setting( 1,100 );

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    ast_send_pkt.send_pkt( pkt_send , rx_channel, 1 );
    test_dir_tx_pkt();
    $display("\n");

    $display("Test done!!!");
    $stop();


  end


endmodule