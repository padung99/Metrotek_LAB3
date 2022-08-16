interface avalon_st_if #( 
  parameter DATA_WIDTH         = 64,
  parameter CHANNEL_WIDTH      = 8,
  parameter EMPTY_WIDTH = $clog2(DATA_WIDTH/8),
  parameter TX_DIR      = 4
) ( input clk );


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