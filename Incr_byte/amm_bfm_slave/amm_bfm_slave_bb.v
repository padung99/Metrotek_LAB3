
module amm_bfm_slave (
	clk,
	reset,
	avs_writedata,
	avs_readdata,
	avs_address,
	avs_waitrequest,
	avs_write,
	avs_read,
	avs_byteenable,
	avs_readdatavalid);	

	input		clk;
	input		reset;
	input	[63:0]	avs_writedata;
	output	[63:0]	avs_readdata;
	input	[9:0]	avs_address;
	output		avs_waitrequest;
	input		avs_write;
	input		avs_read;
	input	[7:0]	avs_byteenable;
	output		avs_readdatavalid;
endmodule
