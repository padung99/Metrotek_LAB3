module lifo_tb;

parameter DWIDTH             = 16;
parameter AWIDTH             = 8;
parameter ALMOST_FULL_VALUE  = 2;
parameter ALMOST_EMPTY_VALUE = 2;


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


logic               almost_empty_tb;
logic               empty_tb;
logic               almost_full_tb;
logic               full_tb;

logic valid_rd;
logic valid_wr;


int                 cnt_wr_data;
bit done_wr;
bit done_rd_wr;
bit done_rd;

int q_error;
int usew_error;
int full_error;
int empty_error;
int almost_full_error;
int almost_empty_error;

bit wr_done;
bit rd_done;
bit rd_begin;

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
rd_data_queue lifo_queue;

logic [AWIDTH:0] ptr = {(AWIDTH+1){1'b0}};

logic [AWIDTH:0] lifo_ptr = {(AWIDTH+1){1'b0}};

task gen_data( mailbox #( logic [DWIDTH-1:0] ) _data_gen,
              input int _data_num 
             );

logic [DWIDTH-1:0] new_data;

for( int i = 0; i < _data_num; i++ )
  begin
    new_data = $urandom_range( 2**DWIDTH-1, 0 );
    _data_gen.put( new_data );
  end
endtask

task write_rq ( mailbox #( logic [DWIDTH-1:0] ) _data_gen,
                mailbox #( logic [DWIDTH-1:0] ) _wr_data
              );

logic [DWIDTH-1:0] new_data;
logic [DWIDTH-1:0] dump_data;
while( _data_gen.num() != 0 )
  begin
    _data_gen.get( new_data );
    wrreq_i_tb = 1;

    if( wrreq_i_tb && !full_o_tb )
      begin
        data_i_tb = new_data;
        if( lifo_ptr != 2**AWIDTH -1 )
          begin
            _wr_data.put( data_i_tb );
            cnt_wr_data++;
          end
      end
    @( posedge clk_i_tb );
  end

wrreq_i_tb <= 0;
wr_done = 1;

endtask

task read_until_empty( input bit _rd_only,
                             int _cnt_repeat
                     );
int delay;
bit repeat_done;

logic [DWIDTH-1:0] new_data;

if( !_rd_only )
  delay = 5;
else
  delay = 0;

forever
  begin
    if( delay != 0 )
      begin
        delay--;
        rdreq_i_tb = 0;
        @( posedge clk_i_tb );
      end
    else
      repeat( _cnt_repeat )
        begin
          rdreq_i_tb = 1;
          @( posedge clk_i_tb );
          repeat_done = 1'b1;
        end
  if( repeat_done )
    break;
  end

repeat(10)
@( posedge clk_i_tb );
rd_done = 1;
rdreq_i_tb <= 0;
endtask

task rd_output_data();

forever
  begin
    @( posedge clk_i_tb );
    if( rdreq_i_tb && !empty_o_tb )
      rd_data.push_front( q_o_tb );

    if( rd_done )
      break;
  end
rd_data.pop_back();
rd_data.push_front( q_o_tb );

endtask

task non_synthesys_signal( input bit _read,
                                     _write,
                                     _rd_and_wr
                          );
forever
  begin
    if( ptr == 2**AWIDTH )
      full_tb = 1'b1;
    else
      full_tb = 1'b0;

    if( ptr >= ALMOST_FULL_VALUE )
      almost_full_tb = 1'b1;
    else
      almost_full_tb = 1'b0;

    if( ptr == 0 )
      empty_tb = 1'b1;
    else
      empty_tb = 1'b0;

    if( ptr <= ALMOST_EMPTY_VALUE )
      almost_empty_tb = 1'b1;
    else
      almost_empty_tb = 1'b0;
    if( _read && done_rd )
      break;
    if( _write && done_wr )
      break;
    if( _rd_and_wr && done_rd_wr )
      break;
    ##1;
  end

endtask

assign valid_wr = wrreq_i_tb && !full_tb;
assign valid_rd = rdreq_i_tb && !empty_tb;

////Control pointer
task inr_ptr();
forever
  begin
    @( posedge clk_i_tb );
    if( valid_wr && !valid_rd )
      lifo_ptr <= lifo_ptr+1;
    if( wr_done )
      break;
  end

endtask

task decr_ptr();

forever
  begin
    @( posedge clk_i_tb );
    if( valid_rd && !valid_wr )
      lifo_ptr <= lifo_ptr-1;
    if( rd_done )
      break;
  end
endtask


task testing( mailbox #( logic [DWIDTH-1:0] ) _wr_data );

logic [DWIDTH-1:0] new_data_wr;
logic [DWIDTH-1:0] new_data_rd;

bit q_o_error;

if( _wr_data.num() != rd_data.size() )
  begin
    $error("Number of input and output data mismatch --- input: %0d, output: %0d", _wr_data.num(), rd_data.size() );
    q_o_error = 1;
  end
else
  begin
    while( _wr_data.num() != 0 )
      begin
        _wr_data.get( new_data_wr );
        new_data_rd = rd_data.pop_front();

        if( new_data_wr != new_data_rd )
          q_o_error = 1;
      end
  end

if( q_o_error )
  $error("q_o error!!");
else
  $display( "no error on q_o " );

endtask

task test_output_signal( input bit _read,
                               bit _write,
                               bit _rd_and_wr
                       );

forever
  begin
  @( posedge clk_i_tb );
//TEST: usew_o 
    if( ptr != usedw_o_tb )
      usew_error++;

//TEST: full_o   
    if( full_o_tb != full_tb )
      full_error++;

//TEST: almost_full_o 
    if( almost_full_o_tb != almost_full_tb )
      almost_full_error++;


//TEST: almost_empty_o    
    if( almost_empty_o_tb != almost_empty_tb )
      almost_empty_error++;


//TEST: empty_o
    if( empty_o_tb != empty_tb )
      empty_error++;

    if( _read && done_rd )
      break;
    if( _write && done_wr )
      break;
    if( _rd_and_wr && done_rd_wr )
      break;
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

/////////////////////////////////////////////////////////////////////////
task wr_1clk();

@( posedge clk_i_tb );
  wrreq_i_tb <= 1'b1;
  rdreq_i_tb <= 1'b0;
  data_i_tb <= $urandom_range(2**DWIDTH,0);


endtask

task rd_1clk();

@( posedge clk_i_tb );
wrreq_i_tb <= 1'b0;
rdreq_i_tb <= 1'b1;


endtask

task control_ptr( input bit _read,
                            _write,
                            _rd_and_wr
                );

forever
  begin
    @( posedge clk_i_tb )
    if( valid_wr )
      lifo_queue.push_back( data_i_tb );
    if( valid_rd )
      lifo_queue.pop_back();
    
    ptr <= lifo_queue.size();
    if( _read && done_rd )
      break;
    if( _write && done_wr )
      break;
    if( _rd_and_wr && done_rd_wr )
      break;
  end

endtask


task rd_and_wr_1clk();

@( posedge clk_i_tb );
wrreq_i_tb <= 1'b1;
data_i_tb <= $urandom_range(2**DWIDTH,0);
rdreq_i_tb <= 1'b1;

endtask

task idle();
@( posedge clk_i_tb );
wrreq_i_tb <= 1'b0;
rdreq_i_tb <= 1'b0;

endtask

task wr_only( input int _repeat = 2**AWIDTH );
$display("Start writing until full");
repeat( _repeat )
  wr_1clk();

$display("Finish!!!");
idle();
done_wr = 1'b1;
endtask


task rd_only( input int _repeat = 2**AWIDTH +2 );
$display("Start reading until empty");
repeat( _repeat )
  rd_1clk();
done_rd = 1'b1;
$display("Finish!!!");
endtask

task rd_and_wr( input int _delay );

repeat( _delay )
  wr_1clk();
repeat( 2**AWIDTH-_delay )
  rd_and_wr_1clk();
repeat( _delay )
  rd_1clk();
done_rd_wr = 1'b1;
endtask

initial
  begin
    srst_i_tb = 1;
    ##1;
    srst_i_tb = 0;
    
    //////////////////Uncomment to run each test case (Run 1 test at the time)/////////////////

    // // Test: Reading process begins immediately after full
    fork
      wr_only( 2**AWIDTH );
      control_ptr(0,1,0);
      non_synthesys_signal(0,1,0);
      test_output_signal(0,1,0);
    join 
    cnt_error();

    fork
      rd_only( 2**AWIDTH + 2 );
      control_ptr(1,0,0);
      non_synthesys_signal(1,0,0);
      test_output_signal(1,0,0);
    join
    cnt_error();

    // // Test: Write to full
    // wr_only( 2**AWIDTH + 5 );

    // // Test: read from empty
    // rd_only( 32 );

    // // Test: Write to full and read until empty
    // wr_only( 2**AWIDTH + 5 );
    // rd_only( 2**AWIDTH + 2 );

    // // Test: Read and write at the same time with delay at the begining
    // rd_and_wr( 5 );
    
    // // Test: Read and write at the same time without delaying at the begining
    // rd_and_wr( 0 );

    // // Test: Alternating read and write processes
    // fork
    //   wr_only( 2**AWIDTH );
    //   rd_only( 2**AWIDTH + 2 );
    // join



    // //////////////////////////////TEST 1//////////////////////////////
    // // WRITE ONLY
    // // Write to lifo (Don't make lifo full)

    // $display("###Test: Write only");
    // gen_data( data_gen, 10 );
    // rdreq_i_tb = 0;
    // fork
    //   write_rq( data_gen, wr_data );
    //   inr_ptr();
    //   test_output_signal(1,0, 0);
    //   non_synthesys_signal(1,0,0);
    // join
    // cnt_error();
    // ##4;
    // $display("\n");
    // wr_done = 0;
    // rd_done = 0;

    // // READ ONLY
    // $display("###Test: Read until empty");
    // fork
    //   read_until_empty(1, cnt_wr_data);
    //   decr_ptr();
    //   test_output_signal(0,1, 0);
    //   non_synthesys_signal(0,1,0);
    //   rd_output_data();
    // join
    // cnt_error();
    // testing( wr_data );

    // //////////////////////////////TEST 2//////////////////////////////
    // // WRITE ONLY
    // // Write to lifo until full
    // // Write some extra values (5 value ) after lifo is full
    // $display("###Test: Write until full");
    // gen_data( data_gen, 2**AWIDTH+5 ); // 5 extra values after lifo is full
    // rdreq_i_tb = 0;
    // fork
    //   write_rq( data_gen, wr_data );
    //   test_output_signal(1,0,0);
    //   inr_ptr();
    //   non_synthesys_signal(1,0,0);
    // join
    // cnt_error();

    // $display("\n");
    // wr_done = 0;
    // rd_done = 0;

    // // READ ONLY
    // $display("###Test: Read until empty");
    // fork
    //   read_until_empty(1, cnt_wr_data);
    //   test_output_signal(0,1,0);
    //   decr_ptr();
    //   non_synthesys_signal(0,1,0);
    //   rd_output_data();
    // join
    // cnt_error();
    // testing( wr_data );

    // //////////////////////////////TEST 3//////////////////////////////
    // // Write to lifo until full
    // // No extra values written to lifo, read process will begin immediately after lifo is full
    // $display("###Test: Write until full");
 
    // gen_data( data_gen, 2**AWIDTH);
    // rdreq_i_tb = 0;
    // fork
    //   write_rq( data_gen, wr_data );
    //   test_output_signal(1,0,0);
    //   inr_ptr();
    //   non_synthesys_signal(1,0,0);
    // join
    // cnt_error();

    // $display("\n");
    // wr_done = 0;
    // rd_done = 0;

    // // READ ONLY
    // $display("###Test: Read until empty");
    // fork
    //   read_until_empty(1, cnt_wr_data);
    //   test_output_signal(0,1,0);
    //   decr_ptr();
    //   non_synthesys_signal(0,1,0);
    //   rd_output_data();
    // join
    // cnt_error();
    // testing( wr_data );

    // ////////////////////////////////TEST 4//////////////////////////////
    // // // Read and write at the same time
    // $display("###Read and write");
    // gen_data( data_gen, 2**AWIDTH+5 );
    
    // fork
    //   write_rq( data_gen, wr_data);
    //   inr_ptr();
    //   read_until_empty(0, 2**AWIDTH+5);
    //   decr_ptr();
    //   test_output_signal(0,0,1);
    //   non_synthesys_signal(0,0,1);
    // join
    // cnt_error();

    $display( "Test done!" );
    $stop();

  end

endmodule