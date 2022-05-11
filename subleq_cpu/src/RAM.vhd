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
		g_ADR_LINES  : natural := 64;
		g_DATA_LINES : natural := 64;
		g_MEM_SIZE   : natural := 20
	);
	port(
		i_DATA: in  std_logic_vector(g_DATA_LINES-1 downto 0);
		i_ADR:  in  std_logic_vector(g_ADR_LINES-1  downto 0);
		i_WE:   in  std_logic;
		i_WCLK: in  std_logic;
		o_DATA: out std_logic_vector(g_DATA_LINES-1 downto 0)
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
end architecture;































