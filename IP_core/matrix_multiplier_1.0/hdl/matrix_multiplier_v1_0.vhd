library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.utils_pkg.all;

entity matrix_multiplier_v1_0 is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;
    --integer(ceil(log2(real(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE))))
		-- Matrix A memory interface
		a_addr_o: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		a_data_i: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		a_wr_o: out std_logic_vector(3 downto 0);
		a_en_o: out std_logic;
		-- Matrix B memory interface
		b_addr_o: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		b_data_i: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		b_wr_o: out std_logic_vector(3 downto 0);
		b_en_o: out std_logic;
		-- Matrix C memory interface
		c_addr_o: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		c_data_o: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		c_wr_o: out std_logic_vector(3 downto 0);
		c_en_o: out std_logic
	);
end matrix_multiplier_v1_0;

architecture arch_imp of matrix_multiplier_v1_0 is
        
        
        constant C_S00_AXI_MAX_SIZE : integer := 8;
		signal a_addr_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-1 downto 0);
		signal a_data_s: std_logic_vector(11 downto 0);
		signal a_wr_s: std_logic;
		-- Matrix B memory interface
		signal b_addr_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-1 downto 0);
		signal b_data_s: std_logic_vector(11 downto 0);
		signal b_wr_s: std_logic;
		-- Matrix dimensions definition interface
		signal n_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		signal p_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		signal m_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		------------------- Output data interface ------------------
		-- Matrix C memory interface
		signal c_addr_s: std_logic_vector(log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-1 downto 0);
		signal c_data_s: std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		signal c_wr_s:  std_logic;
		--------------------- Command interface --------------------
		signal start_s:  std_logic;
		--------------------- Status interface ---------------------
		signal ready_s:  std_logic;

	-- component declaration
	component matrix_multiplier_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_MAX_SIZE	: integer	:= 8;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		n_out: out std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		p_out: out std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		m_out: out std_logic_vector(log2c(C_S00_AXI_MAX_SIZE)-1 downto 0);
		start: out std_logic;
		ready: in std_logic;
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component matrix_multiplier_v1_0_S00_AXI;

begin

-- Instantiation of Axi Bus Interface S00_AXI
matrix_multiplier_v1_0_S00_AXI_inst : matrix_multiplier_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_MAX_SIZE => C_S00_AXI_MAX_SIZE,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
	    n_out => n_s,
		p_out => p_s,
		m_out => m_s,
		start => start_s,
		ready => ready_s,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

	-- Add user logic here
matrix_multiplier_core : entity work.matrix_mult(two_seg_arch)
generic map ( 
		WIDTH => 12,
		SIZE => C_S00_AXI_MAX_SIZE
		)
    port map (
		--------------- Clocking and reset interface ---------------
		clk => s00_axi_aclk,
		reset => s00_axi_aresetn,
		------------------- Input data interface -------------------
		-- Matrix A memory interface
		a_addr_o => a_addr_s,
		a_data_i => a_data_s,
		a_wr_o => a_wr_s,
		-- Matrix B memory interface =>
		b_addr_o => b_addr_s,
		b_data_i =>b_data_s,
		b_wr_o =>b_wr_s,
		-- Matrix dimensions definition interface
		n_in =>n_s,
		p_in =>p_s,
		m_in =>m_s,
		------------------- Output data interface ------------------
		-- Matrix C memory interface
		c_addr_o =>c_addr_s,
		c_data_o =>c_data_s,
		c_wr_o =>c_wr_s,
		--------------------- Command interface -------------------- =>
		start =>start_s,
		--------------------- Status interface ---------------------
		ready =>ready_s
);


a_addr_o <= std_logic_vector(to_unsigned(0,C_S00_AXI_DATA_WIDTH-log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-2)) & a_addr_s & "00";
b_addr_o <= std_logic_vector(to_unsigned(0,C_S00_AXI_DATA_WIDTH-log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-2)) & b_addr_s & "00";
c_addr_o <= std_logic_vector(to_unsigned(0,C_S00_AXI_DATA_WIDTH-log2c(C_S00_AXI_MAX_SIZE*C_S00_AXI_MAX_SIZE)-2)) & c_addr_s & "00";
a_data_s <= a_data_i(11 downto 0);
b_data_s <= b_data_i(11 downto 0);
c_data_o <= c_data_s;
a_wr_o <= (others=>a_wr_s);
b_wr_o <= (others=>b_wr_s);
c_wr_o <= (others=>c_wr_s);
a_en_o <= '1';
b_en_o <= '1';
c_en_o <= '1';
	-- User logic ends

end arch_imp;
