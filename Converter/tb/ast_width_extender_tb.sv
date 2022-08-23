import avl_st_pkg::*;

module ast_width_extender_tb;

parameter DATA_IN_W_TB   = 64;
parameter DATA_OUT_W_TB  = 256;
parameter CHANNEL_W_TB   = 10;
parameter EMPTY_IN_W_TB  = $clog2(DATA_IN_W_TB/8) ?  $clog2(DATA_IN_W_TB/8) : 1;
parameter EMPTY_OUT_W_TB = $clog2(DATA_OUT_W_TB/8) ?  $clog2(DATA_OUT_W_TB/8) : 1;

parameter WORD_OUT = ( DATA_OUT_W_TB/8 );
parameter WORD_IN  = ( DATA_IN_W_TB/8 );


parameter MAX_PK = 5;

bit                          clk_i_tb;
logic                        srst_i_tb;

int k;

int min_assert;
int max_assert;
int min_deassert;
int max_deassert;

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
) ast_send_pk;

ast_class # (
  .DATA_W      ( DATA_OUT_W_TB  ),
  .CHANNEL_W   ( CHANNEL_W_TB   ),
  .EMPTY_OUT_W ( EMPTY_OUT_W_TB )
) ast_receive_pk;

typedef logic [DATA_OUT_W_TB-1:0] pkt_receive_t [$];

mailbox #( pkt_t ) send_byte             = new();
mailbox #( pkt_t ) copy_send_byte        = new();
mailbox #( pkt_receive_t ) receive_packet  = new();
mailbox #( pkt_receive_t ) send_word_out = new();

mailbox #( logic [CHANNEL_W_TB-1:0] ) channel_input  = new();
mailbox #( logic [CHANNEL_W_TB-1:0] ) channel_output = new();

mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) empty_input  = new();
mailbox #( logic [EMPTY_OUT_W_TB-1:0] ) empty_output = new();

task gen_pk( mailbox #( pkt_t ) _send_byte,
             mailbox #( pkt_t ) _copy_send_byte,
             input int _min_byte,
                   int _max_byte
           );

pkt_t new_pk;
logic [7:0] new_data;
int random_byte;
int word_number;

for( int i = 0; i < MAX_PK; i++ )
  begin
    random_byte = $urandom_range( _min_byte,_max_byte );
    for( int j = 0; j < random_byte; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk.push_back( new_data );
      end
    _send_byte.put( new_pk );
    _copy_send_byte.put( new_pk );
    new_pk = {};
  end

endtask

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

min_assert = _min_assert;
max_assert = _max_assert;
min_deassert = _min_deassert;
max_deassert = _max_deassert;

endtask


task output_word( mailbox #( pkt_t ) _send_byte,
                  mailbox #( pkt_receive_t ) _send_word_out
               );

pkt_receive_t new_pk_receive;
logic [DATA_OUT_W_TB-1:0] new_output_data;

pkt_t new_pk;
int last_byte_index;
int pk_size;
int word_number;
logic [EMPTY_OUT_W_TB-1:0] empty_byte;
logic [EMPTY_OUT_W_TB-1:0] byte_in_last_word;

while( _send_byte.num() != 0 )
  begin
    _send_byte.get( new_pk );
    pk_size = new_pk.size();
    word_number = (( pk_size % WORD_OUT ) == 0 )? pk_size/WORD_OUT : pk_size/WORD_OUT +1 ;
    
    byte_in_last_word = pk_size - ( pk_size/WORD_OUT )*WORD_OUT;
    empty_byte = (( pk_size % WORD_OUT ) == 0 ) ? 0 : (  WORD_OUT- byte_in_last_word );

    // _empty_input.put( empty_byte );

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
        // $display("output: %x", new_pk_receive[j]);
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
      // $display("output: %x", new_pk_receive[word_number-1]); 
  k = 0;
  _send_word_out.put( new_pk_receive );
  new_pk_receive = {};
  end

endtask

task test_data( mailbox #( pkt_receive_t ) _receive_packet,
                mailbox #( pkt_receive_t ) _send_word_out
                 );

pkt_receive_t new_pk_receive;
pkt_receive_t new_test_pk_receive;

int packet_size;

int mbox_size;

bit data_error;

if( _receive_packet.num() != _send_word_out.num() )
  $display("Number of packet mismatch, send: %0d, receive: %0d", _send_word_out.num(), _receive_packet.num() );
else
  begin
    $display("--------Test 'data_o' signal-----------");
    mbox_size = _receive_packet.num();
    packet_size = _receive_packet.num();
    while( _receive_packet.num() != 0 )
      begin
        _receive_packet.get( new_pk_receive );
        _send_word_out.get( new_test_pk_receive );
        $display("###PACKET [%0d]", mbox_size-_receive_packet.num());
        if( new_pk_receive.size() != new_test_pk_receive.size() )
          $display("Packet [%0d]'s size mismatch: send: %0d, receive: %0d", packet_size -_receive_packet.num(), new_test_pk_receive.size(), new_pk_receive.size());
        else
          begin
            for( int i = 0; i < new_pk_receive.size(); i++ )
              begin
                if( new_pk_receive[i] != new_test_pk_receive[i] )
                  begin
                    $display("data_o [%0d][%0d] mismatch: receive: %0x, correct: %x", packet_size -_receive_packet.num(), i, new_pk_receive[i], new_test_pk_receive[i] );
                    data_error = 1'b1;
                  end
              end
          end
        if( !data_error )
          $display("No error with data in PACKET [%0d]",mbox_size-_receive_packet.num() );
        data_error = 1'b0;
      end
  end 
endtask


task reset();

srst_i_tb <= 1'b1;
@( posedge clk_i_tb );
srst_i_tb <= 1'b0;

endtask

initial
  begin
    
    ast_src_if.ready <= 1'b1;
    srst_i_tb <= 1'b1;
    @( posedge clk_i_tb );
    srst_i_tb <= 1'b0;
    
    // // // **********************TEST CASE 1*************************
    gen_pk( send_byte, copy_send_byte, WORD_OUT*4, WORD_OUT*4 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte );
    set_assert_range( 2*(WORD_OUT*4)/8+5,2*(WORD_OUT*4)/8+5,0,0 );
    $display("TEST CASE 1: Number of bytes = [WORD_OUT*k] = 32 * 4 = 128");
    fork
      ast_send_pk.send_pk(3);
      ast_receive_pk.reveive_pk( receive_packet );
      assert_ready();
    join_any
    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
 
    // // // **********************TEST CASE 2*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, 132, 132 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte );
    set_assert_range( 2*(132)/8+5,2*(132)/8+5,0,0 );
    $display("TEST CASE 2: Number of bytes = [WORD_OUT*k + N] = 32*4 + 4 = 132");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 3*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_IN, WORD_IN );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 2*(WORD_IN)/8+5,2*(WORD_IN)/8+5,0,0 );
    $display("TEST CASE 3: Number of bytes = [WORD_IN] = 8");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 4*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_IN*1+5, WORD_IN*1+5 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 2*(WORD_IN*1+5)/8+5,2*(WORD_IN*1+5)/8+5,0,0 );
    $display("TEST CASE 4: Number of bytes = [WORD_IN*k + N (k <8)] = 8*1 + 5 = 14");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 5*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_OUT*1, WORD_OUT*1 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 2*(WORD_OUT*1)/8+5,2*(WORD_OUT*1)/8+5,0,0 );
    $display("TEST CASE 5: Number of bytes = [WORD_OUT*k] = 32*1 = 32");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 6*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte,  WORD_IN - 6,  WORD_IN - 6 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 2*(WORD_IN - 6)/8+5,2*(WORD_IN - 6)/8+5,0,0 );
    $display("TEST CASE 6: Number of bytes = [WORD_IN - k (0 < k < 8)] = 8 - 6 = 2");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 7*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_IN*3, WORD_IN*3 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 2*(WORD_IN*3)/8+5,2*(WORD_IN*3)/8+5,0,0 );
    $display("TEST CASE 7: Number of bytes = [WORD_IN*k(k > 1)] = 8*3 ");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    // // // **********************TEST CASE 8*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_IN*3, WORD_IN*3 );
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 1,3,1,3 );
    $display("TEST CASE 8 : Random ready ( only 1 word output )");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    
    // // // **********************TEST CASE 9*************************
    send_byte      = new();
    copy_send_byte = new();

    send_word_out  = new();
    reset();
    gen_pk( send_byte, copy_send_byte, WORD_OUT*3+2, WORD_OUT*3 +2);
    ast_send_pk    = new( ast_snk_if, send_byte );
    ast_receive_pk = new( ast_src_if, send_byte ); 
    set_assert_range( 1,3,1,3 );
    $display("TEST CASE 9 : Random ready ( many words ouput )");

    ast_send_pk.send_pk(3);

    // $display("Test receive mb_size: %0d", receive_packet.num());

    output_word( copy_send_byte, send_word_out );
    test_data( receive_packet, send_word_out );
    $display("\n");
    
    $display("Test done!!");
    $stop();

  end

endmodule