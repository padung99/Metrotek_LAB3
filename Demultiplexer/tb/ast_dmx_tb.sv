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
logic [DIR_SEL_WIDTH_TB-1:0] dir_i_tb ;
genvar i;

logic [DATA_WIDTH_TB-1:0]    ast_data_o_tb          [TX_DIR_TB-1:0];
logic                        ast_startofpacket_o_tb [TX_DIR_TB-1:0];
logic                        ast_endofpacket_o_tb   [TX_DIR_TB-1:0];
logic                        ast_valid_o_tb         [TX_DIR_TB-1:0];
logic [EMPTY_WIDTH_TB-1:0]   ast_empty_o_tb         [TX_DIR_TB-1:0];
logic [CHANNEL_WIDTH_TB-1:0] ast_channel_o_tb       [TX_DIR_TB-1:0];
logic                        ast_ready_i_tb         [TX_DIR_TB-1:0];

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

mailbox #( pkt_t ) send_packet      = new();
mailbox #( pkt_t ) copy_send_packet = new();
mailbox #( logic [DATA_WIDTH_TB-1:0] ) packet_in_word = new();

task gen_pk( mailbox #( pkt_t ) _send_packet,
             mailbox #( pkt_t ) _copy_send_packet,
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
    $display("word_byte: %0d", word_byte);
    for( int j = 0; j < (word_byte-1)*8; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk[j] = new_data;
      end
    word_data = {<<8{new_pk}}; //packing byte to word
    for( int j = (word_byte-1)*8; j < random_byte; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk[j] = new_data;
      end

    for( int j = random_byte -1; j >= WORD_IN*(word_byte-1); j-- )
      begin
        word_data[word_byte-1][7:0] = new_pk[j];
        $display("word_data[%0d][7:0] %0x",word_byte-1, word_data[word_byte-1] );
        if( j != WORD_IN*(word_byte-1) )
          word_data[word_byte-1] = word_data[word_byte-1] << 8;
      end
      byte_last_word = random_byte - WORD_IN*(word_byte-1);
      for( int k = DATA_WIDTH_TB-1; k >= byte_last_word*8; k--)
        word_data[word_byte-1][k] = 1'b0;

      for( int i = 0; i <= word_byte-2; i++ )
        begin
          tmp_data     = word_data[i];
          word_data[i] = word_data[word_byte-2-i];
          word_data[word_byte-2-i] = tmp_data;
        end

      for( int i = 0; i < word_byte; i++ )
        $display("word: %x", word_data[i]);
    _send_packet.put( new_pk );
    _copy_send_packet.put( new_pk );
    new_pk = {};
    $display("\n");
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
// ast_src_if[0].ready <= 1'b0;
ast_ready_i_tb[1] <= 1'b1;
// ast_src_if[2].ready <= 1'b0;
// ast_src_if[3].ready <= 1'b0;
endtask

task deassert_ready_1clk();

@( posedge clk_i_tb )
// ast_src_if[0].ready <= 1'b0;
ast_ready_i_tb[1] <= 1'b0;
// ast_src_if[2].ready <= 1'b0;
// ast_src_if[3].ready <= 1'b0;
endtask


task assert_ready( input int _min_assert, int _max_assert,
                         int _min_deassert, int _max_deassert
                 );

int random_assert;
int random_deassert;

forever
  begin
    random_assert   = $urandom_range( _min_assert, _max_assert );
    random_deassert = $urandom_range( _min_deassert, _max_deassert );

    repeat( random_assert )
      assert_ready_1clk();
    repeat( random_deassert )
      deassert_ready_1clk();

  end
endtask

initial
  begin
    // ast_ready_i_tb[0] <= 1'b1;
    ast_ready_i_tb[1] <= 1'b1;
    // ast_ready_i_tb[2] <= 1'b1;
    // ast_ready_i_tb[3] <= 1'b1;
    dir_i_tb = 2'd1;
    srst_i_tb <= 1'b1;
    @( posedge clk_i_tb )
    srst_i_tb <= 1'b0;

    // @( posedge clk_i_tb );

    gen_pk ( send_packet, copy_send_packet, 88, 88 );

    ast_send_pk = new( ast_snk_if, send_packet );
    fork
      ast_send_pk.send_pk();
      assert_ready(1,3,1,3);
    join_any

    $stop();


  end


endmodule