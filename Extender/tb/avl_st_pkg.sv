package avl_st_pkg;

typedef logic [7:0] pkt_t [$];

class ast_class #(
  parameter DATA_W    = 32,
  parameter CHANNEL_W = 10,
  parameter EMPTY_OUT_W  = $clog2(DATA_W/8) ?  $clog2(DATA_W/8) : 1
);

localparam BYTE_WORD = DATA_W/8;

virtual avalon_st #(
  .DATA_W    ( DATA_W    ),
  .CHANNEL_W ( CHANNEL_W )
) ast_if;

// typedef logic [DATA_W-1:0] pkt_receive_t [$];
mailbox #( pkt_t ) tx_fifo;
mailbox #( pkt_t ) rx_fifo;
// mailbox #( pkt_receive_t ) rx_fifo;

function new ( virtual avalon_st #( .DATA_W    ( DATA_W    ),
                                    .CHANNEL_W ( CHANNEL_W )
                                  ) _ast_if       
             );
this.ast_if  = _ast_if;
this.tx_fifo = new(); 
this.rx_fifo = new();
endfunction

`define cb @( posedge ast_if.clk );

task send_pkt( input pkt_t _rx_pkt, int _delay_between_pkt );

// pkt_t _rx_pkt;

logic [DATA_W-1:0] pkt_data;

int pkt_size;
int i, k;
logic [CHANNEL_W-1:0] new_channel;
int byte_last_word;
int number_of_word;
int int_part, mod_part;

bit random_valid;
int cnt_byte;

logic deassert_valid;
// while( tx_fifo.num() != 0 )
  begin
    this.rx_fifo.put( _rx_pkt );
    while( ast_if.ready != 1'b1 )
      `cb;  
    // tx_fifo.get( _rx_pkt );
    new_channel = $urandom_range( 2**CHANNEL_W,0 );

    pkt_size = _rx_pkt.size();


    int_part = pkt_size / BYTE_WORD;
    
    mod_part = pkt_size % BYTE_WORD;
    i = 0;
    if( mod_part == 0 )
      number_of_word = int_part;
    else
      number_of_word = int_part + 1;

    if( pkt_size <= BYTE_WORD )
      begin
        // if( ast_if.ready )
          begin
            pkt_data        = (DATA_W)'(0);
            ast_if.valid   <= 1'b1;
            ast_if.sop     <= 1'b1;
            ast_if.eop     <= 1'b1;
            ast_if.empty   <= BYTE_WORD-pkt_size;
            for( int j = pkt_size-1; j >= 0; j-- )
              begin
                pkt_data[7:0] = _rx_pkt[j];
                if( j != 0 )
                  pkt_data = pkt_data << 8;
              end
            ast_if.data <= pkt_data;
            `cb;
            if( ast_if.eop == 1'b1 )
              begin
                ast_if.valid <= 1'b0;
                ast_if.sop   <= 1'b0;
                ast_if.eop   <= 1'b0;
              end
          end
      end
    else
      begin
        // $display("*******size: %0d*******", tx_fifo.num());
        while( cnt_byte < number_of_word )
          begin
            // $display("Byte %0d: %x", cnt_byte, _rx_pkt[cnt_byte]);
            if( cnt_byte == 0 )
              begin
                pkt_data         = (DATA_W)'(0);
                ast_if.sop     <= 1'b1;
                ast_if.eop     <= 1'b0;
                ast_if.empty   <= 0;
                ast_if.valid   <= 1'b1;
                ast_if.channel <= new_channel;
                for( int j = (BYTE_WORD*cnt_byte + BYTE_WORD) -1; j >= BYTE_WORD*cnt_byte; j-- )
                  begin
                    pkt_data[7:0] = _rx_pkt[j];
                    if( j != BYTE_WORD*cnt_byte )
                      pkt_data = pkt_data << 8;
                  end
                cnt_byte++;
              end
            else if( ( cnt_byte != 0 ) &&  ( cnt_byte != number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                pkt_data      = (DATA_W)'(0);
                random_valid = $urandom_range(1,0);
                ast_if.sop   <= 1'b0;
                ast_if.eop   <= 1'b0;
                ast_if.valid <= random_valid;

                if( random_valid == 1'b1 )
                  begin
                    for( int j = (BYTE_WORD*cnt_byte + BYTE_WORD) -1; j >= BYTE_WORD*cnt_byte; j-- )
                      begin
                        pkt_data[7:0] = _rx_pkt[j];
                        if( j != BYTE_WORD*cnt_byte )
                          pkt_data = pkt_data << 8;
                      end
                  end
                cnt_byte = cnt_byte + random_valid;
              end
            else if( ( cnt_byte == number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                byte_last_word = ( mod_part != 0 ) ? mod_part : BYTE_WORD;
                pkt_data       = (DATA_W)'(0);
                ast_if.eop    <= 1'b1;
                ast_if.sop    <= 1'b0;
                ast_if.valid  <= 1'b1;
                ast_if.empty  <= BYTE_WORD - byte_last_word;


                for( int j = (BYTE_WORD*cnt_byte + BYTE_WORD) -1; j >= BYTE_WORD*cnt_byte; j-- )
                  begin
                    pkt_data[7:0] = _rx_pkt[j];
                    if( j != BYTE_WORD*cnt_byte )
                      pkt_data = pkt_data << 8;
                  end
                for( int k = DATA_W-1; k >= byte_last_word*8; k--)
                  pkt_data[k] = 1'b0;
                cnt_byte++;
              end

          deassert_valid = ( ast_if.ready != 1'b1 && ( cnt_byte != 1 ) ) ||
                           ( ast_if.ready != 1'b1 && ( cnt_byte == 1 ) && ( ast_if.valid == 1'b1 ) );

          if( deassert_valid )
            ast_if.valid <= 1'b0;

          ast_if.data <= pkt_data;
          `cb;

          end
        if( ast_if.eop == 1'b1 )
          begin
            ast_if.eop   <= 1'b0;
            ast_if.valid <= 1'b0;
            cnt_byte     = 0;
          end
      end

  repeat( _delay_between_pkt )
    `cb;

  end

endtask


task receive_pkt();

logic [DATA_W-1:0] data_out;
logic [DATA_W-1:0] data_shifted;
pkt_t tx_pkt;
int j;
j = 0;
forever
  begin
    `cb;
    data_out = ast_if.data;
    if( ast_if.valid == 1'b1 && ast_if.eop != 1'b1 )
      begin
        for( int i = 0; i < BYTE_WORD - ast_if.empty; i++ )
          begin
            tx_pkt.push_back(data_out[7:0]);
            $display( "[%0d] %x", tx_pkt.size(), data_out[7:0] );
            data_out     = data_out >> 8;         
          end
        j++;
      end
    else if( ast_if.valid == 1'b1 && ast_if.eop == 1'b1 )
      begin
        for( int i = 0; i < BYTE_WORD - ast_if.empty; i++ )
          begin
            tx_pkt.push_back(data_out[7:0]);
            $display("last data_o: %x", data_out);
            $display( "[%0d] %x", tx_pkt.size(), data_out[7:0] );
            data_out   = data_out >> 8;
          end
        this.tx_fifo.put( tx_pkt );
        tx_pkt = {};
        j = 0;
      end
  end

endtask


endclass

endpackage