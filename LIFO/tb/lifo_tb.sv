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

//non-synthesys output
logic [DWIDTH-1:0]  q_tb;

logic               almost_empty_tb;
logic               empty_tb;
logic               almost_full_tb;
logic               full_tb;
logic [AWIDTH:0]    usedw_tb;

logic valid_rd;
logic valid_wr;


int                 cnt_wr_data;

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
    // rdreq_i_tb = 0;

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
          // if( rdreq_i_tb && !empty_o_tb )
          //   begin
          //     rd_data.push_front( q_o_tb );
          //     $display( "q_o: %x", q_o_tb );
          //   end

        repeat_done = 1'b1;
        end
  if( repeat_done )
    break;
  end
//Add 1 more last data in to queue
// rd_data.push_front( q_o_tb );
// $display( "q_o: %x", q_o_tb );

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
      begin
        rd_data.push_front( q_o_tb );
        $display( "q_o: %x", q_o_tb );
      end

    if( rd_done )
      break;
  end
rd_data.pop_back();
rd_data.push_front( q_o_tb );
$display( "q_o: %x", q_o_tb );

endtask

task non_synthesys_signal( input bit _wr_only,
                                 bit _rd_only,
                                 bit _rd_and_wr
                         );
forever
  begin
    // @( posedge clk_i_tb )
    if( lifo_ptr == 2**AWIDTH )
      full_tb = 1'b1;
    else
      full_tb = 1'b0;

    if( lifo_ptr >= ALMOST_FULL_VALUE )
      almost_full_tb = 1'b1;
    else
      almost_full_tb = 1'b0;

    if( lifo_ptr == 0 )
      empty_tb = 1'b1;
    else
      empty_tb = 1'b0;

    if( lifo_ptr <= ALMOST_EMPTY_VALUE )
      almost_empty_tb = 1'b1;
    else
      almost_empty_tb = 1'b0;
 
    if( _wr_only && wr_done )
      break;
    if( ( _rd_only || _rd_and_wr ) && rd_done )
      break;
    ##1;
    // @( posedge clk_i_tb );
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

// task wr_request ( input int _lower_wr,
//                         int _upper_wr,
//                   mailbox #( logic [DWIDTH-1:0] ) _data_gen,
//                   mailbox #( logic [DWIDTH-1:0] ) _wr_data
//                 );

// logic [DWIDTH-1:0] data_wr;
// int pause_wr;
// int cnt_wr;

// while( _data_gen.num() != 0 )
//   begin
//     if( pause_wr == 0 )
//       begin
//         cnt_wr_data++;
//         _data_gen.get( data_wr );
//         //Change _upper_wr,_lower_wr to change write frequency
//         pause_wr   = $urandom_range( _upper_wr,_lower_wr );
//         wrreq_i_tb = 0;
//       end
//     else
//       wrreq_i_tb = 1;

//     if( full_o_tb == 1'b0 && wrreq_i_tb == 1'b1 )
//       begin
//         _wr_data.put( data_wr );
//         data_i_tb = data_wr;
//       end
//     pause_wr--;
//     ##1;
//   end

// wr_done = 1;
// wrreq_i_tb = 0;

// endtask

// task rd_request ( input int cnt_data_rd,
//                      int _lower_rd,
//                      int _upper_rd
//                 );

// int pause_rd;
// int i;
// i = 0;
// while( cnt_wr_data < cnt_data_rd )
//   begin
//     if( pause_rd == 0 )
//       begin
//         //Change _upper_rd,_lower_rd to change read frequency
//         pause_rd   = $urandom_range( _upper_rd,_lower_rd );
//         rdreq_i_tb = 0;
//       end
//     else
//       rdreq_i_tb = 1;
   
//     if( empty_o_tb == 1'b0 && rdreq_i_tb == 1'b1 )
//       begin
//         rd_data.push_front( q_o_tb );
//       end
//     pause_rd--;
//     ##1;
//   end

// rd_done = 1'b1;
// rdreq_i_tb = 0;

// endtask

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
        $display("data write in: %x, data read out: %x", new_data_wr, new_data_rd );
        if( new_data_wr != new_data_rd )
          begin
            // $error("q_o error: data write in: %x, data read out: %x", new_data_wr, new_data_rd );
            q_o_error = 1;
          end
      end
  end

while( _wr_data.num() != 0 )
  begin
    _wr_data.get( new_data_wr );
    $display("wr data: %x",new_data_wr );
  end

if( q_o_error )
  $error("q_o error!!");
else
  $display( "no error on q_o " );

endtask

task test_output_signal( input bit _wr_only,
                               bit _rd_only,
                               bit _rd_and_wr
                       );

forever
  begin
  @( posedge clk_i_tb );
//TEST: usew_o 
    if( lifo_ptr != usedw_o_tb )
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

    if( _wr_only && wr_done )
      break;
    if( ( _rd_only || _rd_and_wr ) && rd_done )
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


initial
  begin
    srst_i_tb = 1;
    ##1;
    srst_i_tb = 0;

    // //////////////////Test 1 //////////////////
    // //Write only to lifo (Don't make lifo full)
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
    
    // ///////////////Test 2////////////////
    // $display("###Test: Write until full");
    // //Write to lifo until full
    // gen_data( data_gen, 2**AWIDTH+5 );
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

    // ///////////////Test 3////////////////
    // $display("###Test: Write until full");
    // //Write to lifo until full
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

    /////////////////Test 4 ///////////////
    $display("###Read and write");
    gen_data( data_gen, 2**AWIDTH+5 );
    
    fork
      write_rq( data_gen, wr_data);
      inr_ptr();
      read_until_empty(0, 2**AWIDTH+5);
      decr_ptr();
      test_output_signal(0,0,1);
      non_synthesys_signal(0,0,1);
    join
    cnt_error();

    // //////////////////Test 4///////////////
    // $display(" Write request more than read request ");
    // gen_data( data_gen, 2**AWIDTH+5 );

    // fork
    //   wr_request( 4,6, data_gen, wr_data );
    //   inr_ptr();
    //   decr_ptr();
    //   non_synthesys_signal();
    //   rd_request( 2**AWIDTH + 5, 1,2 );
    // join


    // // //////////////////Test 5///////////////
    // $display(" Read request more than write request ");
    // gen_data( data_gen, 2**AWIDTH+5 );

    // fork
    //   wr_request( 1,2, data_gen, wr_data );
    //   inr_ptr();
    //   decr_ptr();
    //   non_synthesys_signal();
    //   rd_request( 2**AWIDTH + 5, 4,6 );
    // join

    $display( "Test done!" );
    $stop();

  end

endmodule