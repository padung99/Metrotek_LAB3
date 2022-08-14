interface avalon_mm_if #( 
  parameter ADDR_WIDTH = 10,
  parameter DATA_WIDTH = 64

) ( input clk );

localparam BYTE_CNT = DATA_WIDTH/8;

logic [ADDR_WIDTH-1:0] base_addr_i;
logic [ADDR_WIDTH-1:0] length_i;
logic                  run_i;
logic                  waitrequest_o;

logic [ADDR_WIDTH-1:0] address;
logic                  read;
logic [DATA_WIDTH-1:0] readdata;
logic                  readdatavalid;
logic                  waitrequest;

logic                  write;
logic [DATA_WIDTH-1:0] writedata;
logic [BYTE_CNT-1:0]   byteenable;

modport read ( 
  input  base_addr_i,
         length_i,
         run_i,
         readdata,
         readdatavalid,
         waitrequest,
  output waitrequest_o,
         address,
         read
)

modport write (
  input  base_addr_i,
         length_i,
         run_i,
         waitrequest,
  output waitrequest_o,
         address,
         write,
         writedata,
         byteenable
)

endinterface