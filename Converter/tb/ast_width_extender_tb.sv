import avl_st_pkg::*;

module ast_width_extender_tb;

parameter DATA_IN_W_TB   = 64;
parameter DATA_OUT_W_TB  = 256;
parameter CHANNEL_W_TB   = 10;
parameter EMPTY_IN_W_TB  = $clog2(DATA_IN_W_TB/8) ?  $clog2(DATA_IN_W_TB/8) : 1;
parameter EMPTY_OUT_W_TB = $clog2(DATA_OUT_W_TB/8) ?  $clog2(DATA_OUT_W_TB/8) : 1;

parameter WORD_OUT = (DATA_OUT_W_TB/8);

parameter MAX_PK = 5;

bit                          clk_i_tb;
logic                        srst_i_tb;

// logic [DATA_IN_W_TB-1:0]     ast_data_i_tb;
// logic                        ast_startofpacket_i_tb;
// logic                        ast_endofpacket_i_tb;
// logic                        ast_valid_i_tb;
// logic [EMPTY_IN_W_TB-1:0]    ast_empty_i_tb;
// logic [CHANNEL_W_TB-1:0]     ast_channel_i_tb;
// logic                        ast_ready_o_tb;

// logic [DATA_OUT_W_TB-1:0]    ast_data_o_tb;
// logic                        ast_startofpacket_o_tb;
// logic                        ast_endofpacket_o_tb;
// logic                        ast_valid_o_tb;
// logic [EMPTY_OUT_W_TB-1:0]   ast_empty_o_tb;
// logic [CHANNEL_W_TB-1:0]     ast_channel_o_tb;
// logic                        ast_ready_i_tb;

bit send_done;
int k;

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
  .DATA_W    ( DATA_IN_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB ),
  .EMPTY_OUT_W   ( EMPTY_OUT_W_TB ),
  .MAX_PK    ( MAX_PK       )
) ast_send_pk;

ast_class # (
  .DATA_W    ( DATA_OUT_W_TB ),
  .CHANNEL_W ( CHANNEL_W_TB  ),
  .EMPTY_OUT_W   ( EMPTY_OUT_W_TB ),
  .MAX_PK    ( MAX_PK        )
) ast_receive_pk;

mailbox #( pkt_t ) send_packet = new();
mailbox #( pkt_t ) copy_send_packet = new();
mailbox #( pkt_receive_t ) receive_packet = new();
mailbox #( pkt_receive_t ) test_receive_pk = new();

mailbox #( logic [CHANNEL_W_TB-1:0] ) channel_input = new();
mailbox #( logic [CHANNEL_W_TB-1:0] ) channel_output = new();

mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) empty_input = new();
mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) empty_output = new();

task gen_pk( mailbox #( pkt_t ) _send_packet,
             mailbox #( pkt_t ) _copy_send_packet,
             input int _min_byte,
                   int _max_byte
           );

pkt_t new_pk;
logic [7:0] new_data;
int random_byte;
int word_number;

for( int i = 0; i < MAX_PK; i++ )
  begin
    // random_byte = $urandom_range( 8*_min_word+1,8*_max_word+7 ); //Send 1 word and some bytes
    random_byte = $urandom_range( _min_byte,_max_byte );
    for( int j = 0; j < random_byte; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk.push_back( new_data );
        // $display("byte: %x", new_data);
      end
    _send_packet.put( new_pk );
    _copy_send_packet.put( new_pk );
    // $display("\n");
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

task as_deassert_valid();

repeat(50)
  begin
    repeat(8)
      assert_ready_signal_1clk();
    repeat(8)
      deassert_ready_signal_1clk();
  end

endtask


task output_word( mailbox #( pkt_t ) _send_packet,
                  mailbox #( pkt_receive_t ) _test_receive_pk,
                  mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) _empty_input
               );

pkt_receive_t new_pk_receive;
logic [DATA_OUT_W_TB-1:0] new_output_data;

pkt_t new_pk;
int last_byte_index;
int pk_size;
int word_number;
logic [EMPTY_OUT_W_TB-1:0] empty_byte;
logic [EMPTY_OUT_W_TB-1:0] byte_in_last_word;

while( _send_packet.num() != 0 )
  begin
    _send_packet.get( new_pk );
    pk_size = new_pk.size();
    word_number = (( pk_size % WORD_OUT ) == 0 )? pk_size/WORD_OUT : pk_size/WORD_OUT +1 ;
    
    byte_in_last_word = pk_size - ( pk_size/WORD_OUT )*WORD_OUT;
    empty_byte = (( pk_size % WORD_OUT ) == 0 ) ? 0 : (  WORD_OUT- byte_in_last_word );

    _empty_input.put( empty_byte );

    //0 -->last word-1
    for( int j = 0; j < word_number-1; j++ )
      begin
        new_output_data = (DATA_OUT_W_TB)'(0);

        for( k = WORD_OUT*j+WORD_OUT-1; k >= WORD_OUT*j; k-- )
          begin
            new_output_data[7:0] = new_pk[k];
            if( k != WORD_OUT*j )
              new_output_data = new_output_data << 8;
          end  
        new_pk_receive.insert( j, new_output_data );
        // $display("output: %x", new_pk_receive[j]);///////////
      end

      //last word
      new_output_data = (DATA_OUT_W_TB)'(0);
      for( k = pk_size-1; k >= (word_number-1)*WORD_OUT; k-- )
        begin
          new_output_data[7:0] = new_pk[k];
          if( k != (word_number-1)*WORD_OUT )
            new_output_data = new_output_data << 8;
        end
      new_pk_receive.insert( word_number-1, new_output_data );
      // $display("output: %x", new_pk_receive[word_number-1]); ////////
  k = 0;
  _test_receive_pk.put( new_pk_receive );
  new_pk_receive = {};
  end

endtask

task test_data( mailbox #( pkt_receive_t ) _receive_packet,
                   mailbox #( pkt_receive_t ) _test_receive_pk
                 );

pkt_receive_t new_pk_receive;
pkt_receive_t new_test_pk_receive;

int packet_size;

if( _receive_packet.num() != _test_receive_pk.num() )
  $display("Number of packet mismatch");
else
  begin
    packet_size = _receive_packet.num();
    while( _receive_packet.num() != 0 )
      begin
        _receive_packet.get( new_pk_receive );
        _test_receive_pk.get( new_test_pk_receive );
        if( new_pk_receive.size() != new_test_pk_receive.size() )
          $display("Packet [%0d]'s size mismatch", packet_size -_receive_packet.num());
        else
          begin
            for( int i = 0; i < new_pk_receive.size(); i++ )
              begin
                if( new_pk_receive[i] != new_test_pk_receive[i] )
                  $display("data_o [%0d][%0d] mismatch: receive: %0x, correct: %x", packet_size -_receive_packet.num(), i, new_pk_receive[i], new_test_pk_receive[i] );
                else
                  $display("data_o [%0d][%0d] match", packet_size -_receive_packet.num(), i);
              end
          end
      end
  end 
endtask

task test_empty( mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) _empty_input,
                 mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) _empty_output
               );

logic [EMPTY_OUT_W_TB-1:0] empty_in;
logic [EMPTY_OUT_W_TB-1:0] empty_out;

if( _empty_input.num() != _empty_output.num() )
  $display(" Number of input empty signal and output empty signal mismatch");
else
  begin
    while( _empty_input.num() != 0 )
      begin
        _empty_input.get( empty_in );
        _empty_output.get( empty_out );

        if( empty_in != empty_out )
          $display("empty signal error, correct: %0d, output: %0d", empty_in, empty_out);
        else
          $display("No error on empty signal");
      end
  end

endtask

task test_channel( mailbox #( logic [CHANNEL_W_TB-1:0] ) _channel_input,
                   mailbox #( logic [CHANNEL_W_TB-1:0] ) _channel_output
               );

logic [CHANNEL_W_TB-1:0] channel_in;
logic [CHANNEL_W_TB-1:0] channel_out;

if( _channel_input.num() != _channel_output.num() )
  $display(" Number of input empty signal and output empty signal mismatch");
else
  begin
    while( _channel_input.num() != 0 )
      begin
        _channel_input.get( channel_in );
        _channel_output.get( channel_out );

        if( channel_in != channel_out )
          $display("channel signal error, correct: %0d, output: %0d", channel_in, channel_out);
        else
          $display("No error on channel signal");
      end
  end

endtask

initial
  begin
    srst_i_tb <= 1'b1;
    ##1;
    srst_i_tb <= 1'b0;
    

    gen_pk( send_packet, copy_send_packet, 9, 200 );
    ast_send_pk    = new( ast_snk_if, send_packet, receive_packet, channel_input, channel_output, empty_output );
    ast_receive_pk = new( ast_src_if, send_packet, receive_packet, channel_input, channel_output, empty_output );

    fork
      ast_send_pk.send_pk();
      ast_receive_pk.reveive_pk();
      ast_receive_pk.empty_out();
      ast_receive_pk.channel_out();
      assert_ready();
    join
    // $display("\n");
    // show_receive_pk( receive_packet );

    // $display("\n");
    output_word( copy_send_packet, test_receive_pk, empty_input );
    test_data( receive_packet, test_receive_pk );
    test_empty( empty_input, empty_output );
    test_channel( channel_input, channel_output );
    $display("Test done!!");
    $stop();

  end

endmodule