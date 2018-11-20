library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;
use work.ABC8_globals.all;

entity DECODE_STAGE is
	port (
		CLK			: in 	sl;
		RST			: in	sl;
		ENB			: in	sl;
		OPCODE		: in	ABC8_opcode_t;
		IMM_ARG		: in	ABC_arg16_t;
		CUR_MODE	: in	ABC8_mode_t;
		WRB_MODE	: in	ABC8_mode_t;
		REG_ADDR	: in	ABC8_reg_addr_t;
		WRB_ADDR	: in	ABC8_reg_addr_t;
		WRB_DATA	: in	ABC8_arg16_r;
	);
end entity;

architecture structural of DECODE_STAGE is

begin

	rf: entity work.REGISTER_FILE(behavioral)
	port map (
		CLK			=> CLK,
		RST			=> RST,
		ENB			=> ENB,
		REG_ADDR_RD	=> REG_ADDR,
		REG_ADDR_WR	=> WRB_ADDR,
		MODE_RD		=> CUR_MODE(MODE16_FLAG_BIT),
		MODE_WR		=> WRB_MODE(MODE16_FLAG_BIT),
		DIN			=> WRB_DATA,
		DOUT		=> rf_dout
	);
	
	

end architecture;