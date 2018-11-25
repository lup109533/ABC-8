library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

entity G_BLOCK is
	port (
		G_ik	: in	sl;
		P_ik	: in	sl;
		G_kj	: in	sl;
		G_ij	: out	sl
	);
end entity;

architecture structural of G_BLOCK is
begin

	G_ij <= G_ik or (P_ik and G_kj);

end architecture;