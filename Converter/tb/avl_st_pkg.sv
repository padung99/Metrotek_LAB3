package avl_st_pkg;

typedef logic [7:0] pkt_t [$];

class ast_class #(
  parameter DATA_W    = 32,
  parameter CHANNEL_W = 10
);


virtual avalon_st #(
  .DATA_W    ( DATA_W    ),
  .CHANNEL_W ( CHANNEL_W )
) ast_if;


mailbox #( pkt_t ) tx_fifo;

function new ( virtual avalon_st #( .DATA_W    ( DATA_W    ),
                                    .CHANNEL_W ( CHANNEL_W )
                                  ) _ast_if,
               mailbox #( pkt_t ) _tx_fifo, 
             );

this.tx_fifo = _tx_fifo;
this.ast_if  = _ast_if;

endfunction

`define cb @( posedge ast_if.clk );

task send_pk();



endtask

task reveive_pk();

endtask

endclass

endpackage