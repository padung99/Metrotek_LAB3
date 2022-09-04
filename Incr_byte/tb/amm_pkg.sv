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
int                cnt_byte;
logic [ADDR_W-1:0] base_addr;

function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if
            );

this.amm_if          = _amm_if;
this.read_data_fifo  = new();
this.write_data_fifo = new();
this.write_addr_fifo = new();
this.length          = '0;
this.cnt_byte        = 0;
this.base_addr       = '0;

endfunction

`define cb @( posedge amm_if.clk );

task read_data( input pkt_t _read_data, bit _always_valid = 0, bit _no_waiting );

logic              rd_data_valid;
int                cnt_word;
logic [DATA_W-1:0] pkt_data;
int                pkt_size;
logic              wait_rq;
int                cnt_mem;
int                total_word;

pkt_size      = _read_data.size();
total_word    = ( this.base_addr + pkt_size/BYTE_WORD > 10'h3ff ) ? ( 10'h3ff - this.base_addr + 1 ) : pkt_size/BYTE_WORD;
this.read_data_fifo.put( _read_data );

while( cnt_word < total_word )
  begin
    rd_data_valid = 1'b0;
    if( _no_waiting == 1'b1 )
      wait_rq = 1'b0;
    else
      wait_rq = $urandom_range( 1,0 );
    
    amm_if.waitrequest <= wait_rq;

    //cnt_mem is used to avoid writing to unread address.
    if( amm_if.waitrequest == 1'b0 && amm_if.read == 1'b1 )
      cnt_mem++;

    if( cnt_mem != 0 )
      begin
        if( _always_valid == 1'b1 )
          rd_data_valid = 1'b1;
        else 
          rd_data_valid = $urandom_range( 1,0 );

        if( rd_data_valid == 1'b1 )
          begin
            for( int j = (BYTE_WORD*cnt_word + BYTE_WORD) -1; j >= BYTE_WORD*cnt_word; j-- )
              begin
                pkt_data[7:0] = _read_data[j];
                if( j != BYTE_WORD*cnt_word )
                  pkt_data = pkt_data << 8;
              end
            cnt_mem--;
            cnt_word++;
            amm_if.readdata <= pkt_data;
          end
      end

    amm_if.readdatavalid <= rd_data_valid;

    `cb;

  end

  if( cnt_word == total_word )
    amm_if.readdatavalid <= 1'b0;
  `cb;

$display( "base_addr: %x, word_sended: %0d, total_word: %0d", this.base_addr, cnt_word, pkt_size/BYTE_WORD );

endtask

task write_data();

logic [DATA_W-1:0] new_data_wr;
pkt_t              wr_pkt;
int                int_part;
int                mod_part;
int                cnt_word;
int                max_addr;

forever
  begin
    `cb;

    int_part  = this.length / BYTE_WORD;
    mod_part  = this.length % BYTE_WORD;
    cnt_word  = ( mod_part == 0 ) ? int_part : int_part + 1;
    
    max_addr  = ( this.base_addr + cnt_word > 10'h3ff ) ? 10'h3ff : this.base_addr + cnt_word - 1;
    if( this.cnt_byte == 0 )
      wr_pkt = {};

    if( ( amm_if.write == 1'b1 ) && ( amm_if.waitrequest == 1'b0 ) && ( amm_if.writedata !== 'X ) )
      begin
        write_addr_fifo.put( amm_if.address );
        new_data_wr = amm_if.writedata;
        for( int i = 0; i < BYTE_WORD; i++ )
          begin
            if( amm_if.byteenable[i] == 1'b1 )
              begin
                wr_pkt.push_back( new_data_wr[7:0] );
                new_data_wr = new_data_wr >> 8;
              end
          end
        this.cnt_byte = this.cnt_byte + $countones( amm_if.byteenable );
      
        //Done writing
        if( amm_if.address == max_addr )
          begin
            write_data_fifo.put( wr_pkt );
            this.cnt_byte = 0;
            wr_pkt = {};
          end
        end
  end 

endtask

endclass

endpackage