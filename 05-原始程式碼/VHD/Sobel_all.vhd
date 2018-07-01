--8CC  => 8 connected component
library IEEE;

use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity sobel is
    --Generic(
    --    threshold : integer range 0 to 1023:=128;
    --    ksize : integer range 1 to 3 :=3
    --);
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
    --        SB_data_out_vga :out std_logic;
    --        SB_gradient_out : out std_logic_vector(10 downto 0);
    --        SB_angle_out : out std_logic_vector(7 downto 0)
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
    --signal arctan_x_out :STD_LOGIC_VECTOR(14 downto 0):=(others=>'0');
    
    --component arctan
    --Generic(iteration_time : integer;
    --            mode : integer);-- mode0 : Combinatorial logic  mode1 : pipline 
    --    Port (
    --        clk : in STD_LOGIC;
    --        rst : in STD_LOGIC;
    --        x_in : in STD_LOGIC_VECTOR(14 downto 0);
    --        y_in : in STD_LOGIC_VECTOR(14 downto 0);
    --        x_out : out STD_LOGIC_VECTOR(14 downto 0);
    --        z_out : out STD_LOGIC_VECTOR(7 downto 0)
    --     );
    --end component;
    ----------|
    --SB End--|
    ----------|

begin
    
    --arctan_1 :arctan
    --    GENERIC MAP(
    --         iteration_time => 7,
    --         mode => 0   
    --    )
    --    PORT MAP (
    --			 clk => clk_video,
    --			 rst => rst_system,
    --			 x_in(9 downto 0) => SB_XSCR,
    --			 x_in(14 downto 10) => (others=>'0'),
    --			 y_in(9 downto 0) => SB_YSCR,
    --             y_in(14 downto 10) => (others=>'0'),
    --			 x_out => arctan_x_out,
    --			 z_out => angle
    --			);	
--    process(rst_system, clk_video)
--    begin
--        if rst_system = '0' then
        
--        elsif rising_edge(clk_video) then
--            if image_data_enable='1' then
--                 SB_buf_0(buf_vga_Y_out_cnt) <= SB_buf_1(buf_vga_Y_out_cnt);
--                 SB_buf_1(buf_vga_Y_out_cnt) <= SB_buf_2(buf_vga_Y_out_cnt);
--                 SB_buf_2(buf_vga_Y_out_cnt) <= data_video;        
--            end if;
--        end if;
--    end process;
    
    
    process(rst_system, clk_video)
        variable sobel_x_cc_1 : std_logic_vector(9 downto 0);
        variable sobel_x_cc_2 : std_logic_vector(9 downto 0);
        variable sobel_y_cc_1 : std_logic_vector(9 downto 0);
        variable sobel_y_cc_2 : std_logic_vector(9 downto 0);
    
        --variable SB_XSCR : std_logic_vector((10-1) downto 0):="0000000000";
        --variable SB_YSCR : std_logic_vector((10-1) downto 0):="0000000000";
        --variable SB_SCR : std_logic_vector((12-1) downto 0):="000000000000";
        --variable SB_XSCR_isneg : std_logic;
        --variable SB_YSCR_isneg : std_logic;
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
    --	SB_data_out_vga <= '0';
    -------------------- Return to begin--------------------	
        SB_XSCR_isneg <= '0';
        SB_YSCR_isneg <= '0';
    --    SB_angle_out <= (others=>'0');
    --    SB_gradient_out <= (others=>'0');
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
    --			if ksize = 1 then
    --                if SB_buf_0_data_3 >= SB_buf_0_data_1 then
    --                    SB_XSCR <= SB_buf_0_data_3 - SB_buf_0_data_1;
    --                    SB_XSCR_isneg := '0';
    --                else
    --                    SB_XSCR <= SB_buf_0_data_1 - SB_buf_0_data_3;
    --                    SB_XSCR_isneg := '1';
    --                end if;
                    
    --                if SB_buf_2_data_2 >= SB_buf_0_data_2 then
    --                    SB_YSCR <= SB_buf_2_data_2 - SB_buf_0_data_2;
    --                    SB_YSCR_isneg := '0';
    --                else
    --                    SB_YSCR <= SB_buf_0_data_2 - SB_buf_2_data_2;
    --                    SB_YSCR_isneg := '1';
    --                end if;
    --            else
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
                    
--                    if SB_XSCR_isneg = SB_YSCR_isneg then
                        SB_SCR <= ("00" & SB_XSCR) + ("00" & SB_YSCR);
--                    else
--                        if SB_XSCR_isneg > SB_YSCR_isneg then
--                            SB_SCR(9 downto 0) <= SB_XSCR - SB_YSCR;
--                        else
--                            SB_SCR(9 downto 0) <= SB_YSCR - SB_XSCR;
--                        end if;
--                    end if;
                    
    --            end if;			        
    ---------------------- Operation Point Weights--------------------
    
    ----------------------Angle Operate--------------------------------
    --                if(SB_XSCR_isneg = '0' and SB_YSCR_isneg = '0')then
    --                    if(angle > "01011010")then
    --                        SB_angle_out <= "01011010"; --90
    --                    else
    --                        SB_angle_out <= angle;
    --                    end if;
    --                elsif(SB_XSCR_isneg = '1' and SB_YSCR_isneg = '0')then
    --                    if(angle > "01011010")then
    --                        SB_angle_out <= "01011010"; --90
    --                    else
    --                        SB_angle_out <= "10110100" - angle; --180 - angle 
    --                    end if;
    --               elsif(SB_XSCR_isneg = '1' and SB_YSCR_isneg = '1')then
    --                    if(angle > "01011010")then
    --                        SB_angle_out <= "01011010"; --90
    --                    else
    --                        SB_angle_out <= angle; -- angle 
    --                    end if;                   
    --                else
    --                    if(angle > "01011010")then
    --                        SB_angle_out <= "01011010"; --270
    --                    else
    --                        SB_angle_out <= "10110100" - angle; --180  -  angle
    --                    end if;
    --                end if;
    --                SB_gradient_out <= arctan_x_out(10 downto 0);
    ----------------------Angle Operate--------------------------------
    --------------------critical result------------------					    				    
    --				if (arctan_x_out > std_logic_vector(to_signed(threshold,10))) then				
    --					SB_data_out_vga <= '1';
    --				else
    --					SB_data_out_vga <= '0';
    --				end if;			    				
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
    --			SB_data_out_vga <= '0';			
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


