-------------------------------------------------------------------------------
--
-- Title       : RAM
-- Design      : subleq_cpu
-- Author      : Daniel Hort
-- Company     : UPT
--
-------------------------------------------------------------------------------
--
-- File        : D:\Projects\Licenta\subleq_cpu\src\RAM.vhd
-- Generated   : Wed May  4 22:09:02 2022
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
use ieee.std_logic_textio.all;


entity RAM1DF is
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
		o_ACK:  out std_logic := '0'
	);
end entity;


architecture RAM1DF of RAM1DF is

type t_BIN_FILE is file of character;
subtype t_MEM_UNIT is std_logic_vector(g_DATA_LINES-1 downto 0);
type t_MEM is array(0 to g_MEM_SIZE-1) of t_MEM_UNIT;

function f_INIT_MEM(file_name: in string)
	return t_MEM is
	file f_FILE : t_BIN_FILE;
	variable v_DATA: character;
	variable v_MEM: t_MEM;
begin
	file_open(f_FILE, file_name, read_mode);
	for i in v_MEM'range loop
		for j in 0 to g_DATA_LINES/8-1 loop
			read(f_FILE, v_DATA);
			v_MEM(i)(j*8+7 downto j*8) := std_logic_vector(to_unsigned(character'POS(v_DATA), 8));
		end loop;
	end loop;
	file_close(f_FILE);
	return v_MEM;
end function;

signal s_MEM: t_MEM := f_INIT_MEM("mem.bin");

begin
	
	o_DATA <= s_MEM(to_integer(unsigned(i_ADR)));
	
	process(i_WCLK)
	begin
		if i_WCLK = '1' then 
			if i_WE = '1' and i_REQ = '1' then
				s_MEM(to_integer(unsigned(i_ADR))) <= i_DATA;
				o_ACK <= '1';
			else
				o_ACK <= '0';
			end if;
		end if;
	end process;
	
end architecture;





library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity TB_RAM is
end entity;


architecture TB_RAM of TB_RAM is

component D_FF is
	port(
		i_D:   in  std_logic;
		i_CLK: in  std_logic;
		o_Q:   out std_logic
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

constant CLK_INTERVAL : time := 10ns; --100MHz
signal s_CLK : std_logic := '0';

constant ADR_LINES  : integer := 64;
constant DATA_LINES : integer := 64;
signal s_DATA_IN : std_logic_vector(DATA_LINES-1 downto 0) := (others => '0'); 
signal s_DATA_OUT : std_logic_vector(DATA_LINES-1 downto 0);
signal s_WE: std_logic;
signal s_REQ, s_REQ1: std_logic;
signal s_ACK, s_ACK1: std_logic;
signal s_ADR : std_logic_vector(ADR_LINES-1 downto 0) := (others => '0');

begin
	
	p_CLK : process
	begin
		s_CLK <= not s_CLK;
		wait for CLK_INTERVAL/2;
	end process;
	
	p_INC : process(s_CLK)
	begin
		if s_CLK = '1' then
			--s_ADR <= std_logic_vector(unsigned(s_ADR)+1);
		end if;
	end process;
	
	p_ACK : process(s_ACK)
	begin
		if s_ACK = '1' then
			--s_WE <= '0';
		end if;
	end process;
	
	s_WE      <= '0', '1' after 10ns, '0' after 50ns;
	s_REQ     <= '0', '1' after 10ns, '0' after 50ns;
	s_DATA_IN <= (others => '1');
	
	sync: SYNC2H port map (s_REQ, s_ACK, s_CLK, s_CLK, s_REQ1, s_ACK1);
	
	ram: RAM1DF port map(
		i_DATA => s_DATA_IN,
		i_ADR  => s_ADR,
		i_WE   => s_WE,
		i_WCLK => s_CLK,
		i_REQ  => s_REQ1,
		o_DATA => s_DATA_OUT,
		o_ACK  => s_ACK
	);
	
end architecture;































