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
		g_ADR_LINES:  integer := 64;
		-- bigger or equal to g_ADR_LINES due to SUBLEQ requirements
		g_DATA_LINES: integer := 64;
		g_LC_START:   integer := 0
	);
	port(
		i_CLK   : in    std_logic;
		i_RST   : in    std_logic;
		i_MISS  : in    std_logic;
		o_WE    : out   std_logic; -- WRITE ENABLE
		o_ADR   : out   std_logic_vector(g_ADR_LINES-1  downto 0);
		io_DATA : inout std_logic_vector(g_DATA_LINES-1 downto 0) 
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
signal s_ADR, s_REL_ADR                 : std_logic_vector(g_ADR_LINES-1 downto 0);
signal s_STATE                          : PIPELINE_STATE := INITIATE;
signal s_DATA                           : std_logic_vector(g_DATA_LINES-1 downto 0);
signal s_DATA_A, s_DATA_B, s_DATA_NEW_B : std_logic_vector(g_DATA_LINES-1 downto 0);
signal s_ADR_A, s_ADR_B, s_ADR_C        : std_logic_vector(g_ADR_LINES-1  downto 0);
signal s_WE: std_logic;

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

	p_PIPELINE : process(i_CLK, i_RST)
		variable v_DATA_B : std_logic_vector(g_DATA_LINES-1 downto 0);
	begin
		
		if rising_edge(i_RST) or s_STATE = INITIATE then
			s_ADR     <= std_logic_vector(to_unsigned(g_LC_START, g_ADR_LINES));
			s_REL_ADR <= std_logic_vector(to_unsigned(g_LC_START, g_ADR_LINES));
			s_STATE   <= FETCH_ADR_A;
			s_WE      <= '0'; 
			s_DATA    <= (others => '0');
		end if;
		
		if rising_edge(i_CLK) and i_RST = '0' then
			if s_STATE = FETCH_ADR_A and i_MISS = '0' then
				s_ADR_A   <= io_DATA(g_ADR_LINES-1 downto 0);
				p_INC_SLV(s_REL_ADR);
				s_STATE   <= FETCH_ADR_B;
			elsif s_STATE = FETCH_ADR_B and i_MISS = '0' then
				s_ADR_B   <= io_DATA(g_ADR_LINES-1 downto 0);
				p_INC_SLV(s_REL_ADR);
				s_STATE   <= FETCH_ADR_C;
			elsif s_STATE = FETCH_ADR_C and i_MISS = '0' then
				s_ADR_C   <= io_DATA(g_ADR_LINES-1 downto 0);
				s_REL_ADR <= s_ADR_A;
				s_STATE   <= FETCH_DATA_A;
			elsif s_STATE = FETCH_DATA_A and i_MISS = '0' then
				s_DATA_A  <= io_DATA;
				s_REL_ADR <= s_ADR_B;
				s_STATE   <= FETCH_DATA_B;
			elsif s_STATE = FETCH_DATA_B and i_MISS = '0' then
				s_DATA_B  <= io_DATA;
				s_STATE   <= SUBSTRACT;
			elsif s_STATE = SUBSTRACT then
				v_DATA_B  := f_SUBSTRACT(s_DATA_B, s_DATA_A);
				if s_DATA_B = v_DATA_B then
					s_STATE   <= JUMP_TO_C;
				else
					s_DATA    <= v_DATA_B;
					s_WE      <= '1';
					s_STATE   <= WRITE_B;
				end if;
			elsif s_STATE = WRITE_B and i_MISS = '0' then
				s_STATE   <= JUMP_TO_C;
			elsif s_STATE = JUMP_TO_C and i_MISS = '0' then
				if signed(v_DATA_B) <= 0 then 
					s_ADR     <= s_ADR_C;
					s_REL_ADR <= s_ADR_C;
				else
					s_ADR     <= std_logic_vector(unsigned(s_ADR)+3);
					s_REL_ADR <= std_logic_vector(unsigned(s_ADR)+3);
				end if;
				s_WE      <= '0';
				s_STATE   <= FETCH_ADR_A;
			else
				-- we just wait
			end if;
		end if;
	end process;
	
	o_WE    <= s_WE;
	o_ADR   <= s_REL_ADR;
	io_DATA <= s_DATA when s_WE = '1' else (others => 'Z');
	
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
		g_DATA_LINES : integer := 64;
		g_LC_START   : integer := 0
	);
	port(
		i_CLK    : in    std_logic;
		i_RST    : in    std_logic;
		i_MISS   : in    std_logic;
		o_WE     : out   std_logic;
		o_ADR    : out   std_logic_vector(g_ADR_LINES-1  downto 0);
		io_DATA  : inout std_logic_vector(g_DATA_LINES-1 downto 0) 
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
		i_D1:   in  std_logic;
		i_D2:   in  std_logic;
		i_CLK1: in  std_logic;
		i_CLK2: in  std_logic;
		o_Q1:   out std_logic;
		o_Q2:   out std_logic
	);
end component;

component CACHE is
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
end component;

component ARBITER is
	generic(
		g_SIZE: integer := 2
	);
	port(
		i_REQ: in  std_logic_vector(g_SIZE-1 downto 0);
		o_GRT: out std_logic_vector(g_SIZE-1 downto 0)
	);
end component;

constant c_CLK_INTERVAL : time := 10ns; --100MHz
signal s_CLK:  std_logic := '0';

constant c_CORE_COUNT: integer := 2;
constant c_ADR_LINES:  integer := 8;
constant c_DATA_LINES: integer := 8;
signal   s_ARBITER_REQ, s_ARBITER_GRANT: std_logic_vector(c_CORE_COUNT-1 downto 0);
	 
type t_CORE_SIGNALS is record  
	MISS:         std_logic;
	WE_CPU:       std_logic;   	  
	ADR_CPU:      std_logic_vector(c_ADR_LINES-1  downto 0);
	DATA_CPU:     std_logic_vector(c_DATA_LINES-1 downto 0);  
end record;
type t_CORES_SIGNALS is array(0 to c_CORE_COUNT-1) of t_CORE_SIGNALS;
signal s_CORES_SIGNALS: t_CORES_SIGNALS;

type t_RAM_SIGNALS is record
	ADR_RAM:    std_logic_vector(c_ADR_LINES-1  downto 0);
	DATA_RAM_IN:    std_logic_vector(c_DATA_LINES-1 downto 0);
	DATA_RAM_OUT:   std_logic_vector(c_DATA_LINES-1 downto 0);  
	WE_RAM:     std_logic;
end record;
signal s_RAM_SIGNALS: t_RAM_SIGNALS;
	
type t_SYNC_SIGNALS is record
	REQ, REQ_OUT, ACK, ACK_OUT: std_logic;
end record;
signal s_SYNC_SIGNALS: t_SYNC_SIGNALS;

begin
	
	p_CLK : process
	begin
		wait for c_CLK_INTERVAL/2;
		s_CLK  <= not s_CLK;
	end process;
	
	cpu1: SUBLEQ_CPU
		generic map(
			g_ADR_LINES  => c_ADR_LINES,
			g_DATA_LINES => c_DATA_LINES,
			g_LC_START   => 0
		)
		port map(
			i_CLK   => s_CLK,
			i_RST   => '0',
			i_MISS  => s_CORES_SIGNALS(0).MISS,
			o_WE    => s_CORES_SIGNALS(0).WE_CPU,
			o_ADR   => s_CORES_SIGNALS(0).ADR_CPU,
			io_DATA => s_CORES_SIGNALS(0).DATA_CPU
		);
	
	cpu2: SUBLEQ_CPU
		generic map(
			g_ADR_LINES  => c_ADR_LINES,
			g_DATA_LINES => c_DATA_LINES,
			g_LC_START   => 128
		)
		port map(
			i_CLK   => s_CLK,
			i_RST   => '0',
			i_MISS  => s_CORES_SIGNALS(1).MISS,
			o_WE    => s_CORES_SIGNALS(1).WE_CPU,
			o_ADR   => s_CORES_SIGNALS(1).ADR_CPU,
			io_DATA => s_CORES_SIGNALS(1).DATA_CPU
		);
		
	ram: RAM1DF
		generic map(
			g_ADR_LINES  => c_ADR_LINES,
			g_DATA_LINES => c_DATA_LINES,
			g_MEM_SIZE   => 256
		)
		port map(
			i_DATA => s_RAM_SIGNALS.DATA_RAM_IN, 
			i_ADR  => s_RAM_SIGNALS.ADR_RAM,
			i_WE   => s_RAM_SIGNALS.WE_RAM,
			i_WCLK => s_CLK,
			i_REQ  => s_SYNC_SIGNALS.REQ_OUT,
			o_DATA => s_RAM_SIGNALS.DATA_RAM_OUT,
			o_ACK  => s_SYNC_SIGNALS.ACK
		);
		
	sync: SYNC2H
		port map(
			i_D1   => s_SYNC_SIGNALS.REQ,
			i_D2   => s_SYNC_SIGNALS.ACK,
			i_CLK1 => s_CLK,
			i_CLK2 => s_CLK,
			o_Q1   => s_SYNC_SIGNALS.REQ_OUT,
			o_Q2   => s_SYNC_SIGNALS.ACK_OUT
		);
	
	cache1: CACHE
		generic map(
			g_ADR_LINES  => c_ADR_LINES,
			g_DATA_LINES => c_DATA_LINES,
			g_LINE_SIZE  => 8,
			g_MEM_LINES  => 8
		)
		port map(
			i_CLK       => s_CLK,
			i_ADR       => s_CORES_SIGNALS(0).ADR_CPU,
			i_DATA_MEM  => s_RAM_SIGNALS.DATA_RAM_OUT,
			i_WE        => s_CORES_SIGNALS(0).WE_CPU,
			i_ACK       => s_SYNC_SIGNALS.ACK_OUT,
			i_RST       => '0',
			i_GRT       => s_ARBITER_GRANT(0),
			o_ADR       => s_RAM_SIGNALS.ADR_RAM,
			o_DATA_MEM  => s_RAM_SIGNALS.DATA_RAM_IN,
			o_WE        => s_RAM_SIGNALS.WE_RAM,
			o_MISS      => s_CORES_SIGNALS(0).MISS,
			o_REQ       => s_SYNC_SIGNALS.REQ,
			o_AR_REQ    => s_ARBITER_REQ(0),
			io_DATA     => s_CORES_SIGNALS(0).DATA_CPU
		);
	
	cache2: CACHE
		generic map(
			g_ADR_LINES  => c_ADR_LINES,
			g_DATA_LINES => c_DATA_LINES,
			g_LINE_SIZE  => 8,
			g_MEM_LINES  => 8
		)
		port map(
			i_CLK       => s_CLK,
			i_ADR       => s_CORES_SIGNALS(1).ADR_CPU,
			i_DATA_MEM  => s_RAM_SIGNALS.DATA_RAM_OUT,
			i_WE        => s_CORES_SIGNALS(1).WE_CPU,
			i_ACK       => s_SYNC_SIGNALS.ACK_OUT,
			i_RST       => '0',
			i_GRT       => s_ARBITER_GRANT(1),
			o_ADR       => s_RAM_SIGNALS.ADR_RAM,
			o_DATA_MEM  => s_RAM_SIGNALS.DATA_RAM_IN,
			o_WE        => s_RAM_SIGNALS.WE_RAM,
			o_MISS      => s_CORES_SIGNALS(1).MISS,
			o_REQ       => s_SYNC_SIGNALS.REQ,
			o_AR_REQ    => s_ARBITER_REQ(1),
			io_DATA     => s_CORES_SIGNALS(1).DATA_CPU
		);
		
	
		
	arbiter2: ARBITER
		generic map(
			g_SIZE => c_CORE_COUNT
		)
		port map(
			i_REQ => s_ARBITER_REQ,
			o_GRT => s_ARBITER_GRANT
		);
	
end architecture;






























