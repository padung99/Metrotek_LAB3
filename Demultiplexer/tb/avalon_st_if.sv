interface avalon_st_if #( 
  parameter DATA_W    = 64,
  parameter CHANNEL_W = 8,
  parameter EMPTY_W   = $clog2(DATA_W/8)
) ( input clk );


logic [DATA_W    - 1 : 0] data;
logic [CHANNEL_W - 1 : 0] channel;
logic [EMPTY_W   - 1 : 0] empty;
logic                         valid;
logic                         ready;
logic                         sop;
logic                         eop;

modport sink (
    input  data,
           channel,
           empty,
           eop,
           sop,
           valid,
    output ready
);


endinterface