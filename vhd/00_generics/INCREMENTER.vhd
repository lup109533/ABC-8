library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;
------------------------------------------------------------------------------------------
-- Carry-select adder-like structure designed to increment binary values by powers of 2 --
------------------------------------------------------------------------------------------
entity INCREMENTER is
	generic (
		N			: natural;
		INCR_AMOUNT	: natural := 1;
		BLOCK_SIZE	: natural := 4
	);
	port (
		DIN		: in	slv(N-1 downto 0);
		DOUT	: out	slv(N-1 downto 0);
		COUT	: out	sl
	);
end entity;

architecture structural of INCREMENTER is

	constant blocks_num			: integer := N/BLOCK_SIZE;
	constant increment			: slv(N-1 downto 0) := to_slv(INCR_AMOUNT, N);
	constant first_nonzero_bit	: integer := priority_low2high(increment);
	constant first_full_block	: integer := first_nonzero_bit/BLOCK_SIZE + 1;
	constant partial_block_size	: integer := first_full_block*BLOCK_SIZE - first_nonzero_bit;
	
	signal carry	: slv(blocks_num-1 downto 0);

begin
	
	propagate_unchanged: if first_nonzero_bit > 0 generate
		route_signals: for i in 0 to first_nonzero_bit-1 generate
			DOUT(i) <= DIN(i);
		end generate;
	end generate;
	
	partial_block: entity work.INCR_BLOCK(structural)
	generic map (N => partial_block_size)
	port map (
		A	=> DIN(first_full_block*BLOCK_SIZE-1 downto first_nonzero_bit),
		C	=> carry(first_full_block-1),
		S	=> DOUT(first_full_block*BLOCK_SIZE-1 downto first_nonzero_bit)
	);
	
	gen_full_blocks: for i in first_full_block to blocks_num-1 generate
		full_block: entity work.INCR_CSA_BLOCK(structural)
		generic map (N => BLOCK_SIZE)
		port map (
			A	=> DIN((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE),
			B	=> carry(i-1),
			C	=> carry(i),
			S	=> DOUT((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE)
		);
	end generate;
	
	COUT <= carry(blocks_num-1);

end architecture;