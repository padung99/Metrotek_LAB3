package amm_pkg;

typedef logic [7:0] pkt_t [$];

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

mailbox #( pkt_t )                  read_data_fifo;
mailbox #( pkt_t )                  write_data_fifo;
mailbox #( logic [ADDR_W-1:0] )     write_addr_fifo;

logic [ADDR_W-1:0] length;

function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if
            );

this.amm_if          = _amm_if;
this.read_data_fifo  = new();
this.write_data_fifo = new();
this.write_addr_fifo = new();
this.length          = 'X;

endfunction

`define cb @( posedge amm_if.clk );

task read_data( input pkt_t _read_data, bit _always_valid = 0 );

logic              begin_reading;
logic              rd_data_valid;
int cnt_word;
logic [DATA_W-1:0] pkt_data;
int pkt_size;

pkt_size  = _read_data.size();
this.read_data_fifo.put( _read_data );

while( cnt_word <= pkt_size/BYTE_WORD )
  begin
    if( amm_if.read == 1'b1 )
      begin_reading = 1'b1;

    if( begin_reading == 1'b1 )
      begin
        amm_if.waitrequest <= $urandom_range( 1,0 );

        if( _always_valid == 1'b1 )
          rd_data_valid = 1'b1;
        else
          rd_data_valid = $urandom_range( 1,0 );

        if( cnt_word == pkt_size/BYTE_WORD )
          begin
            amm_if.readdatavalid <= 1'b0;
            break;
          end
        else
          amm_if.readdatavalid <= rd_data_valid;

        if( rd_data_valid == 1'b1 )
          begin
            for( int j = (BYTE_WORD*cnt_word + BYTE_WORD) -1; j >= BYTE_WORD*cnt_word; j-- )
              begin
                pkt_data[7:0] = _read_data[j];
                if( j != BYTE_WORD*cnt_word )
                  pkt_data = pkt_data << 8;
              end
            cnt_word++;
            amm_if.readdata <= pkt_data;
          end
      end
    `cb;
  end

endtask

task write_data(  );

logic [DATA_W-1:0] new_data_wr;
pkt_t wr_pkt;
int cnt_byte;
forever 
  begin
    `cb;
      if( ( amm_if.write == 1'b1 ) && ( amm_if.waitrequest == 1'b0 ) && ( amm_if.writedata !== 'X ) )
        begin
          // $display("length --- task write_data(): %0d", this.length );
          write_addr_fifo.put( amm_if.address );
          // $display("address_wr: %x", amm_if.address );
          new_data_wr = amm_if.writedata;
          for( int i = 0; i < BYTE_WORD; i++ )
            begin
              if( amm_if.byteenable[i] == 1'b1 )
                begin
                  wr_pkt.push_back( new_data_wr[7:0] );
                  // $display("wr_byte: %x", new_data_wr[7:0]);
                  new_data_wr = new_data_wr >> 8;
                end
            end
          cnt_byte = cnt_byte + $countones( amm_if.byteenable );
          // $display("cnt_byte: %0d", cnt_byte );


          //Done writing
          if( cnt_byte == this.length )
            begin
              write_data_fifo.put( wr_pkt );
              cnt_byte = 0;
              wr_pkt = {};
            end
          // write_data_fifo.put( wr_pkt );
          // wr_pkt = {};
          // $display("wr_fifo_size: %0d", write_data_fifo.num() );
          // $display("\n");
        end
  end

endtask

endclass

endpackage