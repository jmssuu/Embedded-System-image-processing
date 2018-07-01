library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.all;

entity myip_vdma_axis_mm2s_v1_0_S00_AXIS is
	generic (
		-- Users to add parameters here
        FIFO_DEPTH : integer := 720;
		-- User parameters ends
		-- Do not modify the parameters beyond this line
        
		-- AXI4Stream sink: Data Width
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- Users to add ports here
           clk_video  : IN  std_logic;
--           reset_active_low : IN  std_logic;
--           sync_vga_en_flag : in std_logic;
            h_blank_vga : in  std_logic;
            v_blank_vga : in  std_logic;
         video_data_out : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
         
           en_display_active_high : in std_logic;-- active HIGH to start buffer reciving AXI4s data
           cnt_vga_en_o : out std_logic;-- active HIGH  to ctrl start vga sync count
           
--         axis_slave_data_o : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
--         axis_tready_vga : in std_logic;
--         sync_vga_start_in : in std_logic;
--         cnt_h_sync_vga :in integer range 0 to 857;
--         cnt_v_sync_vga :in integer range 0 to 524;
--               axis_slave_valid : out std_logic;
		-- User ports ends
		-- Do not modify the ports beyond this line

		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end myip_vdma_axis_mm2s_v1_0_S00_AXIS;

architecture arch_imp of myip_vdma_axis_mm2s_v1_0_S00_AXIS is
	-- function called clogb2 that returns an integer which has the 
	-- value of the ceiling of the log base 2.
--	function clogb2 (bit_depth : integer) return integer is 
--	variable depth  : integer := bit_depth;
--	  begin
--	    if (depth = 0) then
--	      return(0);
--	    else
--	      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
--	        if(depth <= 1) then 
--	          return(clogb2);      
--	        else
--	          depth := depth / 2;
--	        end if;
--	      end loop;
--	    end if;
--	end;    

	-- Total number of input data.
	constant NUMBER_OF_INPUT_WORDS  : integer := FIFO_DEPTH;--640;--256; --###@@@ FIFO one data size ###@@@
	-- bit_num gives the minimum number of bits needed to address 'NUMBER_OF_INPUT_WORDS' size of FIFO.
--	constant bit_num  : integer := clogb2(NUMBER_OF_INPUT_WORDS-1);
	-- Define the states of state machine
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO
	type state is ( IDLE,        -- This is the initial/idle state 
	                WRITE_FIFO,
	                CHANGE_FIFO,
	                IDLE2,
	                WRITE_FIFO2,
	                CHANGE_FIFO2 
	                ); -- In this state FIFO is written with the
	                             -- input stream data S_AXIS_TDATA 
	signal axis_tready	: std_logic;
	-- State variable
	signal  mst_exec_state : state;  
	-- FIFO implementation signals
	signal  byte_index : integer;    
	-- FIFO write enable
	signal fifo_wren : std_logic;
	-- FIFO full flag
--	signal fifo_full_flag : std_logic;
--	-- FIFO write pointer
--	signal write_pointer : integer range 0 to array_range-1 := 0; --bit_num-1 ;
	-- sink has accepted all the streaming data and stored in FIFO
	signal writes_done : std_logic;

--	type BYTE_FIFO_TYPE is array (0 to (NUMBER_OF_INPUT_WORDS-1)) of std_logic_vector(((C_S_AXIS_TDATA_WIDTH/4)-1)downto 0);

	-----AXIs FIFO------------------------------------------------------------
     constant array_range : integer := NUMBER_OF_INPUT_WORDS;--256;--8;
--     constant array_range_cnv :  integer := 8;--3; -- array_range total value's  Binary size
     type fifo_arrays is array (0 to array_range-1) of std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0); --0~7 (31 downt 0)
     type fifo_arrayss is array (0 to 1) of fifo_arrays; -- two fifo buffer to can change
     signal fifo_array: fifo_arrayss;
     
     --FIFO Valid data size-----
     type fifo_valid_cnts is array (0 to 1) of integer range 0 to array_range-1 ;
     signal fifo_valid_cnt:fifo_valid_cnts;
     ----------------------------
     
--     signal fi_index : integer range 0 to array_range-1 := 0;   
     signal fo_index : integer range 0 to array_range-1 := 0;
--     signal fifo_full_flag : std_logic:='0'; -- when fifo full that to HIGH
     
      signal video_data_out_buf : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
      
      signal cnt_vga_en : std_logic:='0';
      --------------------------------------------------------------------------
      	-- FIFO write pointer
      signal write_pointer : integer range 0 to array_range-1 := 0; --bit_num-1 ;
      signal fifo_num_select :  integer range 0 to 1 := 1;--init to send fifo that have data 
      signal fifo_valid_cnt_buf : integer;
begin
	-- I/O Connections assignments
    cnt_vga_en_o <= cnt_vga_en;
	S_AXIS_TREADY	<= axis_tready;
--	S_AXIS_TREADY <= axis_tready_vga;
-- vga read fifo

process(clk_video)--27Mhz
   
begin

	if S_AXIS_ARESETN = '0' then
        fo_index <= 0;
        fifo_num_select <= 1; --init to send fifo that have data 
        fifo_valid_cnt_buf <= fifo_valid_cnt(1);
	elsif (rising_edge (clk_video)) then
	   if cnt_vga_en = '1' and (h_blank_vga='0') and (v_blank_vga='0') then-- and sync_vga_en_flag='1' then
	   
	       if fifo_num_select = 1 then
	           video_data_out <= fifo_array(0)(fo_index);
--	           fifo_valid_cnt_buf <= fifo_valid_cnt(0);
	       else
	            video_data_out <= fifo_array(1)(fo_index);
--	            fifo_valid_cnt_buf <= fifo_valid_cnt(1);
	       end if;
	       
	       if fo_index = array_range-1 then--fifo_valid_cnt_buf then --array_range-1 then
	           fo_index <= 0;
	           if fifo_num_select = 1 then fifo_num_select <= 0; fifo_valid_cnt_buf <= fifo_valid_cnt(1); else fifo_num_select <= 1;  fifo_valid_cnt_buf <= fifo_valid_cnt(0); end if;
	       else
	           fo_index <= fo_index + 1;
	       end if;
	   end if;
	end if;
end process;


	
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      -- Synchronous reset (active low)
	      mst_exec_state      <= IDLE;
	      cnt_vga_en <= '0';
	    else
	    
	      case (mst_exec_state) is
	        when IDLE => 
	          if (en_display_active_high = '1')then-- active HIGH to start buffer reciving AXI4s data
	            mst_exec_state <= WRITE_FIFO;
	          else
	            mst_exec_state <= IDLE;
	          end if;
	      
	        when WRITE_FIFO => 
	          -- When the sink has accepted all the streaming input data,
	          -- the interface swiches functionality to a streaming master
	          if (writes_done = '1') then
	            cnt_vga_en <= '1';-- active HIGH to start buffer reciving AXI4s data
	            mst_exec_state <= CHANGE_FIFO;--IDLE;
	          else
	            -- The sink accepts and stores tdata 
	            -- into FIFO
	            mst_exec_state <= WRITE_FIFO;
	          end if;
	          
	        when CHANGE_FIFO=>
	           if fifo_num_select = 1 then
	               mst_exec_state <= IDLE2;
	            else
	               mst_exec_state <= CHANGE_FIFO;
	           end if;
	           
	        when IDLE2 =>
                mst_exec_state <= WRITE_FIFO2;

	        when WRITE_FIFO2 => 
                 -- When the sink has accepted all the streaming input data,
                 -- the interface swiches functionality to a streaming master
                 if (writes_done = '1') then
                   mst_exec_state <= CHANGE_FIFO2;--IDLE;
                 else
                   -- The sink accepts and stores tdata 
                   -- into FIFO
                   mst_exec_state <= WRITE_FIFO2;
                 end if;
                 
            when CHANGE_FIFO2=>
                if fifo_num_select = 0 then
                      mst_exec_state <= IDLE;
                 else
                      mst_exec_state <= CHANGE_FIFO2;
                 end if;

	        when others => 
	          mst_exec_state <= IDLE;
	        
	      end case;
	    end if;  
	  end if;
	end process;
	-- AXI Streaming Sink 
	-- 
	-- The example design sink is always ready to accept the S_AXIS_TDATA  until
	-- the FIFO is not filled with NUMBER_OF_INPUT_WORDS number of input words.
	axis_tready <= '1' when (((mst_exec_state = WRITE_FIFO)or (mst_exec_state = WRITE_FIFO2)) and (write_pointer <= NUMBER_OF_INPUT_WORDS-1)) else '0';

	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	    if(S_AXIS_ARESETN = '0') then
	      write_pointer <= 0;
	      writes_done <= '0';
	    else
	     
	       if write_pointer <= NUMBER_OF_INPUT_WORDS-1 and S_AXIS_TLAST = '0' then
   --              if (fifo_wren = '1') then
   --                  if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
   --                      -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
   --                      -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
   --                       writes_done <= '1';
   ----                       fifo_valid_cnt(fifo_num_select) <=  write_pointer;--FIFO Valid data size
   --                       write_pointer <= 0;
   --                  else
   --                       write_pointer <= write_pointer + 1;
   --                       writes_done <= '0';
   --                  end if;
   --               end if;
                   if (fifo_wren = '1') then
                     -- write pointer is incremented after every write to the FIFO
                     -- when FIFO write signal is enabled.
                     write_pointer <= write_pointer + 1;
                     
                   end if;
                   
                   writes_done <= '0';
   --                if ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
   --                  -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
   --                  -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
   --                   write_pointer <= 0;
   --                   writes_done <= '1';
   --                end if;
             elsif ((write_pointer = NUMBER_OF_INPUT_WORDS-1) or S_AXIS_TLAST = '1') then
                     -- reads_done is asserted when NUMBER_OF_INPUT_WORDS numbers of streaming data 
                     -- has been written to the FIFO which is also marked by S_AXIS_TLAST(kept for optional usage).
                      write_pointer <= 0;
                      writes_done <= '1';
                   
             end  if;
	     
	     
	     
	    end if;
	  end if;
	end process;

	-- FIFO write enable generation
	fifo_wren <= S_AXIS_TVALID and axis_tready;

	-- FIFO Implementation
--	 FIFO_GEN: for byte_index in 0 to (C_S_AXIS_TDATA_WIDTH/8-1) generate

--	 signal stream_data_fifo : BYTE_FIFO_TYPE;
--	 begin   
	  -- Streaming input data is stored in FIFO
	  process(S_AXIS_ACLK)
	  begin
	    if (rising_edge (S_AXIS_ACLK)) then
	      if (fifo_wren = '1') then
	        fifo_array(fifo_num_select)(write_pointer) <= S_AXIS_TDATA;
--	        stream_data_fifo(write_pointer) <= S_AXIS_TDATA((byte_index*8+7) downto (byte_index*8));
	      end if;  
	    end  if;
	  end process;

--	end generate FIFO_GEN;

	-- Add user logic here
--	 process(S_AXIS_ACLK)
--         begin
--           if (rising_edge (S_AXIS_ACLK)) then
--             if (fifo_wren = '1') then
--               axis_slave_data_o <= S_AXIS_TDATA;
--             end if;  
--           end  if;
--     end process;
         
--      axis_slave_valid <=fifo_wren;
	-- User logic ends

end arch_imp;
