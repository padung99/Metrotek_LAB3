	component amm_bfm_slave is
		port (
			clk               : in  std_logic                     := 'X';             -- clk
			reset             : in  std_logic                     := 'X';             -- reset
			avs_writedata     : in  std_logic_vector(63 downto 0) := (others => 'X'); -- writedata
			avs_readdata      : out std_logic_vector(63 downto 0);                    -- readdata
			avs_address       : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- address
			avs_waitrequest   : out std_logic;                                        -- waitrequest
			avs_write         : in  std_logic                     := 'X';             -- write
			avs_read          : in  std_logic                     := 'X';             -- read
			avs_byteenable    : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- byteenable
			avs_readdatavalid : out std_logic                                         -- readdatavalid
		);
	end component amm_bfm_slave;

	u0 : component amm_bfm_slave
		port map (
			clk               => CONNECTED_TO_clk,               --       clk.clk
			reset             => CONNECTED_TO_reset,             -- clk_reset.reset
			avs_writedata     => CONNECTED_TO_avs_writedata,     --        s0.writedata
			avs_readdata      => CONNECTED_TO_avs_readdata,      --          .readdata
			avs_address       => CONNECTED_TO_avs_address,       --          .address
			avs_waitrequest   => CONNECTED_TO_avs_waitrequest,   --          .waitrequest
			avs_write         => CONNECTED_TO_avs_write,         --          .write
			avs_read          => CONNECTED_TO_avs_read,          --          .read
			avs_byteenable    => CONNECTED_TO_avs_byteenable,    --          .byteenable
			avs_readdatavalid => CONNECTED_TO_avs_readdatavalid  --          .readdatavalid
		);

