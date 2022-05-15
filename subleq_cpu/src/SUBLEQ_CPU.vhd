-------------------------------------------------------------------------------
--
-- Title       : SUBLEQ_CPU
-- Design      : subleq_cpu
-- Author      : Daniel Hort
-- Company     : UPT
--
-------------------------------------------------------------------------------
--
-- File        : D:\Projects\Licenta\subleq_cpu\src\SUBLEQ_CPU.vhd
-- Generated   : Sun Jan 30 21:30:25 2022
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


entity SUBLEQ_CPU is
	generic(
		g_ADR_LINES  : integer := 64;
		-- bigger or equal to g_ADR_LINES due to SUBLEQ requirements
		g_DATA_LINES : integer := 64 
	);
	port(
		i_CLK   : in  std_logic;
		i_RST   : in  std_logic;
		i_ACK   : in  std_logic; --	ACKNOWLEDGE REQUEST TERMINATION
		i_DATA  : in  std_logic_vector(g_DATA_LINES-1 downto 0);
		o_WE    : out std_logic; -- WRITE ENABLE
		o_REQ   : out std_logic; -- SEND REQUEST
		o_ADR   : out std_logic_vector(g_ADR_LINES-1  downto 0);
		o_DATA  : out std_logic_vector(g_DATA_LINES-1 downto 0) 
	);
end entity;


architecture SUBLEQ_CPU of SUBLEQ_CPU is

type PIPELINE_STATE is (
	INITIATE,
	FETCH_ADR_A, 
	FETCH_ADR_B, 
	FETCH_ADR_C,
	FETCH_DATA_A,
	FETCH_DATA_B,
	SUBSTRACT, 
	WRITE_B, 
	JUMP_TO_C);
signal s_ADR, s_REL_ADR : std_logic_vector(g_ADR_LINES-1 downto 0) := (others => '0');
signal s_STATE : PIPELINE_STATE := INITIATE;
signal s_DATA_A, s_DATA_B, s_DATA_NEW_B : std_logic_vector(g_DATA_LINES-1 downto 0);
signal s_ADR_A, s_ADR_B, s_ADR_C : std_logic_vector(g_ADR_LINES-1 downto 0);

procedure p_INC_SLV(signal s_VALUE : inout std_logic_vector) is
begin
	s_VALUE <= std_logic_vector(unsigned(s_VALUE) + 1);
end procedure;

function f_SUBSTRACT(A : in std_logic_vector; B : in std_logic_vector)
return std_logic_vector is
begin
	return std_logic_vector(signed(A) - signed(B));
end function;

begin
	
	p_INC_COUNTER : process(i_CLK) -- to be removed
	begin
		if rising_edge(i_CLK) then
			if i_RST = '0' then
				s_ADR <= std_logic_vector(unsigned(s_ADR) + 1);
			end if;
		end if;
	end process;
	
	p_PIPELINE : process(i_CLK)
		variable v_DATA_B : std_logic_vector(g_DATA_LINES-1 downto 0);
		variable v_REQ : std_logic;
	begin
		
		if rising_edge(i_CLK) then
			if i_RST = '1' or s_STATE = INITIATE then
				s_ADR     <= (others => '0');
				s_REL_ADR <= (others => '0');
				s_STATE   <= FETCH_ADR_A;
				o_WE      <= '0';
				v_REQ     := '0';
				o_DATA    <= (others => '0');
			elsif s_STATE = FETCH_ADR_A then
				s_ADR_A <= i_DATA(g_ADR_LINES-1 downto 0);
				p_INC_SLV(s_REL_ADR);
				s_STATE <= FETCH_ADR_B;
			elsif s_STATE = FETCH_ADR_B then
				s_ADR_B <= i_DATA(g_ADR_LINES-1 downto 0);
				p_INC_SLV(s_REL_ADR);
				s_STATE <= FETCH_ADR_C;
			elsif s_STATE = FETCH_ADR_C then
				s_ADR_C <= i_DATA(g_ADR_LINES-1 downto 0);
				s_REL_ADR <= s_ADR_A;
				s_STATE <= FETCH_DATA_A;
			elsif s_STATE = FETCH_DATA_A then
				s_DATA_A <= i_DATA;
				s_REL_ADR <= s_ADR_B;
				s_STATE <= FETCH_DATA_B;
			elsif s_STATE = FETCH_DATA_B then
				s_DATA_B <= i_DATA;
				s_STATE <= SUBSTRACT;
			elsif s_STATE = SUBSTRACT then
				v_DATA_B := f_SUBSTRACT(s_DATA_B, s_DATA_A);
				if s_DATA_B = v_DATA_B then
					s_STATE <= JUMP_TO_C;
				else
					s_STATE <= WRITE_B;
				end if;
			elsif s_STATE = WRITE_B and i_ACK = '0' then
				o_DATA <= v_DATA_B;
				o_WE <= '1';
				v_REQ := '1';
				s_STATE <= JUMP_TO_C;
			elsif s_STATE = JUMP_TO_C and i_ACK = v_REQ then
				if signed(v_DATA_B) <= 0 then 
					s_ADR     <= s_ADR_C;
					s_REL_ADR <= s_ADR_C;
				else
					s_ADR     <= std_logic_vector(unsigned(s_ADR)+3);
					--s_REL_ADR <= std_logic_vector(unsigned(s_ADR)+3); FIX ME!!!
				end if;
				v_REQ := '0';
				o_WE <= '0';
				s_STATE <= FETCH_ADR_A;
			else
				-- we just wait
			end if;
		end if;
		
		o_REQ <= v_REQ;
	end process;
	
	o_ADR <= s_REL_ADR;
	
end architecture;





library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity CPU_TB is
end entity;


architecture CPU_TB of CPU_TB is

component SUBLEQ_CPU is
	generic(
		g_ADR_LINES  : integer := 64;
		g_DATA_LINES : integer := 64 
	);
	port(
		i_CLK   : in  std_logic;
		i_RST   : in  std_logic;
		i_ACK   : in  std_logic;
		i_DATA  : in  std_logic_vector(g_DATA_LINES-1 downto 0);
		o_WE    : out std_logic;
		o_REQ   : out std_logic;
		o_ADR   : out std_logic_vector(g_ADR_LINES-1  downto 0);
		o_DATA  : out std_logic_vector(g_DATA_LINES-1 downto 0) 
	);
end component;

component RAM1DF is
	generic(
		g_ADR_LINES  : integer := 64;
		g_DATA_LINES : integer := 64;
		g_MEM_SIZE   : integer := 256
	);
	port(
		i_DATA: in  std_logic_vector(g_DATA_LINES-1 downto 0);
		i_ADR:  in  std_logic_vector(g_ADR_LINES-1  downto 0);
		i_WE:   in  std_logic;
		i_WCLK: in  std_logic;
		i_REQ:  in  std_logic;
		o_DATA: out std_logic_vector(g_DATA_LINES-1 downto 0);
		o_ACK:  out std_logic
	);
end component;

component SYNC2H is
	port(
		i_D1: in std_logic;
		i_D2: in std_logic;
		i_CLK1: in std_logic;
		i_CLK2: in std_logic;
		o_Q1: out std_logic;
		o_Q2: out std_logic
	);
end component;

constant CLK_INTERVAL : time := 10ns; --100MHz
signal s_CLK : std_logic := '0';

constant ADR_LINES  : integer := 64;
constant DATA_LINES : integer := 64;
signal s_ADR      : std_logic_vector(ADR_LINES-1  downto 0);
signal s_DATA_IN  : std_logic_vector(DATA_LINES-1 downto 0);
signal s_DATA_OUT : std_logic_vector(DATA_LINES-1 downto 0);
signal s_WE       : std_logic;
signal s_REQ, s_REQ_OUT, s_ACK, s_ACK_OUT : std_logic;


begin
	
	p_CLK : process
	begin
		s_CLK <= not s_CLK;
		wait for CLK_INTERVAL/2;
	end process;
	
	cpu: SUBLEQ_CPU
		port map(
			i_CLK  => s_CLK,
			i_RST  => '0',
			i_ACK  => s_ACK_OUT,
			i_DATA => s_DATA_IN,
			o_WE   => s_WE,
			o_REQ  => s_REQ,
			o_ADR  => s_ADR,
			o_DATA => s_DATA_OUT
		);
		
	ram: RAM1DF
		port map(
			i_DATA => s_DATA_OUT, 
			i_ADR  => s_ADR,
			i_WE   => s_WE,
			i_WCLK => s_CLK,
			i_REQ  => s_REQ_OUT,
			o_DATA => s_DATA_IN,
			o_ACK  => s_ACK
		);
		
	sync: SYNC2H
		port map(
			i_D1   => s_REQ,
			i_D2   => s_ACK,
			i_CLK1 => s_CLK,
			i_CLK2 => s_CLK,
			o_Q1   => s_REQ_OUT,
			o_Q2   => s_ACK_OUT
		);
	
end architecture;






























