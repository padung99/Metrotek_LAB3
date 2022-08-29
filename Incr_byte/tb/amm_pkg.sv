package amm_pkg;

typedef logic [7:0] pkt_t [$];

class amm_control_class #(
  parameter DATA_W   = 64,
  parameter ADDR_W   = 10,
  parameter BYTE_CNT = DATA_W/8
);

parameter BYTE_WORD = DATA_W/8;

virtual avalon_mm_if #(
  .ADDR_WIDTH ( ADDR_W ),
  .DATA_WIDTH ( DATA_W )
) amm_if;

function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if
            );

this.amm_if      = _amm_if;

endfunction

`define cb @( posedge amm_if.clk );

task read_data( input pkt_t _read_data );

logic              begin_reading;
logic              rd_data_valid;
int cnt_word;
logic [DATA_W-1:0] pkt_data;
int pkt_size;

pkt_size = _read_data.size();
// $display("size: %0d", pkt_size);
while( cnt_word <= pkt_size/BYTE_WORD )
  begin
    `cb;
    if( amm_if.read == 1'b1 )
      begin_reading = 1'b1;
    // $display("1");
    if( begin_reading == 1'b1 )
      begin
        // $display("2");
        amm_if.waitrequest   <= $urandom_range( 1,0 );
        rd_data_valid         = $urandom_range( 1,0 );
        amm_if.readdatavalid <= rd_data_valid;

        if( rd_data_valid == 1'b1 )
          begin
            // $display("3");
            for( int j = (BYTE_WORD*cnt_word + BYTE_WORD) -1; j >= BYTE_WORD*cnt_word; j-- )
              begin
                pkt_data[7:0] = _read_data[j];
                if( j != BYTE_WORD*cnt_word )
                  pkt_data = pkt_data << 8;
              end
            cnt_word++;
            amm_if.readdata <= pkt_data;
            // $display("data: %x", pkt_data );
          end
      end
  end
  
endtask

endclass

endpackage