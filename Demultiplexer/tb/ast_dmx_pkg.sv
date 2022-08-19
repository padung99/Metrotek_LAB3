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
        $display("*******size: %0d*******", tx_fifo.num());
        pk_data    = '0;
        while( cnt_bytes < number_of_word )
          begin
            if( cnt_bytes == 0 )
              begin
                ast_if.sop     <= 1'b1;
                ast_if.eop     <= 1'b0;
                ast_if.empty   <= 0;
                ast_if.valid   <= 1'b1;
                ast_if.channel <= new_channel;
                // if( ast_if.valid == 1'b1 )
                  begin
                    for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                      begin
                        // ast_if.data[7:0] = new_pk[j];
                        pk_data[7:0] = new_pk[j];
                        if( j != WORD_IN*cnt_bytes )
                          // ast_if.data = ast_if.data << 8;
                          pk_data = pk_data << 8;
                      end
                  end
                $display("i, number of word: %0d %0d ", cnt_bytes, number_of_word);
                cnt_bytes++;
              end
            else if( ( cnt_bytes != 0 ) &&  ( cnt_bytes != number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                random_valid = $urandom_range(1,0);
                ast_if.sop     <= 1'b0;
                ast_if.eop     <= 1'b0;
                ast_if.valid   <= random_valid;
                if( random_valid == 1'b1 )
                  begin
                    for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                      begin
                        // ast_if.data[7:0] = new_pk[j];
                        pk_data[7:0] = new_pk[j];
                        if( j != WORD_IN*cnt_bytes )
                          // ast_if.data = ast_if.data << 8;
                          pk_data = pk_data << 8;
                      end
                  end
                cnt_bytes = cnt_bytes + random_valid;
                $display("i, number of word: %0d %0d ", cnt_bytes, number_of_word);
              end
            else if( ( cnt_bytes == number_of_word-1 ) &&  ( ast_if.ready == 1'b1 ) )
              begin
                // ast_if.empty   <= xxx;
                ast_if.eop     <= 1'b1;
                ast_if.sop     <= 1'b0;
                ast_if.valid   <= 1'b1;
                $display("i, number of word: %0d %0d ", cnt_bytes, number_of_word);
                // if( ast_if.valid == 1'b1 )
                  begin
                    for( int j = (WORD_IN*cnt_bytes + WORD_IN) -1; j >= WORD_IN*cnt_bytes; j-- )
                      begin
                        // ast_if.data[7:0] = new_pk[j];
                        pk_data[7:0] = new_pk[j];
                        if( j != WORD_IN*cnt_bytes )
                          // ast_if.data = ast_if.data << 8;
                          pk_data = pk_data << 8;
                      end
                  end
                cnt_bytes++;
              end
  
            ast_if.data <= pk_data;
          `cb;

          end
        if( ast_if.eop == 1'b1 )
          begin
            ast_if.eop <= 1'b0;
            ast_if.valid <= 1'b0;
            cnt_bytes = 0;
          end
      //   while( i < number_of_word -1 ) 
      //     begin
      //       // if( ast_if.ready )
      //         begin
      //           if( i == 0 )
      //             begin
      //               // ast_if.data    <= (DATA_W)'(0);
      //               pk_data = (DATA_W)'(0);
      //               ast_if.valid   <= 1'b1;
      //               ast_if.sop     <= 1'b1;
      //               ast_if.empty   <= 0;
      //               ast_if.channel <= new_channel;

      //               //0 -->last word-1
      //               for( int j = WORD_IN-1; j >= 0; j-- )
      //                 begin
      //                   // ast_if.data[7:0] = new_pk[j];
      //                   pk_data[7:0] = new_pk[j];
      //                   if( j != 0 )
      //                     // ast_if.data = ast_if.data << 8;
      //                     pk_data = pk_data << 8;
      //                 end
      //               // ast_if.data
      //               // `cb;
      //               if( ast_if.ready )
      //                 begin
      //                   ast_if.valid <= 1'b0;
      //                   ast_if.sop   <= 1'b0;
      //                 end
      //               i++;
      //             end
      //           else
      //             begin
      //               // ast_if.data <= (DATA_W)'(0);
      //               pk_data = (DATA_W)'(0);
      //               ast_if.valid <= $urandom_range(1,0);
      //               if( ast_if.ready )
      //                 begin
      //                   ast_if.eop <= 1'b0;
      //                   ast_if.sop <= 1'b0;
      //                   ast_if.empty <= 0;
      //                 end
      //               if( ast_if.valid == 1'b1 )
      //                 begin
      //                   ast_if.channel <= new_channel;
      //                   for( int j = (WORD_IN*i + WORD_IN) -1; j >= WORD_IN*i; j-- )
      //                     begin
      //                       // ast_if.data[7:0] = new_pk[j];
      //                       pk_data[7:0] = new_pk[j];
      //                       if( j != WORD_IN*i )
      //                         // ast_if.data = ast_if.data << 8;
      //                         pk_data = pk_data << 8 ;
      //                     end
      //                   i++;
      //                 end
      //               // `cb;
      //             end
      //             // `cb;
      //         end
      //     end

      //   //push bytes to last word
      //   if( mod_part != 0 )
      //     byte_last_word = mod_part;
      //   else
      //     byte_last_word = WORD_IN;
      //   last_word_ind = WORD_IN*i;
      //   k = last_word_ind + byte_last_word -1;

      //   ast_if.data <= (DATA_W)'(0);

      //   while( k >= last_word_ind )
      //     begin
      //       ast_if.valid <= 1'b1;
      //       ast_if.eop <= 1'b1;
      //       ast_if.empty <= WORD_IN-byte_last_word;
      //       ast_if.channel <= 0;

      //       // ast_if.data[7:0] = new_pk[k];
      //       pk_data[7:0] = new_pk[k];
      //       if( k != last_word_ind )
      //         // ast_if.data = ast_if.data << 8;
      //         pk_data = pk_data << 8;

      //       k--;
      //     end
      //     // `cb;
      //     if( ast_if.ready )
      //       begin
      //         ast_if.empty <= 0;
      //         ast_if.valid <= 1'b0;
      //         ast_if.eop   <= 1'b0;
      //       end
      //   k = 0;
      //   i = 0;
      // ast_if.data <= pk_data;
      // `cb;
      end
  repeat(5)
  `cb;
  end

endtask

// task reveive_pk();

// pkt_receive_t new_pk_receive; //???
// // rx_fifo ????
//   forever
//     begin
//       `cb_src;
//         begin
//           for( int i = 0; i < TX_DIR; i++ )
//             begin
//               if( ast_if_src.valid[i] == 1'b1 && ast_if_src.eop[i] != 1'b1 )
//                 begin
//                   new_pk_receive.push_back( ast_if_src.data[i] );
//                 //  $display( "receive: %x", ast_if_src.data );
//                 end
//               else if( ast_if_src.valid[i] == 1'b1 && ast_if_src.eop[i] == 1'b1 )
//                 begin
//                   new_pk_receive.push_back( ast_if_src.data[i] );
//                   // $display( "receive: %x", ast_if_src.data );
//                   rx_fifo.put( new_pk_receive );
//                   new_pk_receive = {};
//                 end
//             end
//         end

//       if( rx_fifo.num() >= MAX_PK )
//         break;
//     end

// endtask

endclass

endpackage