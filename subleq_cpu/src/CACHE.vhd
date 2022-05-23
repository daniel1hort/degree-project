-------------------------------------------------------------------------------
--
-- Title       : CACHE
-- Design      : subleq_cpu
-- Author      : Daniel Hort
-- Company     : UPT
--
-------------------------------------------------------------------------------
--
-- File        : D:\Projects\Licenta\subleq_cpu\src\CACHE.vhd
-- Generated   : Thu May 19 20:57:21 2022
-- From        : interface description file
-- By          : Itf2Vhdl ver. 1.22
--
-------------------------------------------------------------------------------
--
-- Description : 
--
-------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
	
	
entity CACHE is
	generic(
		g_ADR_LINES  : integer := 64;
		g_DATA_LINES : integer := 64;
		g_LINE_SIZE  : integer := 8;
		g_MEM_LINES  : integer := 32
	);
	port(
		i_CLK:      in    std_logic;
		i_ADR:      in    std_logic_vector(g_ADR_LINES-1  downto 0);
		i_DATA_MEM: in    std_logic_vector(g_DATA_LINES-1	downto 0);
		i_WE:       in    std_logic;
		i_ACK:      in    std_logic;
		i_RST:      in    std_logic;
		i_GRT:      in    std_logic;
		o_ADR:      out   std_logic_vector(g_ADR_LINES-1  downto 0); 
		o_DATA_MEM: out   std_logic_vector(g_DATA_LINES-1 downto 0);
		o_WE:       out   std_logic;
		o_MISS:     out   std_logic;
		o_REQ:		out	  std_logic;
		o_AR_REQ:   out   std_logic;
		io_DATA:    inout std_logic_vector(g_DATA_LINES-1 downto 0)
	);
end entity;


architecture CACHE of CACHE is

constant c_OFFSET_SIZE: integer := integer(ceil(log2(real(g_LINE_SIZE))));
constant c_INDEX_SIZE:  integer := integer(ceil(log2(real(g_MEM_LINES))));
constant c_TAG_SIZE:    integer := g_ADR_LINES - c_OFFSET_SIZE - c_INDEX_SIZE;

type t_LINE  is array(0 to g_LINE_SIZE-1) of std_logic_vector(g_DATA_LINES-1 downto 0);
type t_MEM   is array(0 to g_MEM_LINES-1) of t_LINE;
type t_TAG   is record
	DIRTY: std_logic;
	VALID: std_logic;
	VALUE: std_logic_vector(c_TAG_SIZE-1 downto 0);
end record;
type t_TAGS  is array(0 to g_MEM_LINES-1) of t_TAG;
type t_STATE is (
	INITIATE,
	AVAILABLE,
	WRITE_LINE,
	READ_LINE);
constant c_TAG_DEFAULT: t_TAG := (
	DIRTY => '0',
	VALID => '0', 
	VALUE => (others => '0'));

signal s_MEM:          t_MEM;
signal s_TAGS:         t_TAGS  := (others => c_TAG_DEFAULT);
signal s_STATE:        t_STATE := INITIATE;
signal s_ADR:          std_logic_vector(g_ADR_LINES-1  downto 0); 
signal s_DATA_MEM:     std_logic_vector(g_DATA_LINES-1 downto 0);
signal s_WE:           std_logic;
signal s_REQ:		   std_logic;
signal s_DATA_OUT_CPU: std_logic_vector(g_DATA_LINES-1 downto 0);

function f_ENCODE_ADR(
	OFFSET:      in std_logic_vector(c_OFFSET_SIZE-1 downto 0);
	INDEX:       in std_logic_vector(c_INDEX_SIZE-1  downto 0);
	TAG:         in std_logic_vector(c_TAG_SIZE-1    downto 0))
	return std_logic_vector is
	variable v_ADR: std_logic_vector(g_ADR_LINES-1   downto 0);
begin
	v_ADR(g_ADR_LINES-1 downto g_ADR_LINES-c_TAG_SIZE)       := TAG;
	v_ADR(c_OFFSET_SIZE+c_INDEX_SIZE-1 downto c_OFFSET_SIZE) := INDEX;
	v_ADR(c_OFFSET_SIZE-1 downto 0)                          := OFFSET;
	return v_ADR;
end function;

begin
	
	p_AVAILABLE : process(i_CLK, i_RST)
		variable v_LINE_DECODED:  integer;
		variable v_BLOCK_DECODED: integer;
		variable v_TAG_VALUE:     std_logic_vector(c_TAG_SIZE-1 downto 0);
		variable v_TAG:           t_TAG;
		
		variable v_BLOCK_NUMBER: integer;
		variable v_ADR:          std_logic_vector(g_ADR_LINES-1 downto 0);
		variable v_REQ:          std_logic;
	begin
		if rising_edge(i_RST) or s_STATE = INITIATE then
			s_ADR      <= (others => '0');
			s_DATA_MEM <= (others => '0');
			s_WE       <= '0';
			o_MISS     <= '1';
			s_REQ      <= '0';
			v_REQ      := '0';
			s_STATE    <= AVAILABLE;
			s_TAGS     <= (others => c_TAG_DEFAULT);
		end if;
		
		if falling_edge(i_CLK) and i_RST = '0' then
			v_LINE_DECODED  := to_integer(unsigned(i_ADR(c_OFFSET_SIZE+c_INDEX_SIZE-1 downto c_OFFSET_SIZE)));
			v_BLOCK_DECODED := to_integer(unsigned(i_ADR(c_OFFSET_SIZE-1 downto 0)));
			v_TAG_VALUE     := i_ADR(g_ADR_LINES-1 downto g_ADR_LINES-c_TAG_SIZE);
			v_TAG           := s_TAGS(v_LINE_DECODED);
			v_ADR           := i_ADR;
			
			case s_STATE is
				when AVAILABLE  =>
					s_WE           <= '0';
					o_AR_REQ       <= '0';
					v_BLOCK_NUMBER := 0; -- RESET COUNTER
					if v_TAG.VALID = '1' and v_TAG.VALUE = v_TAG_VALUE and i_WE = '0' then
						o_MISS         <= '0';
					elsif v_TAG.VALID = '1' and v_TAG.VALUE = v_TAG_VALUE and i_WE = '1' then
						s_MEM(v_LINE_DECODED)(v_BLOCK_DECODED) <= io_DATA;
						s_TAGS(v_LINE_DECODED).DIRTY           <= '1';
						o_MISS                                 <= '0';
					elsif v_TAG.VALID = '0' or (v_TAG.VALID = '1' and v_TAG.VALUE /= v_TAG_VALUE and v_TAG.DIRTY = '0') then
						o_MISS         <= '1';
						s_STATE        <= READ_LINE;
						v_ADR(c_OFFSET_SIZE-1 downto 0)        := (others => '0');
						s_ADR          <= v_ADR;
						o_AR_REQ       <= '1';
					elsif v_TAG.VALID = '1' and v_TAG.VALUE /= v_TAG_VALUE and v_TAG.DIRTY = '1' then
						o_MISS         <= '1';
						s_STATE        <= WRITE_LINE;
						s_WE           <= '1';
						o_AR_REQ       <= '1';
					end if;
				when READ_LINE  =>
					if i_GRT = '1' then
						if v_BLOCK_NUMBER < g_LINE_SIZE then
							s_MEM(v_LINE_DECODED)(v_BLOCK_NUMBER) <= i_DATA_MEM;
							v_BLOCK_NUMBER                  := v_BLOCK_NUMBER+1;
							v_ADR(c_OFFSET_SIZE-1 downto 0) := std_logic_vector(to_unsigned(v_BLOCK_NUMBER, c_OFFSET_SIZE));
							s_ADR                           <= v_ADR;
						else
							s_TAGS(v_LINE_DECODED) <= ('0', '1', v_TAG_VALUE);
							s_STATE <= AVAILABLE;
							o_MISS  <= '0';
						end if;
					end if;
				when WRITE_LINE =>
					if i_GRT = '1' then
						if v_BLOCK_NUMBER < g_LINE_SIZE and v_REQ = '0' and i_ACK = '0' then
							v_ADR          := f_ENCODE_ADR(std_logic_vector(to_unsigned(v_BLOCK_NUMBER, c_OFFSET_SIZE)),
							                               std_logic_vector(to_unsigned(v_LINE_DECODED, c_INDEX_SIZE)), 
							                               v_TAG.VALUE);
							s_ADR          <= v_ADR;
							s_DATA_MEM     <= s_MEM(v_LINE_DECODED)(v_BLOCK_NUMBER);
							v_REQ          := '1';
						elsif v_BLOCK_NUMBER < g_LINE_SIZE and i_ACK = '1' and v_REQ = '1' then
							v_BLOCK_NUMBER := v_BLOCK_NUMBER+1;
							v_REQ          := '0';
						elsif v_BLOCK_NUMBER >= g_LINE_SIZE then
							s_WE           <= '0';
							s_STATE        <= AVAILABLE;
							s_TAGS(v_LINE_DECODED).DIRTY <= '0';
						end if;
					end if;
				when others =>
			end case;
			
			s_REQ          <= v_REQ;
			s_DATA_OUT_CPU <= s_MEM(v_LINE_DECODED)(v_BLOCK_DECODED);
		end if;
	end process;
	
	o_WE       <= s_WE			 when i_GRT = '1' else 'Z';
    o_REQ      <= s_REQ			 when i_GRT = '1' else 'Z';
	o_ADR      <= s_ADR          when i_GRT = '1' else (others => 'Z');
	o_DATA_MEM <= s_DATA_MEM     when i_GRT = '1' else (others => 'Z');
	io_DATA    <= s_DATA_OUT_CPU when i_WE  = '0' else (others => 'Z');
end architecture;




































