library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.utils_pkg.all;

entity matrix_mult_tb is
end entity;

architecture beh of matrix_mult_tb is
    
    constant DATA_WIDTH_c: integer := 12;
    constant SIZE_c: integer := 8;
    constant N_c: integer := 2;
    constant M_c: integer := 4;
    constant P_c: integer := 2;
    type mem_t is array (0 to SIZE_c*SIZE_c-1) of
    std_logic_vector(DATA_WIDTH_c-1 downto 0);
   
    
    signal clk_s: std_logic;
    signal reset_s: std_logic;
    signal n_in_s: std_logic_vector(log2c(SIZE_c)-1 downto 0);
    signal m_in_s: std_logic_vector(log2c(SIZE_c)-1 downto 0);
    signal p_in_s: std_logic_vector(log2c(SIZE_c)-1 downto 0);
-- Matrix A memory interface
    signal mem_a_addr_s: std_logic_vector(log2c(SIZE_c*SIZE_c)-1 downto 0);
    signal mem_a_data_in_s: std_logic_vector(DATA_WIDTH_c-1 downto 0);
    signal mem_a_wr_s: std_logic;
    signal a_addr_s: std_logic_vector(log2c(SIZE_c*SIZE_c)-1 downto 0);
    signal a_data_in_s: std_logic_vector(DATA_WIDTH_c-1 downto 0);
    signal a_wr_s: std_logic;
-- Matrix B memory interface
    signal mem_b_addr_s: std_logic_vector(log2c(SIZE_c*SIZE_c)-1 downto 0);
    signal mem_b_data_in_s: std_logic_vector(DATA_WIDTH_c-1 downto 0);
    signal mem_b_wr_s: std_logic;
    signal b_addr_s: std_logic_vector(log2c(SIZE_c*SIZE_c)-1 downto 0);
    signal b_data_in_s: std_logic_vector(DATA_WIDTH_c-1 downto 0);
    signal b_wr_s: std_logic;
-- Matrix C memory interface
    signal c_addr_s: std_logic_vector(log2c(SIZE_c*SIZE_c)-1 downto 0);
    signal c_data_out_s: std_logic_vector(2*DATA_WIDTH_c+SIZE_c-1 downto 0);
    signal c_wr_s: std_logic;
-- Control
    signal start_s: std_logic := '0';
    signal ready_s: std_logic;
begin

clk_gen: process
	begin
	clk_s <= '0', '1' after 10 ns;
	wait for 10 ns;
	end process;

stim_gen: process
begin
	-- Apply system level reset
	reset_s <= '1';
	wait for 500 ns;
	reset_s <= '0';
	wait until falling_edge(clk_s);
	-- Load the data into the matrix A memory
	mem_a_wr_s <= '1';
	for i in 0 to N_c-1 loop
		for j in 0 to M_c-1 loop
			mem_a_addr_s <= conv_std_logic_vector(i*M_c+j, mem_a_addr_s'length);
			mem_a_data_in_s <= conv_std_logic_vector((i*M_c+j),DATA_WIDTH_c);
			wait until falling_edge(clk_s);
		end loop;
	end loop;
	mem_a_wr_s <= '0';
-- Load the data into the matrix B memory
	mem_b_wr_s <= '1';
	for i in 0 to M_c-1 loop
		for j in 0 to P_c-1 loop
			mem_b_addr_s <= conv_std_logic_vector(i*P_c+j, mem_b_addr_s'length);
			mem_b_data_in_s <= conv_std_logic_vector((i*P_c+j),DATA_WIDTH_c);
			wait until falling_edge(clk_s);
		end loop;
	end loop;
	mem_b_wr_s <= '0';
-- Start the multiplication process
	start_s <= '1';
	wait until falling_edge(clk_s);
	start_s <= '0';
-- Wait until matrix multiplication module signals operation has been complted
	wait until ready_s = '1';
-- End stimulus generation
	wait;
end process;

-- Matrix A memory
matrix_a_mem: entity work.dp_memory(beh)
generic map (
	WIDTH => DATA_WIDTH_c,
	SIZE => SIZE_c)
port map (
	clk => clk_s,
	reset => reset_s,
	p1_addr_i => mem_a_addr_s,
	p1_data_i => mem_a_data_in_s,
	p1_data_o => open,
	p1_wr_i => mem_a_wr_s,
	p2_addr_i => a_addr_s,
	p2_data_i => (others => '0'),
	p2_data_o => a_data_in_s,
	p2_wr_i => a_wr_s);
-- Matrix B memory
matrix_b_mem: entity work.dp_memory(beh)
generic map (
	WIDTH => DATA_WIDTH_c,
	SIZE => SIZE_c)
port map (
	clk => clk_s,
	reset => reset_s,
	p1_addr_i => mem_b_addr_s,
	p1_data_i => mem_b_data_in_s,
	p1_data_o => open,
	p1_wr_i => mem_b_wr_s,
	p2_addr_i => b_addr_s,
	p2_data_i => (others => '0'),
	p2_data_o => b_data_in_s,
	p2_wr_i => b_wr_s);
-- Matrix C memory
matrix_c_mem: entity work.dp_memory(beh)
generic map (
	WIDTH => 2*DATA_WIDTH_c+SIZE_c,
	SIZE => SIZE_c)
port map (
	clk => clk_s,
	reset => reset_s,
	p1_addr_i => (others => '0'),
	p1_data_i => (others => '0'),
	p1_data_o => open,
	p1_wr_i => '0',
	p2_addr_i => c_addr_s,
	p2_data_i => c_data_out_s,
	p2_data_o => open,
	p2_wr_i => c_wr_s);
-- DUT
n_in_s <= conv_std_logic_vector(N_c, log2c(SIZE_c));
p_in_s <= conv_std_logic_vector(P_c, log2c(SIZE_c));
m_in_s <= conv_std_logic_vector(M_c, log2c(SIZE_c));
matrix_multiplication_core: entity work.matrix_mult(two_seg_arch)

generic map (
	WIDTH => DATA_WIDTH_c,
	SIZE => SIZE_c)
port map (
--------------- Clocking and reset interface ---------------
clk => clk_s,
reset => reset_s,
------------------- Input data interface -------------------
-- Matrix A memory interface
a_addr_o => a_addr_s,
a_data_i => a_data_in_s,
a_wr_o => a_wr_s,
-- Matrix B memory interface
b_addr_o => b_addr_s,
b_data_i => b_data_in_s,
b_wr_o => b_wr_s,
-- Matrix dimensions definition interface
n_in => n_in_s,
p_in => p_in_s,
m_in => m_in_s,
------------------- Output data interface ------------------
-- Matrix C memory interface
c_addr_o => c_addr_s,
c_data_o => c_data_out_s,
c_wr_o => c_wr_s,
--------------------- Command interface --------------------
start => start_s,
--------------------- Status interface ---------------------
ready => ready_s);
end architecture beh;
