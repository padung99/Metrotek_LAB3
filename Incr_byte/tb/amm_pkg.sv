package amm_pkg;

typedef logic [7:0] byte_t;

class amm_control #(
  parameter DATA_W   = 64,
  parameter ADDR_W   = 10,
  parameter BYTE_CNT = DATA_W/8,
  parameter TYPE_RQ  = "read"
);

parameter BYTE_WORD  = DATA_W/8;

virtual avalon_mm_if #(
  .ADDR_WIDTH ( ADDR_W ),
  .DATA_WIDTH ( DATA_W )
) amm_if;

mailbox #( logic [7:0] ) read_data_fifo;
mailbox #( logic [ADDR_W-1:0] ) read_addr_fifo;

mailbox #( logic [7:0] ) write_data_fifo;
mailbox #( logic [ADDR_W-1:0] ) write_addr_fifo;


logic [ADDR_W-1:0] length;
int                cnt_byte;
logic [ADDR_W-1:0] base_addr;

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
this.length          = '0;
this.cnt_byte        = 0;
this.base_addr       = '0;

endfunction

`define cb @( posedge amm_if.clk );

task send_rq( input bit _always_valid = 0, bit _no_waiting );

logic              rd_data_valid;
byte_t              rd_byte;
byte_t              wr_byte;

logic [DATA_W-1:0] new_data_rd;
logic [DATA_W-1:0] new_data_wr;

logic [DATA_W-1:0] pkt_rd_data;

logic              wait_rq;
int                cnt_mem;

int                int_part;
int                mod_part;
int                cnt_word;
logic [ADDR_W-1:0] max_addr;
logic [ADDR_W-1:0] rd_addr;

forever
  begin
    rd_data_valid = 1'b0;
    if( _no_waiting == 1'b1 )
      wait_rq = 1'b0;
    else
      wait_rq = $urandom_range( 1,0 );
    
    amm_if.waitrequest <= wait_rq;

    // // CHECK READ REQUEST // //
    // check if there is a transfer to read data,
    // read address will be pushed into mailbox
    if( TYPE_RQ == "read" )
      begin
        if( amm_if.waitrequest == 1'b0 && amm_if.read == 1'b1 )
          begin
            cnt_mem++;
            read_addr_fifo.put( amm_if.address );
          end

        // // RESPONSE TO READ REQUEST // //
        // transmit data back if there is address read out
        if( cnt_mem != 0 )
          begin 
            if( _always_valid == 1'b1 )
              rd_data_valid = 1'b1;
            else
              rd_data_valid = $urandom_range( 1,0 );

            if( rd_data_valid == 1'b1 ) 
              begin
                cnt_mem--;
                // read_addr_fifo.get( rd_addr );
                pkt_rd_data[63:32] = $urandom_range( 2**DATA_W-1,0 );
                pkt_rd_data[31:0]  = $urandom_range( 2**DATA_W-1,0 );
                new_data_rd = pkt_rd_data;
                for( int i = 0; i < BYTE_WORD; i++ )
                  begin
                    read_data_fifo.put( new_data_rd[7:0] );
                    new_data_rd = new_data_rd >> 8;
                  end

                amm_if.readdata <= pkt_rd_data;
              end
          end
        amm_if.readdatavalid <= rd_data_valid;
        `cb;
      end
    else if( TYPE_RQ == "write" )
      begin
         `cb;
         new_data_wr = ( DATA_W )'(0);
        // // CHECK WRITE REQUEST // // need to use byteenable
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
    else
      $display("parameter TYPE_RQ error!!!!");

  end

endtask

// task write_data();

// logic [DATA_W-1:0] new_data_wr;
// pkt_t              wr_pkt;
// int                int_part;
// int                mod_part;
// int                cnt_word;
// int                max_addr;

// forever
//   begin
//     `cb;

//     int_part  = this.length / BYTE_WORD;
//     mod_part  = this.length % BYTE_WORD;
//     cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;
    
//     max_addr  = ( this.base_addr + cnt_word > 10'h3ff ) ? 10'h3ff : this.base_addr + cnt_word - 1;
//     if( this.cnt_byte == 0 )
//       wr_pkt = {};

//     if( ( amm_if.write == 1'b1 ) && ( amm_if.waitrequest == 1'b0 ) && ( amm_if.writedata !== 'X ) )
//       begin
//         write_addr_fifo.put( amm_if.address );
//         new_data_wr = amm_if.writedata;
//         for( int i = 0; i < BYTE_WORD; i++ )
//           begin
//             if( amm_if.byteenable[i] == 1'b1 )
//               begin
//                 wr_pkt.push_back( new_data_wr[7:0] );
//                 new_data_wr = new_data_wr >> 8;
//               end
//           end
//         this.cnt_byte = this.cnt_byte + $countones( amm_if.byteenable );
      
//         //Done writing
//         if( amm_if.address == max_addr )
//           begin
//             write_data_fifo.put( wr_pkt );
//             this.cnt_byte = 0;
//             wr_pkt = {};
//           end
//         end
//   end 

// endtask

endclass

endpackage