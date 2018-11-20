library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;
-------------------------------------------------------
-- N-bit register with active-low asynchronous reset --
-------------------------------------------------------
entity REG_N is
	generic (N : natural);
	port (
		CLK		: in	sl;
		RST		: in	sl;
		ENB		: in	sl;
		DIN		: in	slv(N-1 downto 0);
		DOUT	: out	slv(N-1 downto 0)
	);
end entity;

architecture behavioral of REG_N is
begin

	proc: process(CLK, RST, ENB) is
	begin
		if (RST = '0') then
			DOUT <= zero(N);
		elsif rising_edge(CLK) and ENB = '1' then
			DOUT <= DIN;
		end if;
	end process;

end architecture;