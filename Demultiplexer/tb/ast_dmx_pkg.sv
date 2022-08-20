package ast_dmx_pkg;

typedef logic [7:0] pkt_t [$];
typedef logic [63:0] pkt_receive_t [$];

class ast_dmx_c #(
  parameter DATA_W    = 64,
  parameter CHANNEL_W = 8,
  parameter EMPTY_W   = $clog2(DATA_W/8),
  parameter TX_DIR    = 4,
  parameter MAX_PK    = 5
);

localparam WORD_IN = DATA_W/8;

virtual avalon_st_if #(
  .DATA_WIDTH    ( DATA_W    ),
  .CHANNEL_WIDTH ( CHANNEL_W ),
  .EMPTY_WIDTH   ( EMPTY_W   )
) ast_if;

mailbox #( pkt_t ) tx_fifo;
mailbox #( pkt_receive_t ) rx_fifo;

function new(
    virtual avalon_st_if #(
                              .DATA_WIDTH    ( DATA_W    ),
                              .CHANNEL_WIDTH ( CHANNEL_W ),
                              .EMPTY_WIDTH   ( EMPTY_W   )
                              ) _ast_if,

    mailbox #( pkt_t ) _tx_fifo
);

this.ast_if  = _ast_if;
this.tx_fifo = _tx_fifo;

endfunction

`define cb @( posedge ast_if.clk );

task send_pk();

pkt_t new_pk;

logic [DATA_W-1:0] pk_data;

int pkt_size;
int i, k;
logic [CHANNEL_W-1:0] new_channel;
int byte_last_word;
int number_of_word;
int int_part, mod_part;
int last_word_ind;
bit random_valid;
int cnt_bytes;

logic deassert_valid;
while( tx_fifo.num() != 0 )
  begin    
    tx_fifo.get( new_pk );
    new_channel = $urandom_range( 2**CHANNEL_W,0 );
    // channel_input.put( new_channel );

    pkt_size = new_pk.size();


    int_part = pkt_size / WORD_IN;
    
    mod_part = pkt_size % WORD_IN;
    i = 0;
    if( mod_part == 0 )
      number_of_word = int_part;
    else
      number_of_word = int_part + 1;
    
    if( pkt_size <= WORD_IN )
      begin
        if( ast_if.ready )
          begin
            ast_if.data    = (DATA_W)'(0);
            ast_if.valid   = 1'b1;
            ast_if.sop     = 1'b1;
            ast_if.eop     = 1'b1;
            ast_if.empty   = WORD_IN-pkt_size;
            for( int j = pkt_size-1; j >= 0; j-- )
              begin
                ast_if.data[7:0] = new_pk[j];
                if( j != 0 )
                  ast_if.data = ast_if.data << 8;
              end
            `cb;
            ast_if.valid = 1'b0;
            ast_if.sop   = 1'b0;
            ast_if.eop   = 1'b0;            
          end
      end
    else
      begin
        // $display("*******size: %0d*******", tx_fifo.num());
        while( cnt_bytes < number_of_word )
          begin
            if( cnt_bytes == 0 )
              begin
                pk_data         = (DATA_W)'(0);
                ast_if.sop     <= 1'b1;
                ast_if.eop     <= 1'b0;
                ast_if.empty   <= 0;
                ast_if.valid   <= 1'b1;
                ast_if.channel <= new_channel;
                // $display("pk_data: %x", pk_data);
                for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                  begin
                    pk_data[7:0] = new_pk[j];
                    if( j != WORD_IN*cnt_bytes )
                      pk_data = pk_data << 8;
                  end
                cnt_bytes++;
              end
            else if( ( cnt_bytes != 0 ) &&  ( cnt_bytes != number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                pk_data      = (DATA_W)'(0);
                random_valid = $urandom_range(1,0);
                ast_if.sop   <= 1'b0;
                ast_if.eop   <= 1'b0;
                ast_if.valid <= random_valid;

                if( random_valid == 1'b1 )
                  begin
                    for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                      begin
                        pk_data[7:0] = new_pk[j];
                        if( j != WORD_IN*cnt_bytes )
                          pk_data = pk_data << 8;
                      end
                  end
                cnt_bytes = cnt_bytes + random_valid;
              end
            else if( ( cnt_bytes == number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                byte_last_word = ( mod_part != 0 ) ? mod_part : WORD_IN;
                pk_data        = (DATA_W)'(0);
                ast_if.eop    <= 1'b1;
                ast_if.sop    <= 1'b0;
                ast_if.valid  <= 1'b1;
                ast_if.empty  <= WORD_IN - byte_last_word;


                for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                  begin
                    pk_data[7:0] = new_pk[j];
                    if( j != WORD_IN*cnt_bytes )
                      pk_data = pk_data << 8;
                  end
                for( int k = DATA_W-1; k >= byte_last_word*8; k--)
                  pk_data[k] = 1'b0;
                cnt_bytes++;
              end

          deassert_valid = ( ast_if.ready == 1'b0 && ( cnt_bytes != 1 ) ) ||
                           ( ast_if.ready == 1'b0 && ( cnt_bytes == 1 ) && ( ast_if.valid == 1'b1 ) );

          if( deassert_valid )
            ast_if.valid <= 1'b0;

            ast_if.data <= pk_data;
          `cb;

          end
        if( ast_if.eop == 1'b1 )
          begin
            ast_if.eop   <= 1'b0;
            ast_if.valid <= 1'b0;
            cnt_bytes     = 0;
          end
      end
  repeat(5)
  `cb;
  end

endtask

endclass

endpackage