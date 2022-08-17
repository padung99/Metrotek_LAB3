package ast_dmx_pkg;

typedef logic [7:0] pkt_t [$];

class ast_dmx_c #(
  parameter DATA_W         = 64,
  parameter CHANNEL_W      = 8,
  parameter EMPTY_W = $clog2(DATA_W/8),
  parameter TX_DIR = 4
);

localparam WORD_IN = DATA_W/8;

virtual snk_avalon_st_if #(
  .DATA_WIDTH    ( DATA_W    ),
  .CHANNEL_WIDTH ( CHANNEL_W ),
  .EMPTY_WIDTH   ( EMPTY_W   )
) ast_if_snk;

virtual src_avalon_st_if #(
  .DATA_WIDTH    ( DATA_W    ),
  .CHANNEL_WIDTH ( CHANNEL_W ),
  .EMPTY_WIDTH   ( EMPTY_W   ),
  .TX_DIR        ( TX_DIR    )
) ast_if_src;


mailbox #( pkt_t ) tx_fifo;

function new(
    virtual snk_avalon_st_if #(
                              .DATA_WIDTH    ( DATA_W    ),
                              .CHANNEL_WIDTH ( CHANNEL_W ),
                              .EMPTY_WIDTH   ( EMPTY_W   )
                              ) _ast_if_snk,
    virtual src_avalon_st_if #(
                              .DATA_WIDTH    ( DATA_W    ),
                              .CHANNEL_WIDTH ( CHANNEL_W ),
                              .EMPTY_WIDTH   ( EMPTY_W   ),
                              .TX_DIR        ( TX_DIR    )
                              ) _ast_if_src,

    mailbox #( pkt_t ) _tx_fifo
);

this.ast_if_snk = _ast_if_snk;
this.ast_if_src = _ast_if_src;
this.tx_fifo    = _tx_fifo;

endfunction

 `define cb_snk @( posedge ast_if_snk.clk );
 `define cb_src @( posedge ast_if_src.clk );

task send_pk();

pkt_t new_pk;


int pkt_size;
int i, k;
logic [CHANNEL_W-1:0] new_channel;
int byte_last_word;
int number_of_word;
int int_part, mod_part;
int last_word_ind;

while( tx_fifo.num() != 0 )
  begin
    $display("In task send_pk");  ////////////
    tx_fifo.get( new_pk );
    new_channel = $urandom_range( 2**CHANNEL_W,0 );
    // channel_input.put( new_channel );

    pkt_size = new_pk.size();

    $display( "size: %0d", pkt_size );
    int_part = pkt_size / WORD_IN;
    
    mod_part = pkt_size % WORD_IN;
    i = 0;
    if( mod_part == 0 )
      number_of_word = int_part;
    else
      number_of_word = int_part + 1;
    
    $display("In task send_pk 2"); /////////
    if( pkt_size <= WORD_IN )
      begin
         $display("In task send_pk 3");
        if( ast_if_snk.ready ) ////// Error's here
          begin
            ast_if_snk.data    = (DATA_W)'(0);
            ast_if_snk.valid   = 1'b1;
            ast_if_snk.sop     = 1'b1;
            ast_if_snk.eop     = 1'b1;
            ast_if_snk.empty   = WORD_IN-pkt_size;
            for( int j = pkt_size-1; j >= 0; j-- )
              begin
                ast_if_snk.data[7:0] = new_pk[j];
                if( j != 0 )
                  ast_if_snk.data = ast_if_snk.data << 8;
              end
            `cb_snk;
            ast_if_snk.valid = 1'b0;
            ast_if_snk.sop   = 1'b0;
            ast_if_snk.eop   = 1'b0;            
          end
      end
    else
      begin
         $display("In task send_pk 4");
        while( i < number_of_word -1 )
          begin
             $display("In task send_pk 5");
            // if( ast_if_snk.ready ) ////// Error's here  ///////////////
              begin
                if( i == 0 )
                  begin
                    $display("In task send_pk 6");
                    ast_if_snk.data    = (DATA_W)'(0);
                    ast_if_snk.valid   = 1'b1;
                    ast_if_snk.sop     = 1'b1;
                    ast_if_snk.empty   = 0;
                    ast_if_snk.channel = new_channel;

                    //0 -->last word-1
                    for( int j = WORD_IN-1; j >= 0; j-- )
                      begin
                        ast_if_snk.data[7:0] = new_pk[j];
                        if( j != 0 )
                          ast_if_snk.data = ast_if_snk.data << 8;
                      end

                    `cb_snk;
                    ast_if_snk.valid = 1'b0;
                    ast_if_snk.sop   = 1'b0;
                    i++;
                  end
                else
                  begin
                    ast_if_snk.data = (DATA_W)'(0);
                    ast_if_snk.valid = $urandom_range(1,0);
                    ast_if_snk.eop = 1'b0;
                    ast_if_snk.sop = 1'b0;
                    ast_if_snk.empty = 0;
                    if( ast_if_snk.valid == 1'b1 )
                      begin
                        ast_if_snk.channel = new_channel;
                        for( int j = (WORD_IN*i + WORD_IN) -1; j >= WORD_IN*i; j-- )
                          begin
                            ast_if_snk.data[7:0] = new_pk[j];
                            if( j != WORD_IN*i )
                              ast_if_snk.data = ast_if_snk.data << 8;
                          end
                        i++;
                      end
                    `cb_snk;
                  end
              end
          end

        //push bytes to last word
        if( mod_part != 0 )
          byte_last_word = mod_part;
        else
          byte_last_word = WORD_IN;
        last_word_ind = WORD_IN*i;
        k = last_word_ind + byte_last_word -1;

        ast_if_snk.data = (DATA_W)'(0);

        while( k >= last_word_ind )
          begin
            ast_if_snk.valid = 1'b1;
            ast_if_snk.eop = 1'b1;
            ast_if_snk.empty = WORD_IN-byte_last_word;
            ast_if_snk.channel = 0;

            ast_if_snk.data[7:0] = new_pk[k];
            if( k != last_word_ind )
              ast_if_snk.data = ast_if_snk.data << 8;

            k--;
          end
          `cb_snk;
          ast_if_snk.empty = 0;
          ast_if_snk.valid = 1'b0;
          ast_if_snk.eop   = 1'b0;

        k = 0;
        i = 0;
      end
  
  repeat(10)
  `cb_snk;
  end

endtask

endclass

endpackage