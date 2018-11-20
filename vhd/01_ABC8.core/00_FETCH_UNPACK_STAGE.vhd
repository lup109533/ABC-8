library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils.all;
use work.ABC8_globals.all;

entity FETCH_UNPACK_STAGE is
	port (
		CLK				: in	sl;
		RST				: in	sl;
		ENB				: in	sl;
		-- ICACHE INTERFACE
		INSTR_ADDR		: out	ABC8_addr16_t;
		INSTRUCTION		: in	ABC8_instr_t;
		IMMEDIATE_ARG	: in	ABC8_arg16_t;
		-- DATA FROM ELSEWHERE
		CUR_MODE		: in	ABC8_mode_t;
		LARGE_ADDR		: in	sl;
		STATUS			: in	status_reg_t;
		BRANCH_TARGET	: in	ABC8_addr16_t;
		-- STAGE OUTPUTS
		READY			: out	sl;
		OPCODE			: out	ABC8_opcode_t;
		MODE			: out	ABC8_mode_t;
		REG_ADDR		: out	ABC8_reg_addr_t;
		IMM_ARG			: out	ABC8_arg16_t
	);
end entity;

architecture structural of FETCH_UNPACK_STAGE is

	signal opcode_s		: ABC8_opcode_t;
	signal optype_s		: ABC8_optype_t;
	signal mode_s			: ABC8_mode_t;
	signal reg_addr_s		: ABC8_reg_addr_t;
	signal arg_low		: ABC8_arg8_t;
	signal arg_high		: ABC8_arg8_t;
	
	signal curr_pc		: ABC8_addr16_t;
	signal incr_pc		: ABC8_addr16_t;
	signal next_pc		: ABC8_addr16_t;

	type fetch_state_t is (NORMAL, IMM_8_BIT, IMM_16_BIT_LO, IMM_16_BIT_HI);
	signal state		: fetch_state_t;
	signal is_imm_instr	: sl;
	signal is_16bit		: sl;
	
	signal instr_buffer_byte0	: ABC8_arg8_t;
	signal instr_buffer_byte1	: ABC8_arg8_t;
	signal instr_buffer_byte2	: ABC8_arg8_t;
	signal instr				: ABC8_instr_t;
	signal imm_arg_lo			: ABC8_arg8_t;
	signal imm_arg_hi			: ABC8_arg8_t;
	
	signal clk_gate		: sl;
	signal take_branch	: sl;
	signal ready_s		: sl;
	
begin

	---- FETCH STAGE FSM
	-----------------------
	fsm: process (CLK, RST) is
	begin
		if (RST = '0') then
			state <= NORMAL;
		elsif (rising_edge(CLK)) then
			case (state) is
				when NORMAL =>
					if (optype_s = I_TYPE) then
						if (CUR_MODE(MODE16_FLAG_BIT) = '1') then
							state <= IMM_16_BIT_LO;
						else
							state <= IMM_8_BIT;
						end if;
					else
						state <= NORMAL;
					end if;
				
				when IMM_8_BIT =>
					state <= NORMAL;
					
				when IMM_16_BIT_LO =>
					state <= IMM_16_BIT_HI;
					
				when IMM_16_BIT_HI =>
					state <= NORMAL;
			end case;
		end if;
	end process;
	
	is_imm_instr	<= '1' when (state = NORMAL and optype_s = I_TYPE) else
					   '1' when (state = IMM_16_BIT_LO)              else
					   '0';
					   
	is_16bit		<= '1' when (state = IMM_16_BIT_LO) else
					   '0';

	---- GET INSTRUCTION & IMMEDIATE ARGUMENT
	--------------------------------------------
	instr_buffer_byte0 <= INSTRUCTION;
	instr_shift_reg: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			instr_buffer_byte1 <= zero(instr_buffer_byte1'length);
			instr_buffer_byte2 <= zero(instr_buffer_byte2'length);
		elsif (rising_edge(CLK)) then
			if (ENB = '1' and is_imm_instr = '1') then
				instr_buffer_byte1 <= instr_buffer_byte0;
			end if;
			if (ENB = '1' and is_imm_instr = '1' and is_16bit = '1') then
				instr_buffer_byte2 <= instr_buffer_byte1;
			end if;
		end if;
	end process;
	
	instr		<= instr_buffer_byte0 when (state = NORMAL)        else
				   instr_buffer_byte1 when (state = IMM_8_BIT)     else
				   instr_buffer_byte1 when (state = IMM_16_BIT_LO) else
				   instr_buffer_byte2 when (state = IMM_16_BIT_HI);
				   
	imm_arg_lo	<= instr_buffer_byte1;
	imm_arg_hi	<= instr_buffer_byte0;

	---- UNPACK INSTRUCTION
	--------------------------
	opcode_s	<= instr(OPCODE_RANGE);
	optype_s	<= instr(OPTYPE_RANGE);
	mode_s		<= instr(MODE_RANGE);
	reg_addr_s	<= instr(REG_ADDR_RANGE);
	
	
	---- PC
	----------
	-- Low byte
	PC0: entity work.REG_N(behavioral)
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> ENB,
		DIN		=> next_pc(LO_BYTE),
		DOUT	=> curr_pc(LO_BYTE)
	);
	-- High byte
	PC1: entity work.REG_N(behavioral)
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> clk_gate,
		DIN		=> next_pc(HI_BYTE),
		DOUT	=> curr_pc(HI_BYTE)
	);
	clk_gate <= LARGE_ADDR and ENB;	-- Activate 16-bit address only if flag set
	
	-- Calculate next PC
	NEXT_PC0: entity work.INCREMENTER(structural)
	generic map (
		N			=> 16,
		INCR_AMOUNT	=> 1
	)
	port map (
		DIN		=> curr_pc,
		DOUT	=> incr_pc,
		COUT	=> open
	);
	-- Select between next PC and calculated branch target
	next_pc	<= BRANCH_TARGET when (take_branch = '1') else incr_pc;
	
	---- BRANCHING MANAGEMENT
	----------------------------
	branch_check: entity work.BRANCH_CHECKER(structural)
	port map (
		CLK			=> CLK,
		RST			=> RST,
		ENB			=> ready_s, -- Output only when fetch cycle complete
		STATUS		=> STATUS,
		OPCODE		=> opcode_s,
		RESULT		=> take_branch
	);
	
	---- OUTPUTS
	---------------
	ready_s	<= '1' when (state = NORMAL and optype_s /= I_TYPE) else
			   '1' when (state = IMM_8_BIT)                     else
			   '1' when (state = IMM_16_BIT_HI)                 else
			   '0';
	READY		<= ready_s;
	OPCODE		<= NOP when (take_branch = '1') else opcode_s;
	REG_ADDR	<= reg_addr_s;
	IMM_ARG		<= imm_arg_hi & imm_arg_lo;
	MODE		<= mode_s when (opcode_s = SET) else CUR_MODE;

end architecture;