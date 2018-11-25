library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity SPARSE_TREE_ROW is
	generic (
		N	: natural;
		ROW	: natural
	);
	port (
		GIN		: in	slv(N-1 downto 0);
		PIN		: in	slv(N-1 downto 0);
		GOUT	: out	slv(N-1 downto 0);
		POUT	: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of SPARSE_TREE_ROW is

	constant CONTROL  : natural := 2**ROW;
	constant G_CUTOFF : natural := 2**(ROW+1);

begin

	g_block_gen: for i in 0 to G_CUTOFF-1 generate
		-- No block
		propagate_g: if (i mod N < CONTROL) generate
			GOUT(i) <= GIN(i);
			POUT(i) <= PIN(i);
		end generate;
		-- G block
		place_g: if (i mod N >= CONTROL) generate
			row_g_i: entity work.G_BLOCK(structural)
			port map (
				G_ik	=> GIN(i),
				P_ik	=> PIN(i),
				G_kj	=> GIN(CONTROL-1),
				G_ij	=> GOUT(i)
			);
			POUT(i) <= PIN(i);
		end generate;
	end generate;
	
	pg_block_gen: for i in G_CUTOFF to N-1 generate
		-- No block
		propagate_pg: if (i mod N < CONTROL) generate
			GOUT(i) <= GIN(i);
			POUT(i) <= PIN(i);
		end generate;
		-- PG block
		place_pg: if (i mod N >= CONTROL) generate
			row_pg_i: entity work.PG_BLOCK(structural)
			port map (
				G_ik	=> GIN(i),
				P_ik	=> PIN(i),
				G_kj	=> GIN(((i-CONTROL)/CONTROL)*CONTROL + (CONTROL-1)),
				P_kj	=> PIN(((i-CONTROL)/CONTROL)*CONTROL + (CONTROL-1)),
				G_ij	=> GOUT(i),
				P_ij	=> POUT(i)
			);
		end generate;
	end generate;

end architecture;