import ast_dmx_pkg::*;

module ast_dmx_tb;

parameter int DATA_WIDTH_TB     = 64;
parameter int CHANNEL_WIDTH_TB  = 8;
parameter int EMPTY_WIDTH_TB    = $clog2( DATA_WIDTH_TB / 8 );
parameter int TX_DIR_TB         = 4;

parameter int DIR_SEL_WIDTH_TB = TX_DIR_TB == 1 ? 1 : $clog2( TX_DIR_TB );

parameter MAX_PKT = 5;

parameter WORD_IN = DATA_WIDTH_TB/8;

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
) ast_receive_pkt;

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

task gen_pkt( mailbox #( pkt_t )      _fifo_pkt_byte,
              mailbox #( pkt_word_t ) _fifo_pkt_word,
              input int _min_byte,
                    int _max_byte
           );

pkt_t       new_pkt;
logic [7:0] new_data;
int         random_byte;
int         word_number;

logic [DATA_WIDTH_TB-1:0] word_data[$];

int int_part;
int mod_part;
int word_byte;

int byte_last_word;

logic [DATA_WIDTH_TB-1:0] tmp_data;

for( int i = 0; i < MAX_PKT; i++ )
  begin
    random_byte = $urandom_range( _min_byte,_max_byte );

    int_part  = random_byte / 8;
    mod_part  = random_byte % 8;
    word_byte = ( mod_part == 0 ) ? int_part : int_part + 1;

    for( int j = 0; j < (word_byte-1)*8; j++ )
      begin
        new_data   = $urandom_range( 2**8,0 );
        new_pkt[j] = new_data;
      end
    word_data = {<<8{new_pkt}}; //packing byte to word
    for( int j = (word_byte-1)*8; j < random_byte; j++ )
      begin
        new_data   = $urandom_range( 2**8,0 );
        new_pkt[j] = new_data;
      end

    for( int j = random_byte -1; j >= WORD_IN*(word_byte-1); j-- )
      begin
        word_data[word_byte-1][7:0] = new_pkt[j];
        
        if( j != WORD_IN*(word_byte-1) )
          word_data[word_byte-1] = word_data[word_byte-1] << 8;
      end
      byte_last_word = random_byte - WORD_IN*(word_byte-1);
    for( int k = DATA_WIDTH_TB-1; k >= byte_last_word*8; k--)
      word_data[word_byte-1][k] = 1'b0;

    if(  word_byte > 2 )
      for( int i = 0; i <= ( word_byte-2 )>>1; i++ )
        begin
          tmp_data                 = word_data[i];
          word_data[i]             = word_data[word_byte-2-i];
          word_data[word_byte-2-i] = tmp_data;
        end

    _fifo_pkt_word.put( word_data );
    _fifo_pkt_byte.put( new_pkt );
    word_data  = {};
    new_pkt    = {};
  end

endtask

task compare_output();

pkt_word_t new_pkt_word;
logic [DATA_WIDTH_TB-1:0] new_word;
int j;

int mb_size;
int pkt_size;

int size_mb;
mb_size = fifo_pkt_word.num();
forever
  begin
    @( posedge clk_i_tb );
    while( fifo_pkt_word.num() != 0 )
      begin
        size_mb = fifo_pkt_word.num();
        $display("*****PACKET %0d*****", mb_size - fifo_pkt_word.num() );
        fifo_pkt_word.get( new_pkt_word );
        pkt_size = new_pkt_word.size();
        $display("pkt_size: %0d words", pkt_size);
        j = 0;
        while( j < pkt_size )
          begin
            
            if( ast_snk_if.sop == 1'b1 && ast_snk_if.valid == 1'b1 )
              dir_tmp = dir_i_tb;

            for( int i = 0; i < TX_DIR_TB; i++ )
              begin
                if( i == dir_tmp )
                  begin
                    if( ast_valid_o_tb[i] == 1'b1 )
                      begin
                        new_word = new_pkt_word[j];
                        if( new_word == ast_data_o_tb[i] )
                          $display("dir %0d / word %0d -- No error ", i, j );
                        else
                          $display("dir %0d / word %0d -- error ###send: %x, receive: %x", i, j, new_word, ast_data_o_tb[i] );
                        j++;
                      end
                  end
                else
                  begin
                    if( ast_valid_o_tb[i] == 1'b1 )
                      begin
                        $display("Channel error: Data should be sended via channel %0d, not channel %0d ", dir_tmp, i);
                        j++;
                      end
                  end
              end
            @( posedge clk_i_tb );
          end
        $display("\n");
      end
  end

endtask

task test_channel();

forever
  begin
    @( posedge clk_i_tb );
    if( ast_valid_o_tb[dir_tmp] == 1'b1 &&  ast_startofpacket_o_tb[dir_tmp] == 1'b1 )
      begin
        if( ast_channel_o_tb[dir_tmp] != ast_snk_if.channel )
          $display("Channel error, send: %0d, receive: %0d", ast_snk_if.channel, ast_channel_o_tb[dir_tmp] );
      end
  end

endtask

task test_empty();

forever
  begin
    @( posedge clk_i_tb );
    if( ast_valid_o_tb[dir_tmp] == 1'b1 &&  ast_endofpacket_o_tb[dir_tmp] == 1'b1 )
      begin
        if( ast_empty_o_tb[dir_tmp] != ast_snk_if.empty )
          $display("Empty error, correct: %0d, receive: %0d", ast_empty_o_tb[dir_tmp], ast_snk_if.empty);
      end
  end
endtask

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
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );
    fork
      ast_send_pkt.send_pkt( 3 );
      assert_ready();
      gen_dir();
      compare_output();
      test_channel();
      test_empty();
    join_any

    // // // ********************Test case 2********************
    dir_setting( 0,3 );
    set_assert_range( 1,3,1,3 );
    reset();
    dir_tmp = 3;
    
    $display("TEST 2: [dir_i = 3 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 3********************
    dir_tmp = 2;
    dir_setting( 0,2 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("TEST 3: [dir_i = 2 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 4********************
    dir_tmp = 1;
    dir_setting( 0, 1 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("TEST 4: [dir_i = 1 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 5********************
    dir_tmp = 0;
    dir_setting( 0, 0 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("TEST 5: [dir_i = 0 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 6********************
    dir_tmp = 3;
    dir_setting( 0, 3 );
    set_assert_range( 1,3,1,3 );
    
    reset();
    
    $display("TEST 6: Test data: Number of byte = 8k \n[dir_i = 3 -- 5 packet ( 64 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 64, 64 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 7********************
    dir_setting( 1,100  );
    set_assert_range( 1,3,1,3 );
    reset();
    dir_tmp = 0;
    $display("TEST 7: Test data: Number of bytes < 8 bytes \n[random dir_i -- 5 packet ( 6 bytes/packet ) -- random 'ready']");
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 6, 6 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 8********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    dir_tmp = 0;
    $display("TEST 8: Test data: number of byte = 8 bytes \n[random dir_i -- 5 packet ( 8 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case
    // // when number of bytes in packet = 1 word (8 bytes)
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 8, 8 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 9********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    dir_tmp = 0;
    $display("TEST 9: Test data: number of byte = 9 bytes \n[random dir_i -- 5 packet ( 9 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case
    // // when number of bytes in packet = 9 bytes (2 words) = 1 word + 1 byte 
    fifo_pkt_byte = new();
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 9, 9 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 10********************
    fifo_pkt_byte = new();
    fifo_pkt_word = new();

    dir_setting( 1, 100 );
    set_assert_range( 150,150,0,0 );
    reset();
    dir_tmp = 0;  
    $display("TEST 10: [RANDOM dir_i -- 5 packet ( 70 bytes/packet ) -- ready = 1]");
    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 70, 70 );
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );


    ast_send_pkt.send_pkt( 3 );

    // // // ********************Test case 11********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    dir_tmp = 0;
    $display("TEST 11: Test data: number of byte = 1 bytes \n[random dir_i -- 5 packet ( 9 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case
    // // when number of bytes in packet = 1 bytes ( 1 word only )
    fifo_pkt_byte = new();

    gen_pkt ( fifo_pkt_byte, fifo_pkt_word, 1, 1 );
    
    ast_send_pkt = new( ast_snk_if, fifo_pkt_byte );

    ast_send_pkt.send_pkt( 3 );

    $stop();


  end


endmodule