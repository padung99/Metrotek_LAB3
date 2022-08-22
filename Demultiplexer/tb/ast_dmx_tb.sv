import ast_dmx_pkg::*;

module ast_dmx_tb;

parameter int DATA_WIDTH_TB     = 64;
parameter int CHANNEL_WIDTH_TB  = 8;
parameter int EMPTY_WIDTH_TB    = $clog2( DATA_WIDTH_TB / 8 );
parameter int TX_DIR_TB         = 4;

parameter int DIR_SEL_WIDTH_TB = TX_DIR_TB == 1 ? 1 : $clog2( TX_DIR_TB );

parameter MAX_PK = 5;

parameter WORD_IN = DATA_WIDTH_TB/8;

bit clk_i_tb;
logic srst_i_tb;
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
  .DATA_W    ( DATA_WIDTH_TB    ),
  .CHANNEL_W ( CHANNEL_WIDTH_TB ),
  .EMPTY_W   ( EMPTY_WIDTH_TB   ),
  .TX_DIR    ( TX_DIR_TB        ),
  .MAX_PK    ( MAX_PK           )
) ast_send_pk;

ast_dmx_c #(
  .DATA_W    ( DATA_WIDTH_TB    ),
  .CHANNEL_W ( CHANNEL_WIDTH_TB ),
  .EMPTY_W   ( EMPTY_WIDTH_TB   ),
  .TX_DIR    ( TX_DIR_TB        ),
  .MAX_PK    ( MAX_PK           )
) ast_receive_pk;

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

mailbox #( pkt_t )      fifo_packet_byte = new();
mailbox #( pkt_word_t ) fifo_packet_word = new();

task gen_pk( mailbox #( pkt_t )      _fifo_packet_byte,
             mailbox #( pkt_word_t ) _fifo_packet_word,
             input int _min_byte,
                   int _max_byte
           );

pkt_t new_pk;
logic [7:0] new_data;
int random_byte;
int word_number;

logic [DATA_WIDTH_TB-1:0] word_data[$];

int int_part;
int mod_part;
int word_byte;

int byte_last_word;

logic [DATA_WIDTH_TB-1:0] tmp_data;

for( int i = 0; i < MAX_PK; i++ )
  begin
    random_byte = $urandom_range( _min_byte,_max_byte );
    // $display("PACKET %0d", i);
    int_part  = random_byte / 8;
    mod_part  = random_byte % 8;
    word_byte = ( mod_part == 0 ) ? int_part : int_part + 1;
    // $display("word_byte: %0d", word_byte);
    for( int j = 0; j < (word_byte-1)*8; j++ )
      begin
        new_data  = $urandom_range( 2**8,0 );
        new_pk[j] = new_data;
      end
    word_data = {<<8{new_pk}}; //packing byte to word
    for( int j = (word_byte-1)*8; j < random_byte; j++ )
      begin
        new_data  = $urandom_range( 2**8,0 );
        new_pk[j] = new_data;
      end

    for( int j = random_byte -1; j >= WORD_IN*(word_byte-1); j-- )
      begin
        word_data[word_byte-1][7:0] = new_pk[j];
        // $display("word_data[%0d][7:0] %0x",word_byte-1, word_data[word_byte-1] );
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

    // for( int i = 0; i < word_byte; i++ )
    //   $display("word: %x", word_data[i]);

    _fifo_packet_word.put( word_data );
    _fifo_packet_byte.put( new_pk );
    word_data = {};
    new_pk    = {};
    // $display("\n");
  end

endtask

task compare_output();

pkt_word_t new_pk_word;
logic [DATA_WIDTH_TB-1:0] new_word;
int j;

int mb_size;
int pk_size;
logic [DIR_SEL_WIDTH_TB-1:0] dir_tmp;
int size_mb;
mb_size = fifo_packet_word.num();
forever
  begin
    @( posedge clk_i_tb );
    while( fifo_packet_word.num() != 0 )
      begin
        size_mb = fifo_packet_word.num();
        $display("*****PACKET %0d*****", mb_size - fifo_packet_word.num() );
        fifo_packet_word.get( new_pk_word );
        pk_size = new_pk_word.size();
        $display("pk_size: %0d words", pk_size);
        j = 0;
        while( j < pk_size )
          begin
            if( ast_snk_if.sop == 1'b1 && ast_snk_if.valid == 1'b1 )
              dir_tmp = dir_i_tb;
            for( int i = 0; i < TX_DIR_TB; i++ )
              begin
                if( i == dir_tmp )
                  begin
                    if( ast_valid_o_tb[i] == 1'b1 )
                      begin
                        new_word = new_pk_word[j];
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

min_assert = _min_assert;
max_assert = _max_assert;
min_deassert = _min_deassert;
max_deassert = _max_deassert;

endtask

task dir_setting( input bit _rand_dir, int _dir_select );

rand_dir = _rand_dir;
dir_select = _dir_select;

endtask

task gen_dir();

forever
  begin
    @( posedge clk_i_tb );
    if( ast_snk_if.sop == 1'b1 && ast_snk_if.valid == 1'b1 )
      begin
        if( rand_dir == 1'b1 )
          dir_i_tb <= $urandom_range(TX_DIR_TB-1,0);
        else
          dir_i_tb <= dir_select;
      end
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
    $display("[Random 'dir_i' -- 5 packet ( 70 bytes/packet ) --  Random 'ready']");
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    set_assert_range( 1,3,1,3 );
    dir_setting( 1,100 );

    ast_send_pk = new( ast_snk_if, fifo_packet_byte );
    fork
      ast_send_pk.send_pk( 3 );
      assert_ready();
      gen_dir();
      compare_output();
    join_any

    // // // ********************Test case 2********************
    dir_setting( 0,3 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("[dir_i = 3 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 3********************
    dir_setting( 0,2 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("[dir_i = 2 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 4********************
    dir_setting( 0, 1 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("[dir_i = 1 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 5********************
    dir_setting( 0, 0 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("[dir_i = 0 -- 5 packet ( 70 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 6********************
    dir_setting( 0, 3 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("Test data: Number of byte = 8k \n[dir_i = 3 -- 5 packet ( 64 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 64, 64 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 7********************
    dir_setting( 1,100  );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("Test data: Number of bytes < 8 bytes \n[random dir_i -- 5 packet ( 6 bytes/packet ) -- random 'ready']");
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 6, 6 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 8********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("Test data: number of byte = 8 bytes \n[random dir_i -- 5 packet ( 8 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case when number of bytes in packet = 1 word (8 bytes)
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 8, 8 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 9********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("Test data: number of byte = 9 bytes \n[random dir_i -- 5 packet ( 9 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case
    // // when number of bytes in packet = 9 bytes (2 words) = 1 word + 1 byte 
    fifo_packet_byte = new();
    gen_pk ( fifo_packet_byte, fifo_packet_word, 9, 9 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 10********************
    fifo_packet_byte = new();
    fifo_packet_word = new();

    // dir_i_tb  <= $urandom_range(TX_DIR_TB-1, 0);
    dir_setting( 1, 100 );
    set_assert_range( 150,150,0,0 );
    reset();
      
    $display("[RANDOM dir_i -- 5 packet ( 70 bytes/packet ) -- ready = 1]");
    gen_pk ( fifo_packet_byte, fifo_packet_word, 70, 70 );
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );


    ast_send_pk.send_pk( 3 );

    // // // ********************Test case 11********************
    dir_setting( 1, 100 );
    set_assert_range( 1,3,1,3 );
    reset();
    
    $display("Test data: number of byte = 1 bytes \n[random dir_i -- 5 packet ( 9 bytes/packet ) -- random 'ready']");
    // // This test is used to test corner case
    // // when number of bytes in packet = 1 bytes ( 1 word only )
    fifo_packet_byte = new();

    gen_pk ( fifo_packet_byte, fifo_packet_word, 1, 1 );
    
    ast_send_pk = new( ast_snk_if, fifo_packet_byte );

    ast_send_pk.send_pk( 3 );

    // // // Test 12: byte = 830 ?????????? TB error, not rtl error
    // gen_pk ( fifo_packet_byte, fifo_packet_word, 800, 800 ); 

    // ast_send_pk = new( ast_snk_if, fifo_packet_byte );
    // fork
    //   ast_send_pk.send_pk( 3 );
    //   assert_ready( 1,3, 1,3 );
    //   gen_dir(0, 3);
    //   compare_output( fifo_packet_word );
    // join_any

    $stop();


  end


endmodule