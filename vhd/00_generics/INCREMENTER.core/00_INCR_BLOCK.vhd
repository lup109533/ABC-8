library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;
--------------------------------------------------------------
-- Simplified RCA structure to increment binary values by 1 --
--------------------------------------------------------------
entity INCR_BLOCK is
	generic (N : natural);
	port (
		A	: in	slv(N-1 downto 0);
		C	: out	sl;
		S	: out	slv(N-1 downto 0)
	);
end entity;

architecture structural of INCR_BLOCK is

	signal carry : slv(N downto 0);

begin

	make_incr: for i in 0 to N-1 generate
		ha0: entity work.HA
		port map (
			A	=> A(i),
			B	=> carry(i),
			S	=> S(i),
			C	=> carry(i+1)
		);
	end generate;
	carry(0)	<= '1';
	C			<= carry(N);

end architecture;