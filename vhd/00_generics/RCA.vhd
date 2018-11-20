library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;
--------------------------------------------------------------
-- Structural implementation of an N-bit ripple-carry adder --
--------------------------------------------------------------
entity HA is
	port (
		A	: in	sl;
		B	: in	sl;
		S	: out	sl;
		C	: out	sl
	);
end entity;

architecture structural of HA is
begin

	S <= A xor B;
	C <= A and B;

end architecture;


library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity FA is
	port (
		A	: in	sl;
		B	: in	sl;
		CI	: in	sl;
		S	: out	sl;
		CO	: out	sl
	);
end entity;

architecture structural of FA is
	
	signal partial_sum : sl;

begin

	partial_sum	<= A xor B;
	S			<= partial_sum xor CI;
	CO			<= (A nand B) nand (partial_sum nand CI);

end architecture;


library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity RCA is
	generic (
		N 				: natural;
		HAS_CARRY_IN	: boolean := true
	);
	port (
		A	: in	slv(N-1 downto 0);
		B	: in	slv(N-1 downto 0);
		S	: out	slv(N-1 downto 0);
		CI	: in	sl;
		CO	: out	sl
	);
end entity;

architecture structural of RCA is

	signal carry : slv(N-2 downto 0);

begin
	
	make_rca: for i in 0 to N-1 generate
		first_fa: if i = 0 generate
			first_ha_no_carry: if not HAS_CARRY_IN generate
				ha0: entity work.HA(structural)
				port map (
					A	=> A(i),
					B	=> B(i),
					S	=> S(i),
					C	=> carry(i)
				);
			end generate;
			first_fa_carry: if HAS_CARRY_IN generate
				fa0: entity work.FA(structural)
				port map (
					A	=> A(i),
					B	=> B(i),
					S	=> S(i),
					CI	=> CI,
					CO	=> carry(i)
				);
			end generate;
		end generate;
		other_fas: if i > 0 generate
			fa0: entity work.FA(structural)
			port map (
				A	=> A(i),
				B	=> B(i),
				S	=> S(i),
				CI	=> carry(i-1),
				CO	=> carry(i)
			);
		end generate;
	end generate;
	CO <= carry(N-2);

end architecture;