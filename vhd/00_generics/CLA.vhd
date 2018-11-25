library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity CLA is
	generic (
		N		: natural;
		RADIX	: natural
	);
	port (
		A		: in	slv(N-1 downto 0);
		B		: in	slv(N-1 downto 0);
		CI		: in	sl;
		CO		: out	sl;
		S		: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of CLA is

	constant BLOCKS_NUM	: natural := N / (2**RADIX);
	constant TREE_DEPTH	: natural := log2(BLOCKS_NUM);
	
	type pre_compression_array is array (natural range <>) of slv(N-1 downto 0);
	signal pre_g, pre_p	: pre_compression_array(RADIX downto 0);
	
	subtype pg_array is slv(BLOCKS_NUM-1 downto 0);
	signal g, p			: pg_array;
	
	subtype TREE_RANGE is natural range BLOCKS_NUM-1 downto 0;
	
	signal carry	: slv(BLOCKS_NUM downto 0);

begin

	---- CARRY GENERATOR
	-----------------------
	-- Generate
	pre_g(0)(N-1 downto 1)	<= A(N-1 downto 1) and B(N-1 downto 1);
	pre_g(0)(0)				<= (A(0) and B(0)) or (p(0) and CI);
	
	-- Propagate
	pre_p(0)				<= A xor B;
	
	radix_reduce: for i in 0 to RADIX-1 generate
		pg_compressor_gen: entity work.PG_COMPRESSOR(structural)
		generic map (N => N/(2**i))
		port map (
			GIN		=> pre_g(i)(N/(2**i)-1 downto 0),
			PIN		=> pre_p(i)(N/(2**i)-1 downto 0),
			GOUT	=> pre_g(i+1)(N/(2**(i+1))-1 downto 0),
			POUT	=> pre_p(i+1)(N/(2**(i+1))-1 downto 0)
		);
	end generate;
	
	g <= pre_g(RADIX)(TREE_RANGE);
	p <= pre_p(RADIX)(TREE_RANGE);
	
	sparse_tree_gen: entity work.SPARSE_TREE(structural)
	generic map (N => BLOCKS_NUM)
	port map (
		GIN		=> g,
		PIN		=> p,
		GOUT	=> carry(BLOCKS_NUM downto 1)
	);
	carry(0) <= CI;
	
	---- SUM GENERATOR
	---------------------
	sum_generator_gen: entity work.SUM_GENERATOR(structural)
	generic map (
		N			=> N,
		BLOCK_SIZE	=> 2**RADIX
	)
	port map (
		A	=> A,
		B	=> B,
		CI	=> carry(BLOCKS_NUM-1 downto 0),
		S	=> S
	);
	CO	<= carry(BLOCKS_NUM);

end architecture;