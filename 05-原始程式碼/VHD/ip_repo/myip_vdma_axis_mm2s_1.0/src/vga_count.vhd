
library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity VGA_count is
port (
        clk_video  : IN  std_logic;
        rst_system : IN  std_logic;
--        f_video_en : IN std_logic;
--        f0_vga_en  : IN std_logic;
        cnt_vga_en : IN std_logic;
--        black_vga_en :inout  std_logic;
        cnt_h_sync_vga :out integer range 0 to 857;
        cnt_v_sync_vga :out integer range 0 to 524;
        sync_vga_en : out  std_logic;
        h_sync_vga : out  std_logic;
        v_sync_vga : out  std_logic;
        h_blank_vga : out  std_logic;
        v_blank_vga : out  std_logic;
        
        axis_start	: in std_logic
        
);
end VGA_count;
architecture Behavioral of VGA_count is

      signal cnt_h_sync_vga_inn : integer range 0 to 857;
      signal cnt_v_sync_vga_inn : integer range 0 to 524;
      signal sync_vga_en_inn :   std_logic;

--signal h_sync_vga : std_logic:='0';
--signal v_sync_vga : std_logic:='0';
begin

  cnt_h_sync_vga <= cnt_h_sync_vga_inn ;
  cnt_v_sync_vga <= cnt_v_sync_vga_inn;
  sync_vga_en <= sync_vga_en_inn ;
      


process(rst_system, clk_video)
begin
if rst_system = '0' then
	--black_vga_en <= '0';
	cnt_h_sync_vga_inn <= 0;
	cnt_v_sync_vga_inn <= 0;
	sync_vga_en_inn <= '0';

else
	if rising_edge(clk_video) then
		if cnt_vga_en = '1' and axis_start ='1' then					
				sync_vga_en_inn <= '1';
				if cnt_h_sync_vga_inn = 857 then
					cnt_h_sync_vga_inn <= 0;
					if cnt_v_sync_vga_inn = 524 then
						cnt_v_sync_vga_inn <= 0;
						--black_vga_en <= '0';
					else
						cnt_v_sync_vga_inn <= cnt_v_sync_vga_inn + 1;
						--black_vga_en <= not black_vga_en;
					end if;
				else
					cnt_h_sync_vga_inn <= cnt_h_sync_vga_inn + 1;
				end if;
			
		end if;
	end if;
end if;
end process;

--VGA-Sync---------------------------------------------------------------------------------------------------
process(rst_system, clk_video)
begin
if rst_system = '0' then
	h_sync_vga <= '1';
	v_sync_vga <= '1';
	
	h_blank_vga <= '1';
    v_blank_vga <= '1';
else
	if rising_edge(clk_video) then
		if (cnt_vga_en = '1' and sync_vga_en_inn = '1') then
			if (cnt_h_sync_vga_inn >= 736 and cnt_h_sync_vga_inn < 798)then --720
				h_sync_vga <= '1';
			else
				h_sync_vga <= '0';
			end if;
			
			if (cnt_v_sync_vga_inn >= 489 and cnt_v_sync_vga_inn < 495)then --480
				v_sync_vga <= '1';
			else
				v_sync_vga <= '0';
			end if;
			
			if (cnt_h_sync_vga_inn >= 0 and cnt_h_sync_vga_inn < 720)then --720
                h_blank_vga <= '0';
            else
                h_blank_vga <= '1';
            end if;
            
            if (cnt_v_sync_vga_inn >= 0 and cnt_v_sync_vga_inn < 480)then --480
                v_blank_vga <= '0';
            else
                v_blank_vga <= '1';
            end if;
		else
			h_sync_vga <= '1';
			v_sync_vga <= '1';
			
			h_blank_vga <= '1';
			v_blank_vga <= '1';
		end if;
	end if;
end if;
end process;
--VGA-Sync---------------------------------------------------------------------------------------------------


end Behavioral;

