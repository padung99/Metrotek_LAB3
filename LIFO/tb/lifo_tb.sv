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
logic [DWIDTH-1:0]  q_tb;

logic valid_rd;
logic valid_wr;

bit done_wr;
bit done_rd_wr;
bit done_rd;

int q_error;
int usew_error;
int full_error;
int empty_error;
int almost_full_error;
int almost_empty_error;

int cnt_testing;

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

typedef logic [DWIDTH-1:0] rd_data_queue [$];

rd_data_queue lifo_queue;

logic [AWIDTH:0] ptr;
// logic [AWIDTH:0] ptr = {(AWIDTH+1){1'b0}};

task wr_1clk();

@( posedge clk_i_tb );
  wrreq_i_tb <= 1'b1;
  rdreq_i_tb <= 1'b0;
  data_i_tb <= $urandom_range(2**DWIDTH,0);

endtask


task wr_1clk_random();

@( posedge clk_i_tb );
  wrreq_i_tb <= $urandom_range(1,0);
  rdreq_i_tb <= 1'b0;
  data_i_tb  <= $urandom_range(2**DWIDTH,0);

endtask

task rd_1clk();

@( posedge clk_i_tb );
wrreq_i_tb <= 1'b0;
rdreq_i_tb <= 1'b1;

endtask

task rd_1clk_random();

@( posedge clk_i_tb );
wrreq_i_tb <= 1'b0;
rdreq_i_tb <= $urandom_range(1,0);

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
      q_tb <= lifo_queue.pop_back();

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
data_i_tb  <= $urandom_range(2**DWIDTH,0);
rdreq_i_tb <= 1'b1;

endtask

task idle();
@( posedge clk_i_tb );
wrreq_i_tb <= 1'b0;
rdreq_i_tb <= 1'b0;

endtask

task rd_wr_idle( input int _repeat );

repeat( 5 )
  begin
    wr_1clk();
    idle();
  end

repeat( _repeat )
  begin
    rd_and_wr_1clk();
    idle();
  end

repeat( 5 )
  begin
    rd_1clk();
    idle();
  end
endtask

task wr_only( input int _repeat );
$display("Start writing until full");
repeat( _repeat )
  wr_1clk();

$display("Finish!!!");
idle();
done_wr = 1'b1;
endtask

task wr_only_random( input int _repeat );
$display("Start writing until full");
repeat( _repeat )
  wr_1clk_random();

$display("Finish!!!");
idle();
done_wr = 1'b1;
endtask

task wr_only_non_idle( input int _repeat );
$display("Start writing until full");
repeat( _repeat )
  wr_1clk();

$display("Finish!!!");
done_wr = 1'b1;
endtask

task rd_only( input int _repeat );
$display("Start reading until empty");
repeat( _repeat )
  rd_1clk();
idle();
done_rd = 1'b1;
$display("Finish!!!");
endtask

task rd_only_non_idle( input int _repeat );
$display("Start reading until empty");
repeat( _repeat )
  rd_1clk();
done_rd = 1'b1;
$display("Finish!!!");
endtask

task rd_only_random( input int _repeat );
$display("Start reading until empty");
repeat( _repeat )
  rd_1clk_random();
done_rd = 1'b1;
$display("Finish!!!");
endtask

task rd_and_wr( input int _delay, int _rd_wr );
repeat( _delay )
  wr_1clk();
repeat( _rd_wr-_delay )
  rd_and_wr_1clk();
repeat( _delay +5 )
  rd_1clk();
done_rd_wr = 1'b1;
endtask

task reset();

srst_i_tb       <= 1;
empty_tb        <= 1;
full_tb         <= 0;
almost_empty_tb <= 1'b1;
almost_full_tb  <= 1'b0;
lifo_queue       = {};
@( posedge clk_i_tb );
srst_i_tb <= 0;

endtask

task output_signal( input bit _read,
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

task test_output_signal( input bit _read,
                               bit _write,
                               bit _rd_and_wr
                       );

forever
  begin
  @( posedge clk_i_tb );
//TEST: q_o 
  if( q_tb != q_o_tb )
    q_error++;

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

if( q_error == 0 )
  $display("No error on q_o!!");
else
  $display("q_o: %0d errors", q_error);

$display("\n");
q_error            = 0;
usew_error         = 0;
full_error         = 0;
empty_error        = 0;
almost_full_error  = 0;
almost_empty_error = 0;

endtask


initial
  begin
    srst_i_tb <= 1;
    @( posedge clk_i_tb );
    srst_i_tb <= 0;
    
    //////////////////UNCOMMENT TO RUN EACH TEST CASE (RUN 1 TEST AT THE TIME)/////////////////

    // // Test case 1: Reading process begins immediately after full

    repeat(5)
      begin
        $display("Test case 1: Reading process begins immediately after full");
        fork
          wr_only( 2**AWIDTH );
          control_ptr(0,1,0);
          output_signal(0,1,0);
          test_output_signal(0,1,0);
        join
        cnt_error();

        fork
          rd_only( 2**AWIDTH );
          control_ptr(1,0,0);
          output_signal(1,0,0);
          test_output_signal(1,0,0);
        join
        idle();
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;
      end
    ////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 2: Write to full

    // repeat(5)
      begin
        $display("Test case 2: Write to full");
        fork
          wr_only( 2**AWIDTH + 5 );
          control_ptr(0,1,0);
          output_signal(0,1,0);
          test_output_signal(0,1,0);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;

      end
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 3: read from empty

    // repeat(5)
      begin
        $display("Test case 3: read from empty");
        fork
          rd_only( 32 );
          control_ptr(1,0,0);
          output_signal(1,0,0);
          test_output_signal(1,0,0);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;

      end
    // //////////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 4: Write some value after full and read out all data

    // repeat(5)
    begin
      $display("Test case 4: Write some value after full and read out all data");
      fork
        wr_only( 2**AWIDTH +5 );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join 
      cnt_error();

      fork
        rd_only( 2**AWIDTH + 5 );
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();
      done_rd         = 1'b0;
      done_wr         = 1'b0;
      done_rd_wr      = 1'b0;

    end
    // ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 5: write to half-full and after that, read and write at the same time

    // repeat(5)
      begin
        $display("Test case 5: write to half-full and after that, read and write at the same time");
        fork
          rd_and_wr( 2**AWIDTH/2, 2**AWIDTH );
          control_ptr(0,0,1);
          output_signal(0,0,1);
          test_output_signal(0,0,1);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;

      end
    // ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 6: Read and write at the same time without delaying at the beginning of reading process

    // repeat(5)
      begin
        $display("Test case 6: Read and write at the same time without delaying at the beginning of reading process");
        fork
          rd_and_wr( 0, 2**AWIDTH );
          control_ptr(0,0,1);
          output_signal(0,0,1);
          test_output_signal(0,0,1);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;
      end
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 7: Alternating read and write processes

    // repeat(5)
      begin
        $display("Test case 7: Alternating read and write processes");
        fork
          wr_only( 2**AWIDTH );
          rd_only( 2**AWIDTH + 2 );
          control_ptr(1,0,0);
          output_signal(1,0,0);
          test_output_signal(1,0,0);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;

      end
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 8: Write to full lifo, and read process (rdreq) begins immediately after wrreq has been deasserted.

    // repeat(5)
    begin
      $display("Test case 8: Write to full lifo, and read process (rdreq) begins immediately after wrreq has been deasserted");
      fork
        wr_only_non_idle( 2**AWIDTH +5 );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join 
      cnt_error();

      fork
        rd_only( 5 );
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();
      done_rd         = 1'b0;
      done_wr         = 1'b0;
      done_rd_wr      = 1'b0;

    end
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 9: Random rdreq and wrreq
    $display("Test case 9: Random rdreq and wrreq");
    fork
      wr_only_random( 1000 );
      rd_only_random( 1000 );
      control_ptr(0,1,0);
      output_signal(0,1,0);
      test_output_signal(0,1,0);
    join
    done_rd         = 1'b0;
    done_wr         = 1'b0;
    done_rd_wr      = 1'b0;
    cnt_error();
    // ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // // Test case 10: Write to lifo full twice and read out once (Test write to full )

    // repeat(5)
    begin
      $display("Test case 10: Write to lifo full twice and read out once (Test write to full )");

      fork
        wr_only( 2**AWIDTH );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join

      idle();

      fork
        wr_only( 2**AWIDTH );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join

      fork
        rd_only( 2**AWIDTH +2);
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();
      done_rd         = 1'b0;
      done_wr         = 1'b0;
      done_rd_wr      = 1'b0;

    end
    // ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 11:  Write to lifo full once and read out twice (Test read from empty)

    // repeat(5)
    begin
      $display("Test case 11:  Write to lifo full once and read out twice (Test read from empty)");

      fork
        wr_only( 2**AWIDTH );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join
      cnt_error();

      fork
        rd_only( 2**AWIDTH +2 );
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();
      idle();

      fork
        rd_only( 2**AWIDTH +2);
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();
      done_rd         = 1'b0;
      done_wr         = 1'b0;
      done_rd_wr      = 1'b0;

    end
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 12: Write to lifo full and after that read/write at the same time
    $display("Test case 12: Write to lifo full and after that read/write at the same time");
    fork
      wr_only( 2**AWIDTH );
      control_ptr(0,1,0);
      output_signal(0,1,0);
      test_output_signal(0,1,0);
    join
    cnt_error();

    fork
      rd_and_wr( 0, 2**AWIDTH  );
      control_ptr(0,0,1);
      output_signal(0,0,1);
      test_output_signal(0,0,1);
    join
    cnt_error();
    done_rd         = 1'b0;
    done_wr         = 1'b0;
    done_rd_wr      = 1'b0;
    ///////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // Test case 13: Write some value, read until empty, and after that, write/read at the same time

    // repeat(5)
      begin
        $display("Test case 13: Write some value, read until empty, and after that, write/read at the same time");
        fork
          wr_only( 10 );
          control_ptr(0,1,0);
          output_signal(0,1,0);
          test_output_signal(0,1,0);
        join 
        cnt_error();

        fork
          rd_only( 10 + 2);
          control_ptr(1,0,0);
          output_signal(1,0,0);
          test_output_signal(1,0,0);
        join
        cnt_error();
        repeat(2)
          idle();

        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;

        fork
          rd_and_wr( 0, 2**AWIDTH );
          control_ptr(0,0,1);
          output_signal(0,0,1);
          test_output_signal(0,0,1);
        join
        cnt_error();

      end
    ////////////////////////////////////////////////////////////////////////////////////////////

    repeat(2)
      idle();
    reset();

    // // // Test case 14: Reading process begins immediately after full, repeat 5 times with reset ( non idle before reset )

    repeat(3)
      begin
        $display("Test case 14: Reading process begins immediately after full, repeat 5 times with reset ( non idle before reset )");
        fork
          wr_only( 20 );
          control_ptr(0,1,0);
          output_signal(0,1,0);
          test_output_signal(0,1,0);
        join 
        cnt_error();

        fork
          rd_only_non_idle( 10 );
          control_ptr(1,0,0);
          output_signal(1,0,0);
          test_output_signal(1,0,0);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;
        // idle();
        reset();
      end
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    repeat(2)
      idle();
    reset();

    // // Test case 15: Writing 1 word to lifo, after that  make 100 transactions for simultaneous writing and reading
      begin
        $display("Test case 15: Writing 1 word to lifo, after that  make 100 transactions for simultaneous writing and reading");
        fork
          rd_and_wr( 1, 100 );
          control_ptr(0,0,1);
          output_signal(0,0,1);
          test_output_signal(0,0,1);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;
      end

    
    repeat(2)
      idle();
    reset();

      // // Test case 16: Writing 255 word to lifo, after that  make 256 transactions for simultaneous writing and reading
      begin
        $display("Test case 16: Writing 255 word to lifo, after that  make 100 transactions for simultaneous writing and reading");
        fork
          rd_and_wr( 255, 100 );
          control_ptr(0,0,1);
          output_signal(0,0,1);
          test_output_signal(0,0,1);
        join
        cnt_error();
        done_rd         = 1'b0;
        done_wr         = 1'b0;
        done_rd_wr      = 1'b0;
      end

    repeat(2)
      idle();
    reset();

    // Test case 17: Run to full and back to empty (REPEAT 5 TIMES)
    repeat(5)
    begin
      $display("Test case 17:  Run to full and back to empty (REPEAT 5 TIMES)");

      fork
        wr_only_non_idle( 2**AWIDTH );
        control_ptr(0,1,0);
        output_signal(0,1,0);
        test_output_signal(0,1,0);
      join
      cnt_error();

      fork
        rd_only_non_idle( 2**AWIDTH );
        control_ptr(1,0,0);
        output_signal(1,0,0);
        test_output_signal(1,0,0);
      join
      cnt_error();

      done_rd         = 1'b0;
      done_wr         = 1'b0;
      done_rd_wr      = 1'b0;

    end

    $display( "Test done!" );
    $stop();
    

  end

endmodule