library ieee;
use ieee.std_logic_1164.all;
use work.ABC8_globals.LO_BYTE;
use work.ABC8_globals.HI_BYTE;
use work.utils.all;

entity SHIFTER is
	generic (N : natural);
	port (
		DIN		: in	slv(N-1 downto 0);
		SHFT	: in	slv(log2(N) downto 0);
		DIR		: in	sl;
		ARITH	: in	sl;
		DOUT	: out	slv(3*N-1 downto 0)
	);
end entity;

architecture behavioral of SHIFTER is

	constant MAX_SHIFT		: integer := 2**SHFT'length-1;
	
	subtype BYTE0 is integer range  7 downto  0;
	subtype BYTE1 is integer range 15 downto  8;
	subtype BYTE2 is integer range 23 downto 16;
	subtype shift_amount_t is integer range 0 to MAX_SHIFT-1;
	
	type slv_array is array (natural range <>) of slv(2*N-1 downto 0);
	
	signal candidates	: slv_array(MAX_SHIFT-1 downto 0);
	signal shift_amount	: shift_amount_t;

begin

	shift_amount <= to_int(SHFT);

	candidates(0) <= DIN;
	get_candidates: process (DIN, SHFT) is
	begin
		-- Left
		if (DIR = '0') then
			for i in 1 to MAX_SHIFT-1 loop
				-- BYTE 0
				candidates(i)(i-1 downto 0)	<= zero(i);
				candidates(i)(N-1 downto i)	<= DIN(N-i-1 downto 0);
				-- BYTE 1
				candidates(i)(2*N-i-1 downto N)		<= DIN(N-1 downto N-i);
				candidates(i)(2*N-1   downto 2*N-i)	<= zero(i);
			end loop;
		-- Right
		else
			for i in 1 to MAX_SHIFT-1 loop
				-- BYTE 0
				candidates(i)(N-i-1 downto   0)	<= zero(MAX_SHIFT-i);
				candidates(i)(N-1   downto N-i)	<= DIN(i-1 downto 0);
				-- BYTE 1
				candidates(i)(2*N-i-1 downto N)		<= DIN(N-1 downto i);
				candidates(i)(2*N-1   downto 2*N-i)	<= fill(ARITH, i);
			end loop;
		end if;
	end process;
	
	-- Select candidate
	DOUT(BYTE0) <= candidates(shift_amount)(LO_BYTE) when (DIR = '1') else zero(8);
	DOUT(BYTE1)	<= candidates(shift_amount)(HI_BYTE) when (DIR = '1') else candidates(shift_amount)(LO_BYTE);
	DOUT(BYTE2) <= candidates(shift_amount)(HI_BYTE) when (DIR = '0') else fill(ARITH,8);

end architecture;