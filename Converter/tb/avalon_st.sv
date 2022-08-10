interface avalon_st #( 
  parameter DATA_W         = 32,
  parameter CHANNEL_W      = 10
) ( input clk );

localparam EMPTY_W = $clog2(DATA_W/8) ?  $clog2(DATA_W/8) : 1;

logic [DATA_W-1:0]    data;
logic [CHANNEL_W-1:0] channel;
logic [EMPTY_W-1:0]   empty;
logic                 valid;
logic                 ready;
logic                 sop;
logic                 eop;

modport sink (
    input  data,
           channel,
           empty,
           sop,
           eop,
           valid,
    output ready
    );

modport source (
    output data,
           channel,
           empty,
           eop,
           sop,
           valid,
    input  ready
);


endinterface