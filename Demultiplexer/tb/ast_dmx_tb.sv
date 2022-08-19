import ast_dmx_pkg::*;

module ast_dmx_tb;

parameter int DATA_WIDTH_TB     = 64;
parameter int CHANNEL_WIDTH_TB  = 8;
parameter int EMPTY_WIDTH_TB    = $clog2( DATA_WIDTH_TB / 8 );
parameter int TX_DIR_TB         = 4;

parameter int DIR_SEL_WIDTH_TB = TX_DIR_TB == 1 ? 1 : $clog2( TX_DIR_TB );

parameter MAX_PK = 5;

bit clk_i_tb;
logic srst_i_tb;
logic [DIR_SEL_WIDTH_TB-1:0] dir_i_tb ;

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

// src_avalon_st_if #(
//   .DATA_WIDTH    ( DATA_WIDTH_TB    ),
//   .CHANNEL_WIDTH ( CHANNEL_WIDTH_TB ),
//   .EMPTY_WIDTH   ( EMPTY_WIDTH_TB   ),
//   .TX_DIR        ( TX_DIR_TB        )
// ) ast_src_if (
//   .clk ( clk_i_tb )
// );

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
    random_byte = $urandom_range( _min_byte,_max_byte );
    $display("PACKET %0d", i);
    for( int j = 0; j < random_byte; j++ )
      begin
        new_data = $urandom_range( 2**8,0 );
        new_pk[j] = new_data;
        $display("data: %x", new_data);
      end
    _send_packet.put( new_pk );
    _copy_send_packet.put( new_pk );
    new_pk = {};
    $display("\n");
  end

endtask

// task assert_ready_1clk();

// @( posedge clk_i_tb )
// ast_src_if.ready[1] <= 1'b1;

// endtask

// task assert_ready();

// repeat(100)
//   assert_ready_1clk();
// endtask

initial
  begin
    ast_ready_i_tb[0] <= 1'b1;
    ast_ready_i_tb[1] <= 1'b1;
    ast_ready_i_tb[2] <= 1'b1;
    ast_ready_i_tb[3] <= 1'b1;
    dir_i_tb = 2'd1;
    srst_i_tb <= 1'b1;
    @( posedge clk_i_tb )
    srst_i_tb <= 1'b0;

    // @( posedge clk_i_tb );

    gen_pk ( send_packet, copy_send_packet, 32, 32 );

    ast_send_pk = new( ast_snk_if, send_packet );
    
    fork
      ast_send_pk.send_pk();
      // assert_ready();
    join

    $stop();


  end


endmodule