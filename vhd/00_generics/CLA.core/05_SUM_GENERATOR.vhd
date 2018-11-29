library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity SUM_GENERATOR is
	generic (
		N			: natural;
		BLOCK_SIZE	: natural
	);
	port (
		A	: in	slv(N-1 downto 0);
		B	: in	slv(N-1 downto 0);
		CI	: in	slv((N/BLOCK_SIZE)-1 downto 0);
		S	: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of SUM_GENERATOR is

	constant BLOCKS_NUM	: natural := N / BLOCK_SIZE;
	
	type slv_pairs is array (0 to 1) of slv(BLOCK_SIZE-1 downto 0);
	type sum_array is array (0 to BLOCKS_NUM-1) of slv_pairs;
	signal sum_candidate : sum_array;

begin

	rca_gen: for i in 0 to BLOCKS_NUM-1 generate
		-- Carry in = 0
		rca0_i: entity work.RCA(structural)
		generic map (N => BLOCK_SIZE)
		port map (
			A	=> A((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE),
			B	=> B((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE),
			CI	=> '0',
			S	=> sum_candidate(i)(0),
			CO	=> open
		);
		-- Carry in = 1
		rca1_i: entity work.RCA(structural)
		generic map (N => BLOCK_SIZE)
		port map (
			A	=> A((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE),
			B	=> B((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE),
			CI	=> '1',
			S	=> sum_candidate(i)(1),
			CO	=> open
		);
		-- Select sum
		S((i+1)*BLOCK_SIZE-1 downto i*BLOCK_SIZE) <= sum_candidate(i)(0) when (CI(i) = '0') else sum_candidate(i)(1);
	end generate;

end architecture;