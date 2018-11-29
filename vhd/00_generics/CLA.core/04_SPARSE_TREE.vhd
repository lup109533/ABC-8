library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity SPARSE_TREE is
	generic (
		N	: natural
	);
	port (
		GIN		: in	slv(N-1 downto 0);
		PIN		: in	slv(N-1 downto 0);
		GOUT	: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of SPARSE_TREE is

	constant ROWS_NUM : natural := log2(N);
	
	type   pg_array is array (natural range <>) of slv(N-1 downto 0);
	signal g : pg_array(ROWS_NUM downto 0);
	signal p : pg_array(ROWS_NUM downto 0);

begin

	g(0) <= GIN;
	p(0) <= PIN;

	tree_gen: for i in 0 to ROWS_NUM-1 generate
		row_i: entity work.SPARSE_TREE_ROW(structural)
		generic map (
			N	=> N,
			ROW	=> i
		)
		port map (
			GIN		=> g(i),
			PIN		=> p(i),
			GOUT	=> g(i+1),
			POUT	=> p(i+1)
		);
	end generate;
	
	GOUT <= g(ROWS_NUM);

end architecture;