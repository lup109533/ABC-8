-- UTILS
--------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package utils is
	-- Custom types and functions to reduce boilerplate
	subtype sl			is std_logic;
	subtype slv			is std_logic_vector;
	subtype byte		is slv(7  downto 0);
	subtype word8		is byte;
	subtype word16		is slv(15 downto 0);
	type    byte_pair	is array (1 downto 0) of byte;
	
	function min               (a, b : integer)              return integer;
	function max               (a, b : integer)              return integer;
	function clamp             (n, a, b : integer)           return integer;
	function to_slv            (n : natural; size : natural) return slv;
	function to_byte_pair      (w : word16)                  return byte_pair;
	function to_word16         (p : byte_pair)               return word16;
	function to_vec            (l : sl)                      return slv;
	function zero              (n : natural)                 return slv;
	function priority_low2high (v : slv)                     return integer;
	function priority_high2low (v : slv)                     return integer;
end package;

package body utils is
	function min (a, b : integer) return integer is
	begin
		if a <= b then
			return a;
		else
			return b;
		end if;
	end function;
	
	function max (a, b : integer) return integer is
	begin
		if a > b then
			return a;
		else
			return b;
		end if;
	end function;
	
	function clamp (n, a, b : integer) return integer is
		variable minimum : integer;
		variable maximum : integer;
	begin
		if a > b then
			maximum := a;
			minimum := b;
		else
			minimum := a;
			maximum := b;
		end if;
	
		if n < minimum then
			return minimum;
		elsif n > maximum then
			return maximum;
		else
			return n;
		end if;
	end function;

	function to_slv (n : natural; size : natural) return slv is
	begin
		return slv(to_unsigned(n, size));
	end function;
	
	function to_byte_pair (w : word16) return byte_pair is
		variable b : byte_pair;
	begin
		b(0) := w(7  downto 0);
		b(1) := w(15 downto 8);
		return b;
	end function;
	
	function to_word16 (p : byte_pair) return word16 is
		variable w : word16;
	begin
		w( 7 downto 0) := p(0);
		w(15 downto 8) := p(1);
		return w;
	end function;
	
	function to_vec (l :sl) return slv is
		variable v : slv(0 downto 0);
	begin
		v(0) := l;
		return v;
	end function;
	
	function zero (n : natural) return slv is
		variable ret : slv(n-1 downto 0) := (others => '0');
	begin
		return ret;
	end function;
	
	function priority_low2high (v : slv) return integer is
		variable curr : integer := 0;
	begin
		for i in 0 to v'length-1 loop
			if (v(i) = '1') then
				return curr;
			end if;
			curr := curr + 1;
		end loop;
		return curr;
	end function;
	
	function priority_high2low (v : slv) return integer is
		variable curr : integer := v'length-1;
	begin
		for i in v'length-1 downto 0 loop
			if (v(i) = '1') then
				return curr;
			end if;
			curr := curr - 1;
		end loop;
		return curr;
	end function;
end package body;


-- GLOBALS
---------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use work.utils.all;

package ABC8_globals is

	---- ABC8 TYPES
	------------------
	subtype ABC8_instr_t    is slv(7  downto 0);	-- 8-bit instruction
	subtype ABC8_opcode_t   is slv(4  downto 0);	-- 5-bit opcode
	subtype ABC8_optype_t	is slv(1  downto 0);	-- 2-bit operation type
	subtype ABC8_mode_t     is slv(2  downto 0);	-- 3-bit mode
	subtype ABC8_reg_addr_t is slv(2  downto 0);	-- 3-bit address for register file
	subtype ABC8_arg8_t     is slv(7  downto 0);	-- 8-bit argument
	subtype ABC8_arg16_t    is slv(15 downto 0);	-- 16-bit argument
	subtype ABC8_addr8_t	is slv(7  downto 0);	-- 8-bit address
	subtype ABC8_addr16_t	is slv(15 downto 0);	-- 16-bit address
	subtype status_reg_t	is slv(3  downto 0);	-- 4-bit status register
	
	-- Ranges and constants for instruction unpacking
	subtype  LO_BYTE		is natural range 7  downto 0;
	subtype  HI_BYTE		is natural range 15 downto 8;
	subtype  OPCODE_RANGE	is natural range 7  downto 3;
	subtype  OPTYPE_RANGE	is natural range 7  downto 6;
	subtype  REG_ADDR_RANGE	is natural range 2  downto 0;
	subtype  MODE_RANGE		is natural range 2  downto 0;
	constant SIGN_FLAG_BIT   : natural := 0;
	constant MODE16_FLAG_BIT : natural := 1;
	
	
	---- OPCODE CONSTANTS
	------------------------
	-- Branch operations + NOP
	constant NOP	: ABC8_opcode_t := to_slv(2#00000#, 5);
	constant JMP	: ABC8_opcode_t := to_slv(2#00001#, 5);
	constant BEQ	: ABC8_opcode_t := to_slv(2#00010#, 5);
	constant BNE	: ABC8_opcode_t := to_slv(2#00011#, 5);
	constant BLT	: ABC8_opcode_t := to_slv(2#00100#, 5);
	constant BGT	: ABC8_opcode_t := to_slv(2#00101#, 5);
	constant BLE	: ABC8_opcode_t := to_slv(2#00110#, 5);
	constant BGE	: ABC8_opcode_t := to_slv(2#00111#, 5);
	
	-- General operations
	constant LDR	: ABC8_opcode_t := to_slv(2#01000#, 5);
	constant STR	: ABC8_opcode_t := to_slv(2#01001#, 5);
	constant LDM	: ABC8_opcode_t := to_slv(2#01010#, 5);
	constant STM	: ABC8_opcode_t := to_slv(2#01011#, 5);
	constant MUL	: ABC8_opcode_t := to_slv(2#01100#, 5);
	constant DIV	: ABC8_opcode_t := to_slv(2#01101#, 5);
	constant CMP	: ABC8_opcode_t := to_slv(2#01110#, 5);
	constant SET	: ABC8_opcode_t := to_slv(2#01111#, 5);
	
	-- Register operations
	constant ADD_r	: ABC8_opcode_t := to_slv(2#10000#, 5);
	constant SUB_r	: ABC8_opcode_t := to_slv(2#10001#, 5);
	constant SLL_r	: ABC8_opcode_t := to_slv(2#10010#, 5);
	constant SRL_r	: ABC8_opcode_t := to_slv(2#10011#, 5);
	constant SRA_r	: ABC8_opcode_t := to_slv(2#10100#, 5);
	constant AND_r	: ABC8_opcode_t := to_slv(2#10101#, 5);
	constant ORR_r	: ABC8_opcode_t := to_slv(2#10110#, 5);
	constant XOR_r	: ABC8_opcode_t := to_slv(2#10111#, 5);
	
	-- Immediate argument operations
	constant ADD_i	: ABC8_opcode_t := to_slv(2#11000#, 5);
	constant SUB_i	: ABC8_opcode_t := to_slv(2#11001#, 5);
	constant SLL_i	: ABC8_opcode_t := to_slv(2#11010#, 5);
	constant SRL_i	: ABC8_opcode_t := to_slv(2#11011#, 5);
	constant SRA_i	: ABC8_opcode_t := to_slv(2#11100#, 5);
	constant AND_i	: ABC8_opcode_t := to_slv(2#11101#, 5);
	constant ORR_i	: ABC8_opcode_t := to_slv(2#11110#, 5);
	constant XOR_i	: ABC8_opcode_t := to_slv(2#11111#, 5);
	
	
	---- OPTYPE CONSTANTS
	------------------------
	constant B_TYPE	: ABC8_optype_t := to_slv(2#00#, 2);
	constant G_TYPE	: ABC8_optype_t := to_slv(2#01#, 2);
	constant R_TYPE	: ABC8_optype_t := to_slv(2#10#, 2);
	constant I_TYPE	: ABC8_optype_t := to_slv(2#11#, 2);
	
	
	---- MODE CONSTANTS
	----------------------
	constant MODE_U8	: ABC8_mode_t := to_slv(2#000#, 3);
	constant MODE_S8	: ABC8_mode_t := to_slv(2#001#, 3);
	constant MODE_U16	: ABC8_mode_t := to_slv(2#010#, 3);
	constant MODE_S16	: ABC8_mode_t := to_slv(2#011#, 3);
	constant MODE_F16	: ABC8_mode_t := to_slv(2#100#, 3);
	constant MODE_RSRV	: ABC8_mode_t := to_slv(2#101#, 3);
	constant MODE_SLEEP	: ABC8_mode_t := to_slv(2#110#, 3);
	constant MODE_RESET	: ABC8_mode_t := to_slv(2#111#, 3);
	
	
	---- STATUS FLAG INDEX CONSTANTS
	-----------------------------
	constant ZF_BIT	: natural := 0;
	constant CF_BIT	: natural := 1;
	constant SF_BIT	: natural := 2;
	constant OF_BIT	: natural := 3;
	
end package;