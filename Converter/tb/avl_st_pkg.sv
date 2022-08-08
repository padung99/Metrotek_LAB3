package avl_st_pkg;

typedef logic [7:0] pkt_t [$];
typedef logic [255:0] pkt_receive_t [$];

class ast_class #(
  parameter DATA_W    = 32,
  parameter CHANNEL_W = 10,
  parameter MAX_PK    = 5
);

virtual avalon_st #(
  .DATA_W    ( DATA_W    ),
  .CHANNEL_W ( CHANNEL_W )
) ast_if;



mailbox #( pkt_t ) tx_fifo;
mailbox #( pkt_receive_t ) rx_fifo;
bit send_done;

function new ( virtual avalon_st #( .DATA_W    ( DATA_W    ),
                                    .CHANNEL_W ( CHANNEL_W )
                                  ) _ast_if,
               mailbox #( pkt_t ) _tx_fifo,
               mailbox #( pkt_receive_t ) _rx_fifo
             );

this.tx_fifo = _tx_fifo;
this.ast_if  = _ast_if;
this.rx_fifo = _rx_fifo;

endfunction

`define cb @( posedge ast_if.clk );

task send_pk();

pkt_t new_pk;

int empty_new;
logic [DATA_W-1:0] ast_data;
int pkt_size;
int i, k;
int new_channel;
int byte_last_word;
int number_of_word;
int int_part, mod_part;
int last_word_ind;

while( tx_fifo.num() != 0 )
  begin
    tx_fifo.get( new_pk );
    new_channel = $urandom_range( 2**CHANNEL_W,0 );
    pkt_size = new_pk.size();


    int_part = pkt_size / 8;
    
    mod_part = pkt_size % 8;
    i = 0;
    if( mod_part == 0 )
      number_of_word = int_part;
    else
      number_of_word = int_part + 1;

    while( i < number_of_word -1 ) 
      begin
        if( ast_if.ready )
          begin
            if( i == 0 )
              begin
                ast_if.data = (DATA_W)'(0);
                ast_if.valid   = 1'b1;
                ast_if.sop     = 1'b1;

                ast_if.channel = new_channel;

                //first word
                for( int j = 7; j >= 0; j-- )
                  begin
                    ast_if.data[7:0] = new_pk[j];
                    // $display("data send: %x", new_pk[j]);
                    if( j != 0 )
                      ast_if.data = ast_if.data << 8;
                  end
                // $display("\n");
                `cb;
                ast_if.valid = 1'b0;
                ast_if.sop   = 1'b0;
                i++;
              end
            else if( i != 0 )
              begin
                ast_if.data = (DATA_W)'(0);
                ast_if.valid = $urandom_range(1,0);
                ast_if.eop = 1'b0;
                ast_if.sop = 1'b0;
                if( ast_if.valid == 1'b1 )
                  begin
                    ast_if.channel = new_channel;
                    for( int j = (8*i + 8) -1; j >= 8*i; j-- )
                      begin
                        ast_if.data[7:0] = new_pk[j];
                        if( j != 8*i )
                          ast_if.data = ast_if.data << 8;
                      end
                    i++;
                  end
                `cb;
              end
          end
      end

    //push bytes to last word
    if( mod_part != 0 )
      byte_last_word = mod_part;
    else
      byte_last_word = 8;
    last_word_ind = 8*i;
    k = last_word_ind + byte_last_word -1;

    ast_if.data = (DATA_W)'(0);

    while( k >= last_word_ind )
      begin
        ast_if.valid = 1'b1;
        ast_if.eop = 1'b1;
        ast_if.empty = 8-byte_last_word;
        ast_if.channel = new_channel;

        ast_if.data[7:0] = new_pk[k];
        if( k != last_word_ind )
          ast_if.data = ast_if.data << 8;

        k--;
      end
      `cb;
      ast_if.valid = 1'b0;
      ast_if.eop   = 1'b0;

  k = 0;
  i = 0;
  repeat(10)
  `cb;
  end


endtask

task reveive_pk();

pkt_receive_t new_pk_receive;
int j;
forever
  begin
    `cb;
    // if( ast_if.valid == 1'b1 && ast_if.sop == 1'b1 )
    //   begin
    //     new_pk_receive = {};
    //     new_pk_receive.push_back( ast_if.data );
    //   end
    // else
    if( ast_if.valid == 1'b1 && ast_if.eop != 1'b1 )
      begin
        new_pk_receive.push_back( ast_if.data );
       $display( "receive: %x", ast_if.data );
      end
    else if( ast_if.valid == 1'b1 && ast_if.eop == 1'b1 )
      begin
        new_pk_receive.push_back( ast_if.data );
        $display( "receive: %x", ast_if.data );
        // $display("size: %0d", rx_fifo.num());
        rx_fifo.put( new_pk_receive );
        new_pk_receive = {};
      end
    if( rx_fifo.num() == MAX_PK)
     break;
  end

j = 0;
endtask

endclass

endpackage