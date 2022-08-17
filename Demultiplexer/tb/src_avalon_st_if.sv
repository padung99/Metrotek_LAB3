interface src_avalon_st_if #( 
  parameter DATA_WIDTH    = 64,
  parameter CHANNEL_WIDTH = 8,
  parameter EMPTY_WIDTH   = $clog2(DATA_WIDTH/8),
  parameter TX_DIR        = 4
) ( input clk );


logic [DATA_WIDTH    - 1 : 0] data    [TX_DIR - 1 : 0];
logic [CHANNEL_WIDTH - 1 : 0] channel [TX_DIR - 1 : 0];
logic [EMPTY_WIDTH   - 1 : 0] empty   [TX_DIR - 1 : 0];
logic                         valid   [TX_DIR - 1 : 0];
logic                         ready   [TX_DIR - 1 : 0];
logic                         sop     [TX_DIR - 1 : 0];
logic                         eop     [TX_DIR - 1 : 0];


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