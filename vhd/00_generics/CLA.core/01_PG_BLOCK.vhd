library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity PG_BLOCK is
	port (
		G_ik	: in	sl;
		P_ik	: in	sl;
		G_kj	: in	sl;
		P_kj	: in	sl;
		P_ij	: out	sl;
		G_ij	: out	sl
	);
end entity;

architecture structural of PG_BLOCK is
begin

	P_ij <= P_ik and P_kj;
	G_ij <= G_ik or (P_ik and G_kj);

end architecture;