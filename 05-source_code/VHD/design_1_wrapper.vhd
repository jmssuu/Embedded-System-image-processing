--Copyright 1986-2017 Xilinx, Inc. All Rights Reserved.
----------------------------------------------------------------------------------
--Tool Version: Vivado v.2017.4.1 (win64) Build 2117270 Tue Jan 30 15:32:00 MST 2018
--Date        : Tue Jun 26 23:01:55 2018
--Host        : F222-PC47-PC running 64-bit Service Pack 1  (build 7601)
--Command     : generate_target design_1_wrapper.bd
--Design      : design_1_wrapper
--Purpose     : IP block netlist
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
entity design_1_wrapper is
  port (
    AXIsToVDMA_en_0 : in STD_LOGIC;
    AXIsToVDMA_h_blank_vga_0 : in STD_LOGIC;
    AXIsToVDMA_v_blank_vga_0 : in STD_LOGIC;
    AXIsToVDMA_video_data_in_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    BRAM_ORG_addr : in STD_LOGIC_VECTOR ( 18 downto 0 );
    BRAM_ORG_clk : in STD_LOGIC;
    BRAM_ORG_din : in STD_LOGIC_VECTOR ( 7 downto 0 );
    BRAM_ORG_en : in STD_LOGIC;
    BRAM_ORG_we : in STD_LOGIC_VECTOR ( 0 to 0 );
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
    en_display_active_high_0 : in STD_LOGIC;
    leds : out STD_LOGIC_VECTOR ( 7 downto 0 );
    reset_active_low_0 : in STD_LOGIC;
    sws : in STD_LOGIC_VECTOR ( 7 downto 0 );
    vid_data_1 : out STD_LOGIC_VECTOR ( 23 downto 0 );
    vid_hsync_1 : out STD_LOGIC;
    vid_io_in_clk_0 : in STD_LOGIC;
    vid_vsync_1 : out STD_LOGIC
  );
end design_1_wrapper;

architecture STRUCTURE of design_1_wrapper is
  component design_1 is
  port (
    DDR_cas_n : inout STD_LOGIC;
    DDR_cke : inout STD_LOGIC;
    DDR_ck_n : inout STD_LOGIC;
    DDR_ck_p : inout STD_LOGIC;
    DDR_cs_n : inout STD_LOGIC;
    DDR_reset_n : inout STD_LOGIC;
    DDR_odt : inout STD_LOGIC;
    DDR_ras_n : inout STD_LOGIC;
    DDR_we_n : inout STD_LOGIC;
    DDR_ba : inout STD_LOGIC_VECTOR ( 2 downto 0 );
    DDR_addr : inout STD_LOGIC_VECTOR ( 14 downto 0 );
    DDR_dm : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dq : inout STD_LOGIC_VECTOR ( 31 downto 0 );
    DDR_dqs_n : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    DDR_dqs_p : inout STD_LOGIC_VECTOR ( 3 downto 0 );
    FIXED_IO_mio : inout STD_LOGIC_VECTOR ( 53 downto 0 );
    FIXED_IO_ddr_vrn : inout STD_LOGIC;
    FIXED_IO_ddr_vrp : inout STD_LOGIC;
    FIXED_IO_ps_srstb : inout STD_LOGIC;
    FIXED_IO_ps_clk : inout STD_LOGIC;
    FIXED_IO_ps_porb : inout STD_LOGIC;
    BRAM_ORG_addr : in STD_LOGIC_VECTOR ( 18 downto 0 );
    BRAM_ORG_clk : in STD_LOGIC;
    BRAM_ORG_din : in STD_LOGIC_VECTOR ( 7 downto 0 );
    BRAM_ORG_en : in STD_LOGIC;
    BRAM_ORG_we : in STD_LOGIC_VECTOR ( 0 to 0 );
    AXIsToVDMA_en_0 : in STD_LOGIC;
    vid_io_in_clk_0 : in STD_LOGIC;
    vid_hsync_1 : out STD_LOGIC;
    vid_vsync_1 : out STD_LOGIC;
    reset_active_low_0 : in STD_LOGIC;
    en_display_active_high_0 : in STD_LOGIC;
    AXIsToVDMA_h_blank_vga_0 : in STD_LOGIC;
    AXIsToVDMA_v_blank_vga_0 : in STD_LOGIC;
    AXIsToVDMA_video_data_in_0 : in STD_LOGIC_VECTOR ( 31 downto 0 );
    vid_data_1 : out STD_LOGIC_VECTOR ( 23 downto 0 );
    leds : out STD_LOGIC_VECTOR ( 7 downto 0 );
    sws : in STD_LOGIC_VECTOR ( 7 downto 0 )
  );
  end component design_1;
begin
design_1_i: component design_1
     port map (
      AXIsToVDMA_en_0 => AXIsToVDMA_en_0,
      AXIsToVDMA_h_blank_vga_0 => AXIsToVDMA_h_blank_vga_0,
      AXIsToVDMA_v_blank_vga_0 => AXIsToVDMA_v_blank_vga_0,
      AXIsToVDMA_video_data_in_0(31 downto 0) => AXIsToVDMA_video_data_in_0(31 downto 0),
      BRAM_ORG_addr(18 downto 0) => BRAM_ORG_addr(18 downto 0),
      BRAM_ORG_clk => BRAM_ORG_clk,
      BRAM_ORG_din(7 downto 0) => BRAM_ORG_din(7 downto 0),
      BRAM_ORG_en => BRAM_ORG_en,
      BRAM_ORG_we(0) => BRAM_ORG_we(0),
      DDR_addr(14 downto 0) => DDR_addr(14 downto 0),
      DDR_ba(2 downto 0) => DDR_ba(2 downto 0),
      DDR_cas_n => DDR_cas_n,
      DDR_ck_n => DDR_ck_n,
      DDR_ck_p => DDR_ck_p,
      DDR_cke => DDR_cke,
      DDR_cs_n => DDR_cs_n,
      DDR_dm(3 downto 0) => DDR_dm(3 downto 0),
      DDR_dq(31 downto 0) => DDR_dq(31 downto 0),
      DDR_dqs_n(3 downto 0) => DDR_dqs_n(3 downto 0),
      DDR_dqs_p(3 downto 0) => DDR_dqs_p(3 downto 0),
      DDR_odt => DDR_odt,
      DDR_ras_n => DDR_ras_n,
      DDR_reset_n => DDR_reset_n,
      DDR_we_n => DDR_we_n,
      FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
      FIXED_IO_mio(53 downto 0) => FIXED_IO_mio(53 downto 0),
      FIXED_IO_ps_clk => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb => FIXED_IO_ps_porb,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      en_display_active_high_0 => en_display_active_high_0,
      leds(7 downto 0) => leds(7 downto 0),
      reset_active_low_0 => reset_active_low_0,
      sws(7 downto 0) => sws(7 downto 0),
      vid_data_1(23 downto 0) => vid_data_1(23 downto 0),
      vid_hsync_1 => vid_hsync_1,
      vid_io_in_clk_0 => vid_io_in_clk_0,
      vid_vsync_1 => vid_vsync_1
    );
end STRUCTURE;
