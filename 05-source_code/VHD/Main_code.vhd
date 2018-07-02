library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_ARITH.all;
use work.HOG_PACK.all;

library UNISIM;
use UNISIM.VComponents.all;

entity main_code is
port(
	clk_video : in std_logic;
	rst_system_i: in std_logic;
	
	-----design wrapper----------------------------------------------
	DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_cas_n : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    btns : in STD_LOGIC_VECTOR ( 3 downto 0 );
    leds : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sws : in STD_LOGIC_VECTOR ( 7 downto 0 );
    ---------------------------------------------------
    
    
-------------------videoin---------------------------
	data_video	 : in std_logic_vector(7 downto 0);
----------------vga-----------------------------
	r_out : out std_logic_vector(3 downto 0);
	g_out : out std_logic_vector(3 downto 0);
	b_out : out std_logic_vector(3 downto 0);
	h_sync_vga : out std_logic;
	v_sync_vga : out std_logic;		
----------sw-----------------------------		
--	sw6 :in std_logic;
--	sw5 :in std_logic;
--	sw4 :in std_logic; 
--	sw3 :in std_logic;
--	sw2 :in std_logic;  
--	sw1 :in std_logic;
--	sw0 :in std_logic;
	
----------HOG DEBUG-----------------------	
--	BlockOut : OUT BlockBin;
--	BlockDataValidOut : OUT std_logic;
----------I2C-----------------------------		
	sda : inout std_logic;
	scl : inout std_logic
);
end main_code;

architecture Behavioral of main_code is

signal rst_system : std_logic := '0';
--BRAM counter----------------------------------
signal BR_Enable_R 		: std_logic;
signal BR_WriteHigh_R	: std_logic_vector(0 downto 0);
signal BR_DataIn_R 		: std_logic_vector(7 downto 0);
signal BR_Address_R 	: integer range 0 to (524287-1);		
signal BR_Address_std_R	: std_logic_vector(18 downto 0);
signal BR_DataOut_R		: std_logic_vector(7 downto 0);

signal Bram_out : std_logic_vector(7 downto 0);

signal data_video_i: std_logic_vector ((8-1) downto 0);
--BRAM counter----------------------------------

signal r_vga:std_logic_vector(3 downto 0);
signal g_vga:std_logic_vector(3 downto 0);
signal b_vga:std_logic_vector(3 downto 0);

--video-in--parameter----------------------------------------------------------------------------------------------------
signal EAV_new : std_logic_vector(1 downto 0):="ZZ";
signal SAV_old : std_logic_vector(1 downto 0):="ZZ";
signal EAV_state : std_logic_vector(1 downto 0):="00";
signal SAV_state : std_logic_vector(1 downto 0):="00";
signal SAV_en : std_logic:='0';

signal cnt_video_hsync : integer range 0 to 1715:=0;

signal f_video_en : std_logic:='Z'; --Field
signal cnt_video_en : std_logic:='0';
signal cnt_vga_en : std_logic:='0';
signal buf_vga_en : std_logic:='0';

signal cnt_h_sync_vga : integer range 0 to 857:=0;
signal cnt_v_sync_vga : integer range 0 to 524:=0;
signal black_vga_en : std_logic:='0';
signal sync_vga_en : std_logic:='0';
signal f0_vga_en : std_logic:='0'; --Field 0
--video-in--parameter----------------------------------------------------------------------------------------------------

--VGA-8bit-------------------------------------------------------------------------------------------------------
--state-------------------------------------------------------------------------------------------------------
signal image_data_enable : std_logic:='0';

signal buf_data_state : std_logic_vector(1 downto 0):="00";
--state-------------------------------------------------------------------------------------------------------

--VGA-8bit-------------------------------------------------------------------------------------------------------
signal buf_vga_state : std_logic_vector(1 downto 0):="00";

type Array_Y is ARRAY (integer range 0 to 719) of std_logic_vector(7 downto 0);
signal buf_vga_Y : Array_Y;
signal buf_vga_Y_buf : std_logic_vector(7 downto 0);
signal buf_vga_R, buf_vga_G, buf_vga_B : Array_Y;

signal buf_vga_Y_in_cnt : integer range 0 to 719:=0;
signal buf_vga_Y_out_cnt : integer range 0 to 719:=719;

signal buf_vga_bram : Array_Y;

signal YCR_C1 : std_logic_vector(11 downto 0):=x"5a1";--constant1 of YUV convert R, 1.4075(d) * 1024(d) = 5a1(H)
signal YCG_C1 : std_logic_vector(11 downto 0):=x"161";--constant1 of YUV convert G, 0.3455(d) * 1024(d) = 161(H)
signal YCG_C2 : std_logic_vector(11 downto 0):=x"2de";--constant2 of YUV convert G, 0.7169(d) * 1024(d) = 2de(H)
signal YCB_C1 : std_logic_vector(11 downto 0):=x"71d";--constant1 of YUV convert B, 1.7790(d) * 1024(d) = 71d(H)
signal Cb_register, Cr_register : std_logic_vector(7 downto 0);

signal YCR : std_logic_vector(19 downto 0);
signal YCG : std_logic_vector(19 downto 0);
signal YCB : std_logic_vector(19 downto 0);

component design_1_wrapper is
  port (
  
       DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
     DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
     DDR_cas_n : inout STD_LOGIC;
     DDR_ck_n : inout STD_LOGIC;
     DDR_ck_p : inout STD_LOGIC;
     DDR_cke : inout STD_LOGIC;
     DDR_cs_n : inout STD_LOGIC;
     DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
     DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
     DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
     DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
     DDR_odt : inout STD_LOGIC;
     DDR_ras_n : inout STD_LOGIC;
     DDR_reset_n : inout STD_LOGIC;
     DDR_we_n : inout STD_LOGIC;
     FIXED_IO_ddr_vrn : inout STD_LOGIC;
     FIXED_IO_ddr_vrp : inout STD_LOGIC;
     FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
     FIXED_IO_ps_clk : inout STD_LOGIC;
     FIXED_IO_ps_porb : inout STD_LOGIC;
     FIXED_IO_ps_srstb : inout STD_LOGIC;
     
 
     leds : out STD_LOGIC_VECTOR ( 7 downto 0 );
     sws : in STD_LOGIC_VECTOR ( 7 downto 0 );
     
     ----AXI VDMA------------------------------------------------------------------- 
     vid_io_in_clk_0 : in STD_LOGIC;
     
     vid_data_1 : out STD_LOGIC_VECTOR ( 23 downto 0 );--( 31 downto 0 );--( 23 downto 0 );
     vid_hsync_1 : out STD_LOGIC;
     vid_vsync_1 : out STD_LOGIC;
     reset_active_low_0 : in STD_LOGIC;
     en_display_active_high_0 : in STD_LOGIC;
     ---VDMA in----------------------------------------------------------
     AXIsToVDMA_h_blank_vga_0 : in STD_LOGIC;
     AXIsToVDMA_en_0 : in STD_LOGIC;
     AXIsToVDMA_v_blank_vga_0 : in STD_LOGIC;
     AXIsToVDMA_video_data_in_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
     ---------------------------------------------------------
     BRAM_ORG_addr : in STD_LOGIC_VECTOR ( 18 downto 0 );
     BRAM_ORG_clk : in STD_LOGIC;
     BRAM_ORG_din : in STD_LOGIC_VECTOR ( 7 downto 0 );
     BRAM_ORG_en : in STD_LOGIC;
     BRAM_ORG_we : in STD_LOGIC_VECTOR ( 0 to 0 )
    

  );
end component;


     signal axi_data_i_0 : STD_LOGIC_VECTOR ( 31 downto 0 );
     signal axi_data_o_0 : STD_LOGIC_VECTOR ( 31 downto 0 );
     signal hog_data_0 : STD_LOGIC_VECTOR ( 8063 downto 0 );
     
     signal BlocksInRow_cnt : integer range 0 to 6 := 0;            --HOG count row = 7
     signal BlocksInCol_cnt : integer range 0 to 14 := 0;           --HOG count col = 15
     
     --to DMA vga-----------------------------------------------
     signal vid_io_in_0_data : STD_LOGIC_VECTOR ( 23 downto 0 );
     signal vtc_hsync_out_0 : STD_LOGIC;
     signal vtc_vsync_out_0 : STD_LOGIC;
     -----video VDMA in------------------------------------------------
     signal AXIsToVDMA_video_data_in_0 : STD_LOGIC_VECTOR ( 31 downto 0 );
     
     --out vga-----------------------------------------------
     signal vid_data_1 : STD_LOGIC_VECTOR ( 23 downto 0 );--( 31 downto 0 );--( 23 downto 0 );
     signal vid_hsync_1 : STD_LOGIC;
     signal vid_vsync_1 : STD_LOGIC;
     ---------------------------------------------------------
     signal BRAM_ORG_addr : STD_LOGIC_VECTOR ( 18 downto 0 );
     signal BRAM_ORG_din : STD_LOGIC_VECTOR ( 7 downto 0 );
     signal BRAM_ORG_en : STD_LOGIC;
--VGA-8bit-------------------------------------------------------------------------------------------------------
component i2c
Port (
		 clk : IN  std_logic;
		 rst: IN  std_logic;
		 sda : inout std_logic;
		 scl : inout std_logic
);
end component;

component video_in
Port ( 
		clk_video  : IN  std_logic;
		rst_system : IN  std_logic;
		data_video : IN  std_logic_vector(7 downto 0)  ;
		f_video_en : inout std_logic;
		cnt_video_en : inout std_logic;
		cnt_vga_en : inout std_logic ;
		buf_vga_en : inout std_logic ;
		cnt_video_hsync : inout  integer range 0 to 1715;
		f0_vga_en : inout std_logic;
	 
		black_vga_en :inout  std_logic;
		cnt_h_sync_vga :inout integer range 0 to 857;
		cnt_v_sync_vga :inout integer range 0 to 524;
		sync_vga_en : inout  std_logic;
		v_sync_vga : out  std_logic;
		h_sync_vga : out  std_logic;
		h_blank_vga : out  std_logic;
        v_blank_vga : out  std_logic
);
end component;

	signal h_sync_vga_buf : std_logic;
    signal v_sync_vga_buf : std_logic;  
    signal h_blank_vga_buf : std_logic;
    signal v_blank_vga_buf : std_logic;

component sobel is
port (
        clk_video  : IN  std_logic;
        rst_system : IN  std_logic;
--**
        data_video: in std_logic_vector (7 downto 0);
--**        
        image_data_enable : in  std_logic;
        cnt_h_sync_vga :in integer range 0 to 857;
        cnt_v_sync_vga :in integer range 0 to 524;
        buf_vga_Y_out_cnt :in integer range 0 to 719;
        
        SB_XSCR_o : out std_logic_vector((10-1) downto 0):="0000000000";
        SB_YSCR_o : out std_logic_vector((10-1) downto 0):="0000000000";
        SB_SCR_o : out std_logic_vector((12-1) downto 0):="000000000000"

);
end component;

signal SB_XSCR,SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
signal SB_SCR : std_logic_vector((12-1) downto 0):="000000000000";
signal sobel_data_video_in : std_logic_vector(7 downto 0) := "00000000";
signal SB_SCR_Thresholding : std_logic_vector(11 downto 0):="000000000000";
signal SB_SCR_Thr_video : std_logic_vector(7 downto 0):="00000000";

signal F : std_logic_vector(25 downto 0);


----64bit display-------------------------------------------------------------------------------------------
component number_hex_64bit
Generic(set_left : integer range 0 to 719 :=0;
        set_top  : integer range 0 to 480 :=0);
Port ( 
        number_64_in : in STD_LOGIC_VECTOR (63 downto 0);
        
        cnt_h_sync_vga :in integer range 0 to 857;
        cnt_v_sync_vga :in integer range 0 to 524;
        
        number_64_display_area :out std_logic;
        number_64_out :out std_logic
);
end component;
signal SB_SCR_Thresholding_show : std_logic_vector(63 downto 0):= (others=>'0');
signal number_display_area : std_logic:='0';
signal number_out : std_logic:='0';




begin

rst_system <= not rst_system_i;

with sws(1) select
v_sync_vga<= vid_vsync_1 when '1',--"01",
             v_sync_vga_buf when others;


with sws(1) select
h_sync_vga<= vid_hsync_1 when '1',--"01",
             h_sync_vga_buf when others;

with sws(0) select
    r_out<= vid_data_1(7 downto 4) when '1',
            r_vga when others;

with sws(0) select
    g_out<= vid_data_1(15 downto 12) when '1',
            g_vga when others;
            
with sws(0) select
    b_out<= vid_data_1(23 downto 20) when '1',
            b_vga when others;    
            
                                  
 vid_io_in_0_data <= data_video_i & data_video_i & data_video_i;
 AXIsToVDMA_video_data_in_0 <= "00000000" & data_video_i & data_video_i & data_video_i;

  

design_wrapper:design_1_wrapper 
  port map(
    DDR_addr => DDR_addr,
    DDR_ba => DDR_ba,
    DDR_cas_n => DDR_cas_n,
    DDR_ck_n => DDR_ck_n,
    DDR_ck_p => DDR_ck_p,
    DDR_cke => DDR_cke,
    DDR_cs_n => DDR_cs_n,
    DDR_dm => DDR_dm,
    DDR_dq => DDR_dq,
    DDR_dqs_n => DDR_dqs_n,
    DDR_dqs_p  => DDR_dqs_p,
    DDR_odt  => DDR_odt,
    DDR_ras_n => DDR_ras_n,
    DDR_reset_n  => DDR_reset_n,
    DDR_we_n  => DDR_we_n,
    FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
    FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
    FIXED_IO_mio => FIXED_IO_mio,
    FIXED_IO_ps_clk  => FIXED_IO_ps_clk,
    FIXED_IO_ps_porb  => FIXED_IO_ps_porb,
    FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
    

    leds => leds,
    sws => sws,
    
    vid_io_in_clk_0 => clk_video,
    

    
    vid_data_1 => vid_data_1,
    vid_hsync_1 => vid_hsync_1,
    vid_vsync_1 => vid_vsync_1,
    reset_active_low_0 => rst_system,
    en_display_active_high_0 => cnt_vga_en,
    
    ---video VDMA in-------------------------------------------
    AXIsToVDMA_h_blank_vga_0 => h_blank_vga_buf,
    AXIsToVDMA_v_blank_vga_0 => v_blank_vga_buf,
    AXIsToVDMA_en_0 => cnt_vga_en,
    AXIsToVDMA_video_data_in_0 => AXIsToVDMA_video_data_in_0,
    --------------------------------------
    BRAM_ORG_addr => BRAM_ORG_addr,
    BRAM_ORG_clk => clk_video,
    BRAM_ORG_din => BRAM_ORG_din,
    BRAM_ORG_en => BRAM_ORG_en,
    BRAM_ORG_we => "1"
      
  );

i2c_1 :i2c
PORT MAP (
		clk => clk_video,
		rst => rst_system,
		sda => sda,
		scl => scl
);						
VIDEO_IN1 : video_in
PORT MAP (
		clk_video  =>clk_video,
		rst_system =>rst_system,
		data_video =>data_video,
		f_video_en =>f_video_en,
		cnt_video_en =>cnt_video_en,
		cnt_vga_en =>cnt_vga_en,
		buf_vga_en =>buf_vga_en,
		cnt_video_hsync =>cnt_video_hsync,
		f0_vga_en =>f0_vga_en,
	   
		black_vga_en =>black_vga_en,
		cnt_h_sync_vga =>cnt_h_sync_vga,
		cnt_v_sync_vga =>cnt_v_sync_vga,
		sync_vga_en =>sync_vga_en,
		v_sync_vga =>v_sync_vga_buf,--v_sync_vga,
		h_sync_vga =>h_sync_vga_buf,--h_sync_vga 
		h_blank_vga => h_blank_vga_buf,
        v_blank_vga => v_blank_vga_buf            
);			

sobel_all : sobel 
PORT MAP (
        clk_video  =>clk_video,
		rst_system =>rst_system,
		data_video =>sobel_data_video_in,

        image_data_enable => image_data_enable,
		cnt_h_sync_vga =>cnt_h_sync_vga,
        cnt_v_sync_vga =>cnt_v_sync_vga,
        buf_vga_Y_out_cnt => buf_vga_Y_out_cnt,
        
        SB_XSCR_o => SB_XSCR,
        SB_YSCR_o => SB_YSCR,
        SB_SCR_o => SB_SCR

);

diplay:number_hex_64bit
        Generic map(set_left => 80,
        set_top  => 450
        )
        Port map(
        number_64_in => SB_SCR_Thresholding_show,
        
        cnt_h_sync_vga => cnt_h_sync_vga,
        cnt_v_sync_vga => cnt_v_sync_vga,
        
        number_64_display_area => number_display_area,
        number_64_out => number_out
        );  

			
sobel_data_video_in <= buf_vga_Y(buf_vga_Y_out_cnt);

with sws(6 downto 4) select 
data_video_i <= buf_vga_Y(buf_vga_Y_out_cnt) when "000",
                buf_vga_Y(buf_vga_Y_out_cnt) when "001",
                buf_vga_Y(buf_vga_Y_out_cnt) when "010",
                buf_vga_Y(buf_vga_Y_out_cnt) when "011",
                SB_SCR(10 downto 3) when "110",
                SB_SCR_Thr_video when "111",
                SB_XSCR(9 downto 2) when "100",
                SB_YSCR(9 downto 2) when "101",
                "00000000" when others;
--axi_data_o_0 <= axi_data_i_0;

process(rst_system, clk_video , F)
begin
    if rst_system = '0' then
        SB_SCR_Thresholding <= (others=>'0');
    elsif rising_edge(F(17)) then		
        if btns(3)='1' then
            SB_SCR_Thresholding <= SB_SCR_Thresholding + 1;
        elsif btns(0)='1' then
            SB_SCR_Thresholding <= SB_SCR_Thresholding - 1;
        end if;
    end if;
    
    --Divider-----------------------
    if rst_system = '0' then   
        F <= (others=>'0');
    elsif rising_edge(clk_video) then
        F <= F + 1;
    end if;  
    
     
end process;

SB_SCR_Thr_video <= "11111111" when SB_SCR >= SB_SCR_Thresholding else "00000000";
SB_SCR_Thresholding_show(11 downto 0) <= SB_SCR_Thresholding;

			
--VGA-RGB-9bit----------------------------------------------------------------------------------------------------
VGA_OUT_Control:process(rst_system, clk_video)
begin
if rst_system = '0' then
	r_vga <= "0000";
	g_vga <= "0000";
	b_vga <= "0000";
	buf_vga_Y_out_cnt <= 0;
	BRAM_ORG_en <= '0';
elsif rising_edge(clk_video) then				
    if ( cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 720 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
	    buf_vga_Y_out_cnt <= buf_vga_Y_out_cnt - 1;
		
		---BRAM ORG picture--------------------------------
		BRAM_ORG_addr <= conv_std_logic_vector(cnt_v_sync_vga*720+cnt_h_sync_vga,19);
		BRAM_ORG_din <= data_video_i;
		BRAM_ORG_en <= '1';
		---------------------------------------------------
		
		if number_out = '1' and sws(6 downto 4)="111" then
		      r_vga <= "1111";
              g_vga <= "1111";
              b_vga <= "1111";
		elsif number_display_area = '1' and sws(6 downto 4)="111" then
              r_vga <= "0000";
              g_vga <= "0000";
              b_vga <= "0000";
		else
            r_vga <= data_video_i(7 downto 4);
            g_vga <= data_video_i(7 downto 4);
            b_vga <= data_video_i(7 downto 4);
        end if;
		
 
        
                         
    else
		r_vga <= "0000";
		g_vga <= "0000";
		b_vga <= "0000";
		buf_vga_Y_out_cnt <= 719;
		BRAM_ORG_en <= '0';
    end if;
end if;
end process;

--Buf-state---------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
	if rst_system = '0' then	
		image_data_enable <= '0';
		buf_data_state <= "00";
	else
		if rising_edge(clk_video) then
			if (buf_vga_en = '1' and (cnt_video_hsync >= 0 and cnt_video_hsync < 1440 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480)) then --buf_vga_en >>image begin enable      (cnt_video_hsync < 1290)  >> 640*2 =1280  effective data			
				buf_data_state <= buf_data_state + '1';--cb(00)  Y(01)  cr(10)  Y(11)  			
				image_data_enable <= '1';							
			else			
				image_data_enable <= '0';			
				buf_data_state <= "00";
			end if;
		end if;
	end if;
end process;
--Buf-state---------------------------------------------------------------------------------------------------

video_buffer : process(rst_system, clk_video)
begin
if rst_system = '0' then
	buf_vga_state <= "00";
	buf_vga_Y_in_cnt <= 0;

	YCR <= x"00000"; --YUV convert R
	YCG <= x"00000"; --YUV convert G
	YCB <= x"00000"; --YUV convert B

	Cr_register <= x"00";
	Cb_register <= x"00";
else
	if rising_edge(clk_video) then
		if (buf_vga_en = '1' and cnt_video_hsync < 1440) then

			case buf_vga_state(0) is
				when '0' =>	buf_vga_state <= buf_vga_state + "01"; --the vdata is Cb

                when '1' =>	buf_vga_state <= buf_vga_state + "01"; --the vdata is Y
				   
					if buf_vga_Y_in_cnt = 719 then
						buf_vga_Y_in_cnt <= 0;
					else
						buf_vga_Y_in_cnt <= buf_vga_Y_in_cnt + 1;
					end if;		
							
					buf_vga_Y(buf_vga_Y_in_cnt) <= data_video(7 downto 0);
				when others => null;
			end case;
		else
			buf_vga_state        <= "00";
			buf_vga_Y_in_cnt     <= 0;
			YCR                  <= x"00000";
			YCG                  <= x"00000";
			YCB                  <= x"00000";
		end if;
	end if;
end if;
end process;
end Behavioral;

