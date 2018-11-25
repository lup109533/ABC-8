library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;
use work.ABC8_globals.all;

entity EXECUTE_STAGE is
	port (
		CLK			: in	sl;
		RST			: in	sl;
		ENB			: in	sl;
		CUR_MODE	: in	ABC8_mode_t;
		REG_ADDR	: in	ABC8_reg_addr_t;
		OPCODE		: in	ABC8_opcode_t;
		OPERAND		: in	ABC8_arg16_t;
		READY		: out	sl;
	);
end entity;

architecture structural of EXECUTE_STAGE is

begin

	operand2 <= OPERAND;

	---- ACCUMULATOR
	-------------------
	-- BYTE 0
	accumulator0: entity work.REG_N(behavioral)
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode8_bit_enb,
		DIN		=> result(LO_BYTE),
		DOUT	=> operand2(LO_BYTE)
	);
	-- BYTE 1
	accumulator1: entity work.REG_N(behavioral)
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> result(HI_BYTE),
		DOUT	=> operand2(HI_BYTE)
	);
	
	---- ALU & FPU
	--------------------
	alu0: entity work.ALU(structural)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		MODE	=> CUR_MODE,
		OP1		=> operand1,
		OP2		=> operand2,
		OPCODE	=> OPCODE,
		DOUT	=> alu0_dout
	);

end architecture;