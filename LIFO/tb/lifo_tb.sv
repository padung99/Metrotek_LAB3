module lifo_tb;

parameter DWIDTH             = 16;
parameter AWIDTH             = 8;
parameter ALMOST_FULL_VALUE  = 2;
parameter ALMOST_EMPTY_VALUE = 2;

parameter MAX_DATA           = 100;

bit                 clk_i_tb;
logic               srst_i_tb;

logic               wrreq_i_tb;
logic  [DWIDTH-1:0] data_i_tb;

logic               rdreq_i_tb;
logic [DWIDTH-1:0]  q_o_tb;

logic               almost_empty_o_tb;
logic               empty_o_tb;
logic               almost_full_o_tb;
logic               full_o_tb;
logic [AWIDTH:0]    usedw_o_tb;

int                 cnt_wr_data;

int q_error;
int usew_error;
int full_error;
int empty_error;
int almost_full_error;
int almost_empty_error;

bit wr_done;
bit rd_done; 

initial
  forever 
   #5 clk_i_tb = !clk_i_tb;

default clocking cb
  @( posedge clk_i_tb );
endclocking

lifo #(
  .DWIDTH         ( DWIDTH             ),
  .AWIDTH         ( AWIDTH             ),
  .ALMOST_FULL    ( ALMOST_FULL_VALUE  ),
  .ALMOST_EMPTY   ( ALMOST_EMPTY_VALUE )
) lifo_inst (
  .clk_i          ( clk_i_tb          ),
  .srst_i         ( srst_i_tb         ),

  .wrreq_i        ( wrreq_i_tb        ),
  .data_i         ( data_i_tb         ),

  .rdreq_i        ( rdreq_i_tb        ),
  .q_o            ( q_o_tb            ),

  .almost_empty_o ( almost_empty_o_tb ),
  .empty_o        ( empty_o_tb        ),
  .almost_full_o  ( almost_full_o_tb  ),
  .full_o         ( full_o_tb         ),
  .usedw_o        ( usedw_o_tb        )
);

mailbox #( logic [DWIDTH-1:0] ) data_gen = new();
mailbox #( logic [DWIDTH-1:0] ) wr_data  = new();
mailbox #( logic [DWIDTH-1:0] ) rd_data_mb  = new();
typedef logic [DWIDTH-1:0] rd_data_queue [$];

rd_data_queue rd_data;
logic [AWIDTH:0] lifo_ptr = {(AWIDTH+1){1'b1}};

task gen_data( mailbox #( logic [DWIDTH-1:0] ) _data_gen );

logic [DWIDTH-1:0] new_data;

for( int i = 0; i < 10; i++ )
  begin
    new_data = $urandom_range( 2**DWIDTH-1, 0 );
    _data_gen.put( new_data );
  end
  
endtask

task write_until_full ( mailbox #( logic [DWIDTH-1:0] ) _data_gen,
                        mailbox #( logic [DWIDTH-1:0] ) _wr_data
                      );

logic [DWIDTH-1:0] new_data;

while( _data_gen.num() != 0 )
  begin
    _data_gen.get( new_data );
    wrreq_i_tb = 1;
    rdreq_i_tb = 0;

    if( wrreq_i_tb && !full_o_tb )
      begin
        data_i_tb <= new_data;
        _wr_data.put( data_i_tb );
        lifo_ptr <= lifo_ptr+1;
        cnt_wr_data++;
      end
    @( posedge clk_i_tb );
    // #0;
  end
wrreq_i_tb = 0;
wr_done = 1;

endtask

task read_until_empty( );

repeat( cnt_wr_data )
  begin
    rdreq_i_tb = 1;
    // wrreq_i_tb = 0;
    if( rdreq_i_tb && !empty_o_tb )
      begin
        rd_data.push_front( q_o_tb );
        lifo_ptr <= lifo_ptr-1;
        // $display("q_o_tb: %x", q_o_tb);
      end
    @( posedge clk_i_tb );
  end
repeat(10)
  @( posedge clk_i_tb );
rd_done = 1;

rdreq_i_tb = 0;

endtask


task testing( mailbox #( logic [DWIDTH-1:0] ) _wr_data );

logic [DWIDTH-1:0] new_data_wr;
logic [DWIDTH-1:0] new_data_rd;

bit q_o_error;

while( _wr_data.num() != 0 )
  begin
    _wr_data.get( new_data_wr );
    new_data_rd = rd_data.pop_front();
    $display("data write in: %x, data read out: %x", new_data_wr, new_data_rd );
    if( new_data_wr != new_data_rd )
      begin
        // $error("q_o error: data write in: %x, data read out: %x", new_data_wr, new_data_rd );
        q_o_error = 1;
      end
  end

while( rd_data.size() != 0 )
  begin
    new_data_rd = rd_data.pop_front();
    $display("rd data: %x",new_data_rd );
  end

if( q_o_error )
  $error("q_o error!!");
else
  $display( "no error on q_o " );

endtask

task test_output_signal( );

forever
  begin
  @( posedge clk_i_tb );
//TEST: usew_o 
    if( lifo_ptr != usedw_o_tb )
      usew_error++;

//TEST: full_o   
    if( lifo_ptr == 2**AWIDTH )
      begin
        if( full_o_tb != 1'b1 )
          full_error++;
      end

//TEST: almost_full_o 
    if( lifo_ptr >= ALMOST_FULL_VALUE )
      begin
        if( almost_full_o_tb != 1'b1 )
          almost_full_error++;
      end

//TEST: almost_empty_o    
    if( lifo_ptr <= ALMOST_EMPTY_VALUE )
      begin
        if( almost_empty_o_tb != 1'b1 )
          almost_full_error++;
      end

//TEST: empty_o
    if( lifo_ptr == 0 )
      begin
        if( empty_o_tb != 1'b1 )
          empty_error++;
      end

    if( wr_done || rd_done )
      break;
    // ##1;
  end
endtask

task cnt_error();

if( usew_error == 0 )
  $display("No error on usew_o!!");
else
  $display("usew_o: %0d errors", usew_error);

if( empty_error == 0 )
  $display("No error on empty_o!!");
else
  $display("empty_o: %0d errors", empty_error); 

if( almost_empty_error == 0 )
  $display("No error on almost_empty_o!!");
else
  $display("almost_empty_o: %0d errors", almost_empty_error);

if( full_error == 0 )
  $display("No error on full_o!!");
else
  $display("full_o: %0d errors", full_error);

if( almost_full_error == 0 )
  $display("No error on almost_full_o!!");
else
  $display("almost_full_o: %0d errors", almost_full_error);

q_error = 0;
usew_error = 0;
full_error = 0;
empty_error = 0;
almost_full_error = 0;
almost_empty_error = 0;

endtask

task rd_request( mailbox #( logic [DWIDTH-1:0] ) _data_gen );


endtask

initial
  begin
    srst_i_tb <= 1;
    ##1;
    srst_i_tb <= 0;

    $display("Test: Write until full");
    gen_data( data_gen );

    fork
      write_until_full( data_gen, wr_data );
      test_output_signal();
    join
    cnt_error();

    // srst_i_tb <= 1;
    // @( posedge clk_i_tb );
    // srst_i_tb <= 0;
    // ##5;

    wr_done = 0;
    rd_done = 0;
    $display("Test: Read until empty");
    fork
      read_until_empty();
      test_output_signal();
    join
    cnt_error();

    // testing( wr_data );

    // rd_data = {};
    $display( "Test done!" );
    $stop();

  end

endmodule