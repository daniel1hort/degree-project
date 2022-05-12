-------------------------------------------------------------------------------
--
-- Title       : D_FF
-- Design      : subleq_cpu
-- Author      : Daniel Hort
-- Company     : UPT
--
-------------------------------------------------------------------------------
--
-- File        : D:\Projects\Licenta\subleq_cpu\src\D_FF.vhd
-- Generated   : Thu May 12 23:23:01 2022
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


entity D_FF is
	port(
		i_D:   in  std_logic;
		i_CLK: in  std_logic;
		o_Q:   out std_logic
	);
end entity;


architecture D_FF of D_FF is
begin
	
	p_CLK : process(i_CLK)
	begin
		if i_CLK = '1' then
			o_Q <= i_D;
		end if;
	end process;
	
end architecture;





library ieee;
use ieee.std_logic_1164.all;


entity SYNC2H is
	port(
		i_D1: in std_logic;
		i_D2: in std_logic;
		i_CLK1: in std_logic;
		i_CLK2: in std_logic;
		o_Q1: out std_logic;
		o_Q2: out std_logic
	);
end entity;


architecture SYNC2H of SYNC2H is

component D_FF is
	port(
		i_D:   in  std_logic;
		i_CLK: in  std_logic;
		o_Q:   out std_logic
	);
end component;

signal s_D1, s_D2: std_logic;

begin
	
	dff1: D_FF port map(i_D1, i_CLK2, s_D1);
	dff2: D_FF port map(s_D1, i_CLK2, o_Q1);
	dff3: D_FF port map(i_D2, i_CLK1, s_D2);
	dff4: D_FF port map(s_D2, i_CLK1, o_Q2);
	
end architecture;
























