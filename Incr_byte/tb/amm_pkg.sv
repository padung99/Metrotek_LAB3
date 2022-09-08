package amm_pkg;

class amm_control #(
  parameter DATA_W   = 64,
  parameter ADDR_W   = 10,
  parameter BYTE_CNT = DATA_W/8
);

parameter BYTE_WORD  = DATA_W/8;

virtual avalon_mm_if #(
  .ADDR_WIDTH ( ADDR_W ),
  .DATA_WIDTH ( DATA_W )
) amm_if;

mailbox #( logic [7:0] )        read_data_fifo;
mailbox #( logic [ADDR_W-1:0] ) read_addr_fifo;

mailbox #( logic [7:0] )        write_data_fifo;
mailbox #( logic [ADDR_W-1:0] ) write_addr_fifo;


function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if
            );

this.amm_if          = _amm_if;
this.read_data_fifo  = new();
this.read_addr_fifo  = new();
this.write_data_fifo = new();
this.write_addr_fifo = new();

endfunction

`define cb @( posedge amm_if.clk );

task send_rq( input bit _no_waiting );

logic [DATA_W-1:0] new_data_wr;

logic              wait_rq;

forever
  begin
    if( _no_waiting == 1'b1 )
      wait_rq = 1'b0;
    else
      wait_rq = $urandom_range( 1,0 );
    
    amm_if.waitrequest <= wait_rq;

    // // CHECK READ REQUEST // //
    // check if there is a read request
    if( amm_if.write === 'x )
      begin
        if( amm_if.waitrequest == 1'b0 && amm_if.read == 1'b1 )
          read_addr_fifo.put( amm_if.address );
        `cb;
      end
    else if( amm_if.read === 'x )
      begin
         `cb;
         new_data_wr = ( DATA_W )'(0);
        
        // // CHECK WRITE REQUEST // //
        if( amm_if.waitrequest == 1'b0 && amm_if.write == 1'b1 && ( amm_if.writedata !== 'X ) )
          begin
            write_addr_fifo.put( amm_if.address );
            new_data_wr = amm_if.writedata;
            for( int i = 0; i < BYTE_WORD; i++ )
              begin
                if( amm_if.byteenable[i] == 1'b1 )
                  begin
                    write_data_fifo.put( new_data_wr[7:0] );
                    new_data_wr = new_data_wr >> 8;
                  end
              end
          end
      end
  end

endtask

task response_rd_rq( input bit _always_valid = 0, int _delay );

logic              rd_data_valid;
logic [DATA_W-1:0] new_data_rd;
logic [DATA_W-1:0] pkt_rd_data;
// int                cnt_mem;
int                cnt_delay [$];
forever
  begin
    rd_data_valid = 1'b0;
    if( amm_if.write === 'x )
      begin
      if( amm_if.waitrequest == 1'b0 && amm_if.read == 1'b1 )
       begin
        //  cnt_mem++;
         cnt_delay.push_front(0);
       end

      for( int i = 0; i < cnt_delay.size(); i++ )
        begin
          cnt_delay[i]++;
        end
      
      for( int i = 0; i < cnt_delay.size(); i++ )
        begin
          if( cnt_delay[i] == _delay  && cnt_delay.size() != 0  )
            begin
              rd_data_valid = 1'b1;
              if( rd_data_valid == 1'b1 )
                begin
                  // cnt_mem--;
                  pkt_rd_data[63:32] = $urandom_range( 2**DATA_W-1,0 );
                  pkt_rd_data[31:0]  = $urandom_range( 2**DATA_W-1,0 );
                  new_data_rd        = pkt_rd_data;
                  for( int i = 0; i < BYTE_WORD; i++ )
                    begin
                      read_data_fifo.put( new_data_rd[7:0] );
                      new_data_rd = new_data_rd >> 8;
                    end

                  amm_if.readdata <= pkt_rd_data;
                end
              //  cnt_delay.delete(i);
            end
        end
      amm_if.readdatavalid <= rd_data_valid;

      `cb;
      //   // // CHECK READ REQUEST // //
      //   // check if there is a read request
      //   if( amm_if.waitrequest == 1'b0 && amm_if.read == 1'b1 )
      //     cnt_mem++;

      //   // // RESPONSE TO READ REQUEST // //
      //   // transmit data back if there is address read out
      //   if( cnt_mem != 0 )
      //     begin
      //       if( _always_valid == 1'b1 )
      //         rd_data_valid = 1'b1;
      //       else
      //         rd_data_valid = $urandom_range( 1,0 );

      //       if( rd_data_valid == 1'b1 )
      //         begin
      //           cnt_mem--;
      //           pkt_rd_data[63:32] = $urandom_range( 2**DATA_W-1,0 );
      //           pkt_rd_data[31:0]  = $urandom_range( 2**DATA_W-1,0 );
      //           new_data_rd        = pkt_rd_data;
      //           for( int i = 0; i < BYTE_WORD; i++ )
      //             begin
      //               read_data_fifo.put( new_data_rd[7:0] );
      //               new_data_rd = new_data_rd >> 8;
      //             end

      //           amm_if.readdata <= pkt_rd_data;
      //         end
      //     end
      //   amm_if.readdatavalid <= rd_data_valid;
      // `cb;
      end
  end

endtask

endclass

endpackage