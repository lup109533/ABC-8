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
		IMM_ARG		: in	ABC8_arg16_t;
		CUR_MODE	: in	ABC8_mode_t;
		REG_ADDR	: in	ABC8_reg_addr_t;
		WRB_ENB		: in	sl;
		WRB_ADDR	: in	ABC8_reg_addr_t;
		WRB_DATA	: in	ABC8_arg16_t;
		DOUT		: out	ABC8_arg16_t
	);
end entity;

architecture structural of DECODE_STAGE is

	signal optype		: ABC8_optype_t;
	signal rf_wr_enb	: sl;
	signal rf_dout		: ABC8_arg16_t;

begin

	rf: entity work.REGISTER_FILE(behavioral)
	port map (
		CLK			=> CLK,
		RST			=> RST,
		ENB			=> rf_wr_enb,
		REG_ADDR_RD	=> REG_ADDR,
		REG_ADDR_WR	=> WRB_ADDR,
		DIN			=> WRB_DATA,
		DOUT		=> rf_dout
	);
	
	optype		<= OPCODE(OPTYPE_RANGE);
	rf_wr_enb	<= ENB and WRB_ENB;
	
	DOUT		<= IMM_ARG when (optype = I_TYPE) else rf_dout;

end architecture;