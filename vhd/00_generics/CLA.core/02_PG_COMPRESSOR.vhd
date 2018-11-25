library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity PG_COMPRESSOR is
	generic (N	: natural);
	port (
		GIN		: in	slv(N-1   downto 0);
		PIN		: in	slv(N-1   downto 0);
		GOUT	: out	slv(N/2-1 downto 0);
		POUT	: out	slv(N/2-1 downto 0)
	);
end entity;

architecture structural of PG_COMPRESSOR is

begin

	-- First block
	g_block_gen: entity work.G_BLOCK(structural)
	port map (
		G_ik	=> GIN(1),
		G_kj	=> GIN(0),
		P_ik	=> PIN(1),
		G_ij	=> GOUT(0)
	);
	POUT(0)		<= PIN(0);
	
	pg_block_gen: for i in 1 to N/2-1 generate
		pg_block_i: entity work.PG_BLOCK(structural)
	port map (
		G_ik	=> GIN(i*2+1),
		G_kj	=> GIN(i*2),
		P_ik	=> PIN(i*2+1),
		P_kj	=> PIN(i),
		G_ij	=> GOUT(i),
		P_ij	=> POUT(i)
	);
	end generate;

end architecture;