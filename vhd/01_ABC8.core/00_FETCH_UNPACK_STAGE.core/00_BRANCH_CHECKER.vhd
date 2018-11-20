library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;
use work.ABC8_globals.all;

entity BRANCH_CHECKER is
	port (
		CLK			: in	sl;
		RST			: in	sl;
		ENB			: in	sl;
		STATUS		: in	status_reg_t;
		OPCODE		: in	ABC8_opcode_t;
		RESULT		: out	sl
	);
end entity;

architecture structural of BRANCH_CHECKER is

	type compare_t is (NONE, EQ, NE, LT, GT, LE, GE, NC);
	signal compare : compare_t;

	signal eq_unsign	: sl;
	signal ne_unsign	: sl;
	signal lt_unsign	: sl;
	signal gt_unsign	: sl;
	signal le_unsign	: sl;
	signal ge_unsign	: sl;
	
	signal eq_signed	: sl;
	signal ne_signed	: sl;
	signal lt_signed	: sl;
	signal gt_signed	: sl;
	signal le_signed	: sl;
	signal ge_signed	: sl;
	
	signal res_unsign	: sl;
	signal res_signed	: sl;
	signal curr_result	: sl;
	
	signal fet_out		: slv(0 downto 0);
	signal dec_reg_out	: slv(0 downto 0);
	signal exe_reg_out	: slv(0 downto 0);
	
begin

	--- CHECK COMPARE TYPE
	-------------------------
	compare	<= EQ when (OPCODE = BEQ) else
			   NE when (OPCODE = BNE) else
			   LT when (OPCODE = BLT) else
			   GT when (OPCODE = BGT) else
			   LE when (OPCODE = BLE) else
			   GE when (OPCODE = BGE) else
			   NC when (OPCODE = JMP) else
			   NONE;
			   
	---- GET CURRENT RESULT
	--------------------------
	eq_unsign	<=     STATUS(ZF_BIT);
	ne_unsign	<= not STATUS(ZF_BIT);
	lt_unsign	<= not STATUS(CF_BIT);
	gt_unsign	<=     STATUS(CF_BIT) and not STATUS(ZF_BIT);
	le_unsign	<= not STATUS(CF_BIT) or      STATUS(ZF_BIT);
	ge_unsign	<=     STATUS(CF_BIT);
	
	eq_signed	<=     STATUS(ZF_BIT);
	ne_signed	<= not STATUS(ZF_BIT);
	lt_signed	<= not STATUS(OF_BIT);
	gt_signed	<=     STATUS(OF_BIT) and not STATUS(ZF_BIT);
	le_signed	<= not STATUS(OF_BIT) or      STATUS(ZF_BIT);
	ge_signed	<=     STATUS(OF_BIT);
	
	res_unsign	<= eq_unsign when (compare = EQ) else
				   ne_unsign when (compare = NE) else
				   lt_unsign when (compare = LT) else
				   gt_unsign when (compare = GT) else
				   le_unsign when (compare = LE) else
				   ge_unsign when (compare = GE) else
				   '1'       when (compare = NC) else
				   '0';
				   
	res_signed	<= eq_signed when (compare = EQ) else
				   ne_signed when (compare = NE) else
				   lt_signed when (compare = LT) else
				   gt_signed when (compare = GT) else
				   le_signed when (compare = LE) else
				   ge_signed when (compare = GE) else
				   '1'       when (compare = NC) else
				   '0';
				   
	curr_result	<= res_signed when (STATUS(SF_BIT) = '1') else res_unsign;
	
	---- RESULT PIPELINE (BRANCH TARGET IS ONLY KNOWN AT EXECUTE STAGE)
	----------------------------------------------------------------------
	fet_out <= to_vec(curr_result);
	dec_reg: entity work.REG_N(behavioral)
	generic map (N => 1)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> ENB,
		DIN		=> fet_out,
		DOUT	=> dec_reg_out
	);
	exe_reg: entity work.REG_N(behavioral)
	generic map (N => 1)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> ENB,
		DIN		=> dec_reg_out,
		DOUT	=> exe_reg_out
	);
	
	---- OUTPUT
	--------------
	RESULT <= fet_out(0) or dec_reg_out(0) or exe_reg_out(0);
	
end architecture;