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
		g_ADR_LINES  : integer := 8; -- probably 32
		-- bigger or equal to g_ADR_LINES due to SUBLEQ requirements
		g_DATA_LINES : integer := 8	 -- probably 64 
	);
	port(
		i_CLK   : in std_logic;
		i_SYNC  : in std_logic;
		i_RST   : in std_logic;
		o_CS    : out std_logic;  -- 1 enable RW, 0 disable RW
		o_RW    : out std_logic;  -- 1 read, 0 write
		o_ADR   : out std_logic_vector(g_ADR_LINES-1 downto 0) := (others => 'Z');
		io_DATA : inout std_logic_vector(g_DATA_LINES-1 downto 0) 
	);
end entity;


architecture SUBLEQ_CPU of SUBLEQ_CPU is

type PIPELINE_STATE is (
	FETCH_ADR_A, 
	FETCH_ADR_B, 
	FETCH_ADR_C,
	FETCH_DATA_A,
	FETCH_DATA_B,
	SUBSTRACT, 
	WRITE_B, 
	JUMP_TO_C);
signal s_ADR, s_REL_ADR : std_logic_vector(g_ADR_LINES-1 downto 0) := (others => '0');
signal s_STATE : PIPELINE_STATE := FETCH_ADR_A;
signal s_DATA_A, s_DATA_B, s_DATA_NEW_B : std_logic_vector(g_DATA_LINES-1 downto 0);
signal s_ADR_A, s_ADR_B, s_ADR_C : std_logic_vector(g_ADR_LINES-1 downto 0);

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
	begin
		if rising_edge(i_CLK) and i_RST = '0' then
			
			if i_RST = '1' then
				s_ADR     <= (others => '0');
				s_REL_ADR <= (others => '0');
				s_STATE   <= FETCH_ADR_A;
				o_CS      <= '0';
				o_RW      <= '1';
				io_DATA   <= (others => 'Z');
			else
				if s_STATE = FETCH_ADR_A and i_SYNC = '0' then
					s_REL_ADR <= s_ADR;
					o_CS <= '1';											-- enable memory
					o_RW <= '1';											-- read
				elsif s_STATE = FETCH_ADR_A and i_SYNC = '1' then			
					s_ADR_A <= io_DATA(g_ADR_LINES-1 downto 0);			    -- save data
					s_REL_ADR <= std_logic_vector(unsigned(s_REL_ADR) + 1); -- increment address
					s_STATE <= FETCH_ADR_B;									-- switch state
					o_CS <= '0';											-- disable memory
				elsif s_STATE = FETCH_ADR_B and i_SYNC = '0' then
					o_CS <= '1';
					o_RW <= '1';
				elsif s_STATE = FETCH_ADR_B and i_SYNC = '1' then
					s_ADR_B <= io_DATA(g_ADR_LINES-1 downto 0);
					s_REL_ADR <= std_logic_vector(unsigned(s_REL_ADR) + 1);
					s_STATE <= FETCH_ADR_C;
					o_CS <= '0';
				elsif s_STATE = FETCH_ADR_C and i_SYNC = '0' then
					o_CS <= '1';
					o_RW <= '1';
				elsif s_STATE = FETCH_ADR_C and i_SYNC = '1' then
					s_ADR_C <= io_DATA(g_ADR_LINES-1 downto 0);
					s_REL_ADR <= s_ADR_A;
					s_STATE <= FETCH_DATA_A;
					o_CS <= '0';
				elsif s_STATE = FETCH_DATA_A and i_SYNC = '0' then
					o_CS <= '1';
					o_RW <= '1';
				elsif s_STATE = FETCH_DATA_A and i_SYNC = '1' then
					s_DATA_A <= io_DATA;
					s_REL_ADR <= s_ADR_B;
					s_STATE <= FETCH_DATA_B;
					o_CS <= '0';
				elsif s_STATE = FETCH_DATA_B and i_SYNC = '0' then
					o_CS <= '1';
					o_RW <= '1';
				elsif s_STATE = FETCH_DATA_B and i_SYNC = '1' then
					s_DATA_B <= io_DATA;
					s_STATE <= SUBSTRACT;
					o_CS <= '0';
				elsif s_STATE = SUBSTRACT then
					v_DATA_B := std_logic_vector(signed(s_DATA_B) - signed(s_DATA_A));
					if s_DATA_B = v_DATA_B then
						s_STATE <= JUMP_TO_C;
					else
						s_STATE <= WRITE_B;
					end if;
				elsif s_STATE = WRITE_B and i_SYNC = '0' then
					o_CS <= '1';
					o_RW <= '0';
					io_DATA <= v_DATA_B;
				elsif s_STATE = WRITE_B and i_SYNC = '1' then
					s_STATE <= JUMP_TO_C;
					o_CS <= '0';
				elsif s_STATE = JUMP_TO_C then
					if signed(v_DATA_B) <= 0 then 
						s_ADR <= s_ADR_C;
					else
						s_ADR <= std_logic_vector(unsigned(s_ADR)+3);
					end if;
					s_STATE <= FETCH_ADR_A;
				end if;
			end if;
		end if;
	end process;
	
	-- fetch        read    enabled    wait sync
	-- calculate    read	disabled
	-- write        write   enabled    wait sync
	-- jump			read	disabled
	
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
		g_ADR_LINES  : integer := 16;
		g_DATA_LINES : integer := 8
	);
	port(
		i_CLK   : in std_logic;
		i_SYNC  : in std_logic;
		i_RST   : in std_logic; 
		o_RW    : out std_logic;  -- 1 read, 0 write
		o_ADR   : out std_logic_vector(g_ADR_LINES-1 downto 0);
		io_DATA : inout std_logic_vector(g_DATA_LINES-1 downto 0) 
	);
end component;

constant CLK_INTERVAL : time := 10ns; --100MHz
signal CLK : std_logic := '0';
signal ADR : std_logic_vector(15 downto 0);

begin
	
	p_CLK : process
	begin
		CLK <= not CLK;
		wait for CLK_INTERVAL/2;
	end process;
	
	cpu: SUBLEQ_CPU 
		generic map(
			g_ADR_LINES  => 8,
			g_DATA_LINES => 8
		) 
		port map(
			i_CLK   => CLK,
			i_SYNC  => '0',
			i_RST   => '0',
			o_RW    => open,
			o_ADR   => ADR,
			io_DATA	=> open
		);
	
end architecture;






























