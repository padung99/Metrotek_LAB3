interface avalon_mm_if #( 
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 64

) ( input clk );

localparam BYTE_CNT = DATA_WIDTH/8;

logic [ADDR_WIDTH-1:0] address;
logic                  read;
logic [DATA_WIDTH-1:0] readdata;
logic                  readdatavalid;
logic                  waitrequest;

logic                  write;
logic [DATA_WIDTH-1:0] writedata;
logic [BYTE_CNT-1:0]   byteenable;

// modport rd ( 
//   input  readdata,
//          readdatavalid,
//          waitrequest,
//   output address,
//          read
// );

// modport wr (
//   input  waitrequest,
//   output address,
//          write,
//          writedata,
//          byteenable
// );

endinterface