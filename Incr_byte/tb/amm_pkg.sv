package amm_pkg;


class amm_control_class #(
  parameter DATA_W   = 64,
  parameter ADDR_W   = 10,
  parameter BYTE_CNT = DATA_W/8
);

virtual avalon_mm_if #(
  .ADDR_WIDTH ( ADDR_W ),
  .DATA_WIDTH ( DATA_W )
) amm_if;

// virtual amm_setting_if #(
//   .ADDR_WIDTH ( ADDR_W )
// ) setting_if;

logic  [ADDR_W-1:0] base_addr;
logic  [ADDR_W-1:0] length;
// bit                 run;
logic               waitrequest;

function new( virtual avalon_mm_if #(
                                    .ADDR_WIDTH ( ADDR_W ),
                                    .DATA_WIDTH ( DATA_W )
                                    ) _amm_if
            );

this.amm_if      = _amm_if;
// this.setting_if = _setting_if;
this.base_addr   = 'X;
this.length      = 'X;
this.waitrequest = 'X;
// this.run        = 1'b0;

endfunction

`define cb @( posedge amm_if.clk );

// task setting( input _base_addr,
//                     _length
//             );
// forever
//   begin
//   // if( setting_if.waitrequest == 1'b0 )
//     begin
//       this.base_addr        = _base_addr;
//       this.length           = _length;
//       // this.run              = 1'b1;
//       setting_if.base_addr <= _base_addr;
//       setting_if.length    <= _length;
//       setting_if.run       <= 1'b1;
//     end

//   `cb;

//   if( setting_if.run == 1'b1 )
//     begin
//       setting_if.run       <= 1'b0;
//       setting_if.base_addr <= '0;
//       setting_if.length    <= '0;
//     end
//   end

// endtask

task read();

logic wait_rq;
int cnt_length;
int cnt_data;
logic data_valid;

bit begin_read_data;

while( cnt_data < this.length )
  begin
    $display("length: %0d", this.length);
    $display("cnt_data: %0d", cnt_data);
    if( this.waitrequest == 1'b1 )
      begin
        if( amm_if.address == this.length + this.base_addr )
          amm_if.waitrequest <= 1'b0;
        else
          begin
            wait_rq             = $urandom_range( 1,0 );
            amm_if.waitrequest <= wait_rq;
          end
        if( amm_if.address == this.length + this.base_addr  && ( amm_if.read == 1'b0 ) && ( wait_rq == 1'b0 ) )
          begin_read_data = 1'b1;

        if( begin_read_data == 1'b1 )
          begin
            data_valid = $urandom_range( 1,0 ); 
            amm_if.readdatavalid <= data_valid;
            if( data_valid == 1'b1 )
              begin 
                amm_if.readdata <= $urandom_range( 2**DATA_W-1,0 );
                cnt_data++;
              end
          end
      end
    `cb;
  end

begin_read_data = 1'b0;

endtask

endclass

endpackage