library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_misc.or_reduce;
use work.utils.all;
use work.ABC8_globals.all;

entity ALU is
	port (
		CLK		: in	sl;
		RST		: in	sl;
		ENB		: in	sl;
		MODE	: in	ABC8_mode_t;
		OP1		: in	ABC8_arg16_t;
		OP2		: in	ABC8_arg16_t;
		OPCODE	: in	ABC8_opcode_t;
		READY	: out	sl;
		DOUT	: out	ABC8_arg16_t;
		CMP_OUT	: out	ABC8_status_t
	);
end entity;

architecture structural of ALU is

	subtype BYTE0 is integer range  7 downto  0;
	subtype BYTE1 is integer range 15 downto  8;
	subtype BYTE2 is integer range 23 downto 16;

	type output_type_t is (ARITH, LOGIC, SHIFT);
	signal output_type : output_type_t;

begin

	---- FSM
	-----------
	fsm: process (CLK, RST, ENB) is
	begin
		if (RST = '0') then
			state <= STAGE1;
		elsif (rising_edge(CLK) and ENB = '1') then
			case (state) is
				when STAGE1 =>
					if (MODE(MODE16_FLAG_BIT) = '1') then
						state <= STAGE2;
					else
						state <= STAGE1;
					end if;
					
				when STAGE2 =>
					state <= STAGE1;
			end case;
		end if;
	end process;

	
	---- DECODE OPCODE
	---------------------
	op_is_subtraction	<= '1' when (OPCODE = SUB_r) else
						   '1' when (OPCODE = SUB_i) else
						   '1' when (OPCODE = CMP)   else
						   '0';
						   
	output_type			<= SHIFT when (OPCODE = SLL_r) else
						   SHIFT when (OPCODE = SRL_r) else
						   SHIFT when (OPCODE = SRA_r) else
						   SHIFT when (OPCODE = SLL_i) else
						   SHIFT when (OPCODE = SRL_i) else
						   SHIFT when (OPCODE = SRA_i) else
						   LOGIC when (OPCODE = AND_r) else
						   LOGIC when (OPCODE = ORR_r) else
						   LOGIC when (OPCODE = XOR_r) else
						   LOGIC when (OPCODE = AND_i) else
						   LOGIC when (OPCODE = ORR_i) else
						   LOGIC when (OPCODE = XOR_i) else
						   ARITH;

						   
	---- ADDER/SUBTRACTOR
	------------------------
	operand1(LO_BYTE) <= OP1(LO_BYTE);
	operand2(LO_BYTE) <= OP2(LO_BYTE) xor op_is_subtraction;
	
	-- STAGE 1
	addsub0: entity work.CLA(structural)
	generic map (
		N			=> 8,
		BLOCK_SIZE	=> 4
	)
	port map (
		A	=> operand1(LO_BYTE),
		B	=> operand2(LO_BYTE),
		S	=> addsub_out(LO_BYTE),
		CI	=> op_is_subtraction,
		CO	=> carry(0)
	);
	-- PIPELINE
	addsub_pipe_carry: entity work.REG_N
	generic map (N => 1)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> carry(0 downto 0),
		DOUT	=> carry(1 downto 1)
	);
	addsub_pipe_operand1: entity work.REG_N
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> operand1(HI_BYTE),
		DOUT	=> operand1_hi_byte
	);
	addsub_pipe_operand2: entity work.REG_N
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> ENB,
		DIN		=> operand2(HI_BYTE),
		DOUT	=> operand2_hi_byte
	);
	-- STAGE 2
	addsub1: entity work.CLA(structural)
	generic map (
		N			=> 8,
		BLOCK_SIZE	=> 4
	)
	port map (
		A	=> operand1_hi_byte,
		B	=> operand2_hi_byte,
		S	=> addsub_out(HI_BYTE),
		CI	=> carry(1),
		C	=> carry(2)
	);
	
	-- Extract useful values for comparison
	zero_sum0	<= not or_reduce(addsub_out(LO_BYTE));
	zero_sum1	<= not or_reduce(addsub_out(HI_BYTE));
	sign0(0)	<= operand1(LO_BYTE)(7);
	sign0(1)	<= operand2(LO_BYTE)(7);
	sign0(2)	<= addsub_out(LO_BYTE)(7);
	sign1(0)	<= operand1(HI_BYTE)(7);
	sign1(1)	<= operand2(HI_BYTE)(7);
	sign1(2)	<= addsub_out(HI_BYTE)(7);
	
	
	---- COMPARATOR
	------------------
	-- Record current sign
	sign_flag	<= MODE(SIGN_FLAG_BIT);
	-- Check if lo byte (if on 8 bits) or if both bytes (if on 16 bits) of the result are zero
	zero_flag	<= zero_sum0 when (MODE(MODE16_FLAG_BIT) = '0') else zero_sum0 and zero_sum1;
	-- Check if unsigned overflow (carry = '1' if sum or carr = '0' if sub)
	carry_flag	<= carry(0) xor op_is_subtraction when (MODE(MODE16_FLAG_BIT) = '0') else
				   carry(2) xor op_is_subtraction;
	-- Check if signed overflow (sign of operands is the same and is also different from that of the sum)
	ovfl_flag	<= (sign0(0) xor sign0(1)) and (sign0(0) xor sign0(2)) when (MODE(MODE16_FLAG_BIT) = '0') else
				   (sign1(0) xor sign1(1)) and (sign1(0) xor sign1(2));
				   
	-- Pack status
	CMP_OUT(SF_BIT)	<= sign_flag;
	CMP_OUT(ZF_BIT) <= zero_flag;
	CMP_OUT(CF_BIT) <= carry_flag;
	CMP_OUT(OF_BIT) <= ovfl_flag;
	
	
	---- LOGIC
	-------------
	and_out		<= OP1 and OP2;
	orr_out		<= OP1 or  OP2;
	xor_out		<= OP1 xor OP2;
	
	logic_out	<= and_out when (OPCODE = AND_r or OPCODE = AND_i) else
				   orr_out when (OPCODE = ORR_r or OPCODE = ORR_i) else
				   xor_out;
	
	
	---- SHIFTER
	---------------
	shift_amount	<= OP2(3 downto 0);
	shift_direction	<= '0' when (OPCODE = SLL_r or OPCODE = SLL_i) else '1';
	arith_shift		<= '1' when (OPCODE = SRA_r or OPCODE = SRA_i) else '0';
	-- BYTE 0
	shifter0: entity work.SHIFTER(behavioral)
	generic map (N => 8)
	port map (
		DIN		=> OP1(LO_BYTE),
		SHFT	=> shift_amount,
		DIR		=> shift_direction,
		ARITH	=> arith_shift,
		DOUT	=> shifter0_out
	);
	-- PIPELINE
	shifter_pipeline_operand1: entity work.REG_N
	generic map (N => 8)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> OP1(HI_BYTE),
		DOUT	=> op1_hi_byte
	);
	shifter_pipeline_shift_amount: entity work.REG_N
	generic map (N => 4)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> shift_amount,
		DOUT	=> shift_amount_pipe
	);
	shifter_pipeline_shift_direction: entity work.REG_N
	generic map (N => 1)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> to_vec(shift_direction),
		DOUT	=> shift_direction_pipe
	);
	shifter_pipeline_artih_shift: entity work.REG_N
	generic map (N => 1)
	port map (
		CLK		=> CLK,
		RST		=> RST,
		ENB		=> mode16_bit_enb,
		DIN		=> to_vec(arith_shift),
		DOUT	=> arith_shift_pipe
	);
	-- BYTE 1
	shifter0: entity work.SHIFTER(behavioral)
	generic map (N => 8)
	port map (
		DIN		=> op1_hi_byte,
		SHFT	=> shift_amount_pipe,
		DIR		=> shift_direction_pipe(0),
		ARITH	=> arith_shift_pipe(0),
		DOUT	=> shifter1_out
	);
	-- COMPOSE OUTPUT
	shifter_out(LO_BYTE)	<= (shifter0_out(BYTE1) or shifter1_out(BYTE0)) when (OPCODE = SRL_r or OPCODE = SRL_i) else
							   (shifter0_out(BYTE1) or shifter1_out(BYTE0)) when (OPCODE = SRA_r or OPCODE = SRA_i) else
							   (shifter0_out(BYTE1));
	shifter_out(HI_BYTE)	<= (shifter0_out(BYTE2) or shifter1_out(BYTE1)) when (OPCODE = SLL_r or OPCODE = SLL_i) else
							   (shifter1_out(BYTE1));
	
	
	---- OUTPUTS
	---------------
	READY	<= '1' when (MODE(MODE16_FLAG_BIT) = '1' and state = STAGE2) else
			   '1' when (MODE(MODE16_FLAG_BIT) = '0' and state = STAGE1) else
			   '0';
			   
	DOUT	<= shifter_out when (output_type = SHIFT) else
			   logic_out   when (output_type = LOGIC) else
			   addsub_out;

end architecture;