interface amm_setting_if @(
  parameter ADDR_WIDTH = 10
)

logic [ADDR_WIDTH-1:0] base_addr;
logic [ADDR_WIDTH-1:0] length;
logic                  run;
logic                  waitrequest;

modport setting (
  input  base_addr,
         length,
         run
  output waitrequest
)


endinterface