import avl_st_pkg::*;

module ast_width_extender_tb;

parameter DATA_IN_W_TB   = 64;
parameter DATA_OUT_W_TB  = 256;
parameter CHANNEL_W_TB   = 10;
parameter EMPTY_IN_W_TB  = $clog2(DATA_IN_W_TB/8) ?  $clog2(DATA_IN_W_TB/8) : 1;
parameter EMPTY_OUT_W_TB = $clog2(DATA_OUT_W_TB/8) ?  $clog2(DATA_OUT_W_TB/8) : 1;

parameter MAX_PK = 5;

bit                          clk_i_tb;
logic                        srst_i_tb;

logic [DATA_IN_W_TB-1:0]     ast_data_i_tb;
logic                        ast_startofpacket_i_tb;
logic                        ast_endofpacket_i_tb;
logic                        ast_valid_i_tb;
logic [EMPTY_IN_W_TB-1:0]    ast_empty_i_tb;
logic [CHANNEL_W_TB-1:0]     ast_channel_i_tb;
logic                        ast_ready_o_tb;

logic [DATA_OUT_W_TB-1:0]    ast_data_o_tb;
logic                        ast_startofpacket_o_tb;
logic                        ast_endofpacket_o_tb;
logic                        ast_valid_o_tb;
logic [EMPTY_OUT_W_TB-1:0]   ast_empty_o_tb;
logic [CHANNEL_W_TB-1:0]     ast_channel_o_tb;
logic                        ast_ready_i_tb;

bit send_done;

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
  .DATA_W ( DATA_OUT_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB )
) ast_src_if (
  .clk( clk_i_tb )
);

ast_width_extender #(
  .DATA_IN_W   ( DATA_IN_W_TB ),
  .EMPTY_IN_W  ( EMPTY_IN_W_TB ),
  .CHANNEL_W   ( CHANNEL_W_TB ),
  .DATA_OUT_W  ( DATA_OUT_W_TB ),
  .EMPTY_OUT_W ( EMPTY_OUT_W_TB )
) dut (
  .clk_i ( clk_i_tb ),
  .srst_i( srst_i_tb ),

  .ast_data_i( ast_snk_if.data ),
  .ast_startofpacket_i( ast_snk_if.sop ),
  .ast_endofpacket_i( ast_snk_if.eop ),
  .ast_valid_i( ast_snk_if.valid ),
  .ast_empty_i( ast_snk_if.empty ),
  .ast_channel_i( ast_snk_if.channel ),
  .ast_ready_o( ast_snk_if.ready ),

  .ast_data_o( ast_src_if.data ),
  .ast_startofpacket_o( ast_src_if.sop ),
  .ast_endofpacket_o( ast_src_if.eop ),
  .ast_valid_o( ast_src_if.valid ),
  .ast_empty_o( ast_src_if.empty ),
  .ast_channel_o( ast_src_if.channel ),
  .ast_ready_i( ast_src_if.ready )
);

//Declare object
ast_class # (
  .DATA_W ( DATA_IN_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB ),
  .MAX_PK( MAX_PK )
) ast_send_pk;

ast_class # (
  .DATA_W ( DATA_OUT_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB ),
  .MAX_PK( MAX_PK )
) ast_receive_pk;

mailbox #( pkt_t ) send_packet = new();
mailbox #( pkt_receive_t ) receive_packet = new();

task gen_pk( mailbox #( pkt_t ) _send_packet,
             input int _min_word,
                   int _max_word
           );

pkt_t new_pk;
logic [7:0] new_data;
int random_byte;
int word_number;

for( int i = 0; i < MAX_PK; i++ )
  begin
    random_byte = $urandom_range( 8*_min_word+1,8*_max_word+7 ); //Send 1 word and some bytes
    for( int j = 0; j < random_byte; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk.push_back( new_data );
        $display("byte: %x", new_data);
      end
    _send_packet.put( new_pk );
    $display("\n");
    new_pk = {};
  end

endtask

task assert_ready_signal_1clk();

@( posedge clk_i_tb )
ast_src_if.ready <= 1'b1;

endtask

task deassert_ready_signal_1clk();

@( posedge clk_i_tb )
ast_src_if.ready <= 1'b0;

endtask

task assert_ready();

repeat(100)
  assert_ready_signal_1clk();
endtask

task deassert_ready();

repeat(100)
  deassert_ready_signal_1clk();
endtask

task show_receive_pk( mailbox #( pkt_receive_t ) _receive_packet );

pkt_receive_t new_pk_receive;

logic [DATA_OUT_W_TB-1:0] data_receive;

while( _receive_packet.num() != 0 )
  begin
    _receive_packet.get( new_pk_receive );
    for( int i = 0; i < new_pk_receive.size(); i++ )
        begin
        //   data_receive = new_pk_receive.pop_front();
          $display( "receive: %x", new_pk_receive[i] );
        end
    new_pk_receive = {};
  end

endtask

initial
  begin
    srst_i_tb <= 1'b1;
    ##1;
    srst_i_tb <= 1'b0;

    gen_pk( send_packet, 16,16 );
    ast_send_pk    = new( ast_snk_if, send_packet, receive_packet );
    ast_receive_pk = new( ast_src_if, send_packet, receive_packet );
    fork
      ast_send_pk.send_pk();
      ast_receive_pk.reveive_pk();
      assert_ready();
    join
    $display("\n");
    show_receive_pk( receive_packet );

    $display("Test done!!");
    $stop();

  end

endmodule