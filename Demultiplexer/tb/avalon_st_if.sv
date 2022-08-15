interface avalon_st_if #( 
  parameter DATA_WIDTH         = 64,
  parameter CHANNEL_WIDTH      = 8
) ( input clk );

localparam EMPTY_WIDTH = $clog2(DATA_W/8);

logic [DATA_WIDTH-1:0]    data;
logic [CHANNEL_WIDTH-1:0] channel;
logic [EMPTY_WIDTH-1:0]   empty;
logic                     valid;
logic                     ready;
logic                     sop;
logic                     eop;

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