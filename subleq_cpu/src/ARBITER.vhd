-------------------------------------------------------------------------------
--
-- Title       : ARBITER
-- Design      : subleq_cpu
-- Author      : Daniel Hort
-- Company     : UPT
--
-------------------------------------------------------------------------------
--
-- File        : D:\Projects\Licenta\subleq_cpu\src\ARBITER.vhd
-- Generated   : Mon May 23 22:18:41 2022
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


entity ARBITER is
	generic(
		g_SIZE: integer := 2
	);
	port(
		i_REQ: in  std_logic_vector(g_SIZE-1 downto 0);
		o_GRT: out std_logic_vector(g_SIZE-1 downto 0)
	);
end entity;


architecture ARBITER of ARBITER is

constant c_ZERO: unsigned(g_SIZE-1 downto 0) := to_unsigned(0, g_SIZE);
constant c_ONE: unsigned(g_SIZE-1 downto 0)  := to_unsigned(1, g_SIZE);

begin
	
	process(i_REQ)
		variable v_GRT: std_logic_vector(g_SIZE-1 downto 0);
	begin
		if(i_REQ = std_logic_vector(c_ZERO)) then
			v_GRT := std_logic_vector(c_ZERO);
		else
			for i in g_SIZE-1 downto 0 loop
				if(i_REQ(i) = '1') then
					v_GRT := std_logic_vector(shift_left(c_ONE, i));
				end if;
			end loop;
		end if;
		
		o_GRT <= v_GRT;
	end process;
	
end architecture;





library ieee;
use ieee.std_logic_1164.all;


entity ARBITER_TB is
end entity;


architecture ARBITER_TB of ARBITER_TB is

component ARBITER is
	generic(
		g_SIZE: integer := 2
	);
	port(
		i_REQ: in  std_logic_vector(g_SIZE-1 downto 0);
		o_GRT: out std_logic_vector(g_SIZE-1 downto 0)
	);
end component;

constant c_SIZE: integer := 3;
signal   s_REQ, s_GRT: std_logic_vector(c_SIZE-1 downto 0);

begin
	
	s_REQ <= "000", 
	         "001" after 10ns,
			 "010" after 20ns, 
			 "011" after 30ns,
			 "100" after 40ns, 
	         "101" after 50ns,
			 "110" after 60ns, 
			 "111" after 70ns;
		
	
	arbiter1: ARBITER
		generic map(
			g_SIZE => c_SIZE
		)
		port map(
			i_REQ => s_REQ,
			o_GRT => s_GRT
		);
	
end architecture;





































