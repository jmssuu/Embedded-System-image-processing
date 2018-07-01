--8CC  => 8 connected component
library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sobel is

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
    end sobel;
    
architecture Behavioral of sobel is
    ---------------------|
    --SB = Sobel Buffer--|
    ---------------------|
    type Array_Sobel_buf is array (integer range 0 to 719) of std_logic_vector ((8-1) downto 0);
    signal SB_buf_0 : Array_Sobel_buf;
    signal SB_buf_0_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_0_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_0_data_3 : std_logic_vector((10-1) downto 0):="0000000000";
    
    signal SB_buf_1 : Array_Sobel_buf;
    signal SB_buf_1_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_1_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_1_data_3 : std_logic_vector((10-1) downto 0):="0000000000";
    
    signal SB_buf_2 : Array_Sobel_buf;
    signal SB_buf_2_data_1 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_2_data_2 : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_buf_2_data_3 : std_logic_vector((10-1) downto 0):="0000000000";
    
    
    
    signal SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
    signal SB_SCR : std_logic_vector((12-1) downto 0):="000000000000";
    --signal SB_data_out_vga : std_logic:='0';
    signal SB_XSCR_isneg : std_logic;
    signal SB_YSCR_isneg : std_logic;
    
    signal angle : STD_LOGIC_VECTOR(7 downto 0):=(others=>'0');


begin
    
    process(rst_system, clk_video)
        variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
        variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
        variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
        variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
    
    begin
    if rst_system = '0' then
    -------------------- Return to begin--------------------
        SB_buf_0_data_1 <= "0000000000";
        SB_buf_0_data_2 <= "0000000000";
        SB_buf_0_data_3 <= "0000000000";
        SB_buf_1_data_1 <= "0000000000";
        SB_buf_1_data_2 <= "0000000000";
        SB_buf_1_data_3 <= "0000000000";
        SB_buf_2_data_1 <= "0000000000";
        SB_buf_2_data_2 <= "0000000000";
        SB_buf_2_data_3 <= "0000000000";
        
    -------------------- Return to begin--------------------	
        SB_XSCR <= "0000000000";
        SB_YSCR <= "0000000000";
        SB_SCR <= "000000000000";

    -------------------- Return to begin--------------------	
        SB_XSCR_isneg <= '0';
        SB_YSCR_isneg <= '0';

    -------------------- Return to begin--------------------	
    elsif rising_edge(clk_video) then
            if ( cnt_h_sync_vga >= 0 and cnt_h_sync_vga < 720 and cnt_v_sync_vga >= 0 and cnt_v_sync_vga < 480) then
    -- 01 02 03
    -- 11 12 13
    -- 21 22 (23)   >>(now_data)		 		    				    			
    --------------------GET IN data------------------	
                SB_buf_0_data_3 <= "00" & SB_buf_1(buf_vga_Y_out_cnt);
                SB_buf_0_data_2 <= SB_buf_0_data_3;
                SB_buf_0_data_1 <= SB_buf_0_data_2;
    
                SB_buf_1_data_3 <= "00" & SB_buf_2(buf_vga_Y_out_cnt);
                SB_buf_1_data_2 <= SB_buf_1_data_3;
                SB_buf_1_data_1 <= SB_buf_1_data_2;
    
                -----------****--data in--****---------------------------- 
                SB_buf_2_data_3 <= "00" & data_video;
                -----------****--data in--****----------------------------
                SB_buf_2_data_2 <= "00" &SB_buf_2(buf_vga_Y_out_cnt + 1);
                SB_buf_2_data_1 <= "00" &SB_buf_2(buf_vga_Y_out_cnt + 2);
    
        
                SB_buf_0(buf_vga_Y_out_cnt) <= SB_buf_1(buf_vga_Y_out_cnt);
                SB_buf_1(buf_vga_Y_out_cnt) <= SB_buf_2(buf_vga_Y_out_cnt);
                -----------****--data in--****----------------------------
                SB_buf_2(buf_vga_Y_out_cnt) <= data_video;				
    --------------------GET IN data------------------	
    ---------------------- Operation Point Weights--------------------

                    sobel_y_cc_1 := SB_buf_0_data_1 + SB_buf_0_data_2 + SB_buf_0_data_2 + SB_buf_0_data_3;                
                    sobel_y_cc_2 := SB_buf_2_data_1 + SB_buf_2_data_2 + SB_buf_2_data_2 + SB_buf_2_data_3;                
                    sobel_x_cc_1 := SB_buf_0_data_1 + SB_buf_1_data_1 + SB_buf_1_data_1 + SB_buf_2_data_1;                
                    sobel_x_cc_2 := SB_buf_0_data_3 + SB_buf_1_data_3 + SB_buf_1_data_3 + SB_buf_2_data_3;
        
                    if sobel_x_cc_2 >= sobel_x_cc_1 then
                        SB_XSCR <= sobel_x_cc_2 - sobel_x_cc_1;
                        SB_XSCR_isneg <= '0';
                    else
                        SB_XSCR <= sobel_x_cc_1 - sobel_x_cc_2;
                        SB_XSCR_isneg <= '1';
                    end if;
                                
                    if sobel_y_cc_2 >= sobel_y_cc_1 then
                        SB_YSCR <= sobel_y_cc_2 - sobel_y_cc_1;
                        SB_YSCR_isneg <= '0';
                    else
                        SB_YSCR <= sobel_y_cc_1 - sobel_y_cc_2;
                        SB_YSCR_isneg <= '1';
                    end if;
                    

                        SB_SCR <= ("00" & SB_XSCR) + ("00" & SB_YSCR);
		        
   	    				
    --------------------critical result------------------
            elsif image_data_enable = '0' then --range outside
    -------------------- Return to begin--------------------		
                SB_buf_0_data_1 <= "0000000000";
                SB_buf_0_data_2 <= "0000000000";
                SB_buf_0_data_3 <= "0000000000";
                SB_buf_1_data_1 <= "0000000000";
                SB_buf_1_data_2 <= "0000000000";
                SB_buf_1_data_3 <= "0000000000";
                SB_buf_2_data_1 <= "0000000000";
                SB_buf_2_data_2 <= "0000000000";
                SB_buf_2_data_3 <= "0000000000";			
    -------------------- Return to begin--------------------
                SB_XSCR <= "0000000000";
                SB_YSCR <= "0000000000";
	
    -------------------- Return to begin--------------------
            else
                null;
            end if;
    end if;
    
    SB_SCR_o <= SB_SCR;
    SB_XSCR_o <= SB_XSCR;
    SB_YSCR_o <= SB_YSCR;
    
    end process;
    --Sobel-------------------------------------------------------------------------------------------------
end architecture;


