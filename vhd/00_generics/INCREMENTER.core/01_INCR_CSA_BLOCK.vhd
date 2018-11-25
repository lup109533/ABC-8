library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;
------------------------------------------
-- Carry select block with incrementers --
------------------------------------------
entity INCR_CSA_BLOCK is
	generic (N : natural);
	port (
		A	: in	slv(N-1 downto 0);
		B	: in	sl;
		C	: out	sl;
		S	: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of INCR_CSA_BLOCK is

	signal carry_candidate	: sl;
	signal sum_candidate	: slv(N-1 downto 0);

begin

	incr: entity work.INCR_BLOCK(structural)
	generic map (N => N)
	port map (
		A	=> A,
		C	=> carry_candidate,
		S	=> sum_candidate
	);
	
	S	<= A   when (B = '0') else sum_candidate;
	C	<= '0' when (B = '0') else carry_candidate;

end architecture;