library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;
use work.ABC8_globals.all;

entity REGISTER_FILE is
	port (
		CLK			: in	sl;
		RST			: in	sl;
		ENB			: in	sl;
		REG_ADDR_RD	: in	ABC8_reg_addr_t;
		REG_ADDR_WR	: in	ABC8_reg_addr_t;
		DIN			: in	ABC8_arg16_t;
		DOUT		: out	ABC8_arg16_t
	);
end entity;

architecture behavioral of REGISTER_FILE is

	constant MODE8_BIT	: sl := '0';
	constant MODE16_BIT	: sl := '1';

	subtype int_addr_t is integer range 0 to 7;
	
	signal mode8_addr_rd	: ABC8_reg_addr_t;
	signal mode16_addr_rd	: ABC8_reg_addr_t;
	signal mode8_addr_wr	: ABC8_reg_addr_t;
	signal mode16_addr_wr	: ABC8_reg_addr_t;
	
	signal rd_index0		: int_addr_t;
	signal rd_index1		: int_addr_t;
	signal wr_index0		: int_addr_t;
	signal wr_index1		: int_addr_t;
	
	constant REGISTER_SIZE	: natural := 8;
	constant MEMORY_SIZE	: natural := 8;
	
	type memory_t is array (0 to MEMORY_SIZE-1) of ABC8_arg8_t;
	signal memory	: memory_t;

begin

	---- GET BASE ADDRESS
	------------------------
	mode8_addr_rd	<= REG_ADDR_RD;
	mode8_addr_wr	<= REG_ADDR_WR;
	
	---- GET OFFSET ADDRESS FOR 16 BIT MODE
	------------------------------------------
	-- READ
	incr_rd: entity work.INCREMENTER(structural)
	generic map (
		N			=> 3,
		INCR_AMOUNT	=> 1,
		BLOCK_SIZE	=> 3
	)
	port map (
		DIN		=> mode8_addr_rd,
		DOUT	=> mode16_addr_rd,
		COUT	=> open
	);
	-- WRITE
	incr_wr: entity work.INCREMENTER(structural)
	generic map (
		N			=> 3,
		INCR_AMOUNT	=> 1,
		BLOCK_SIZE	=> 3
	)
	port map (
		DIN		=> mode8_addr_wr,
		DOUT	=> mode16_addr_wr,
		COUT	=> open
	);
	
	---- CONVERT ADDRESSES
	-------------------------
	rd_index0	<= to_int(mode8_addr_rd);
	rd_index1	<= to_int(mode16_addr_rd);
	wr_index0	<= to_int(mode8_addr_wr);
	wr_index1	<= to_int(mode16_addr_wr);
	
	---- MEMORY MANAGER
	----------------------
	memory_manager: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			for i in 0 to MEMORY_SIZE-1 loop
				memory(i) <= zero(REGISTER_SIZE);
			end loop;
		elsif (rising_edge(CLK) and ENB = '1') then
			memory(wr_index0) <= DIN(LO_BYTE);
			memory(wr_index1) <= DIN(HI_BYTE);
		end if;
	end process;
	
	DOUT(LO_BYTE) <= memory(rd_index0);
	DOUT(HI_BYTE) <= memory(rd_index1);

end architecture;