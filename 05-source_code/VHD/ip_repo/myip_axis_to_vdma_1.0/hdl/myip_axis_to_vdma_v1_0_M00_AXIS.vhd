library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.all;

entity myip_axis_to_vdma_v1_0_M00_AXIS is
	generic (
		-- Users to add parameters here

		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXIS address bus. The slave accepts the read and write addresses of width C_M_AXIS_TDATA_WIDTH.
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32;
		-- Start count is the number of clock cycles the master will wait before initiating/issuing any transaction.
--		C_M_START_COUNT	: integer	:= 32;
		FIFO_DEPTH      : integer	:= 640
--		VIDEO_HSYNC_COUNT : integer := 640;
--        VIDEO_VSYNC_COUNT : integer := 480
	);
	port (
		-- Users to add ports here
		clk_video  : IN  std_logic;
--           reset_active_low : IN  std_logic;
        data_in_en_flag_active_high : in std_logic;
         h_blank_vga : in  std_logic;
         v_blank_vga : in  std_logic;
        video_data_in : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- User ports ends
		-- Do not modify the ports beyond this line

--        M_AXIS_TUSER    : out std_logic; --for s2mm tuser mode set used        
----        M_AXIS_FSYNC    : out std_logic; 
        
		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- 
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic
	);
end myip_axis_to_vdma_v1_0_M00_AXIS;

architecture implementation of myip_axis_to_vdma_v1_0_M00_AXIS is
	-- Total number of output data                                              
	constant NUMBER_OF_OUTPUT_WORDS : integer := FIFO_DEPTH;--VIDEO_HSYNC_COUNT;--640;                                   
	
	 -- function called clogb2 that returns an integer which has the   
	 -- value of the ceiling of the log base 2.                              
--	function clogb2 (bit_depth : integer) return integer is                  
--	 	variable depth  : integer := bit_depth;                               
--	 	variable count  : integer := 1;                                       
--	 begin                                                                   
--	 	 for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
--	      if (bit_depth <= 2) then                                           
--	        count := 1;                                                      
--	      else                                                               
--	        if(depth <= 1) then                                              
--	 	       count := count;                                                
--	 	     else                                                             
--	 	       depth := depth / 2;                                            
--	          count := count + 1;                                            
--	 	     end if;                                                          
--	 	   end if;                                                            
--	   end loop;                                                             
--	   return(count);        	                                              
--	 end;                                                                    

--	 -- WAIT_COUNT_BITS is the width of the wait counter.                       
--	 constant  WAIT_COUNT_BITS  : integer := clogb2(C_M_START_COUNT-1);               
	                                                                                  
--	-- In this example, Depth of FIFO is determined by the greater of                 
--	-- the number of input words and output words.                                    
--	constant depth : integer := NUMBER_OF_OUTPUT_WORDS;                               
	                                                                                  
--	-- bit_num gives the minimum number of bits needed to address 'depth' size of FIFO
--	constant bit_num : integer := clogb2(depth);                                      
	                                                                                  
	-- Define the states of state machine                                             
	-- The control state machine oversees the writing of input streaming data to the FIFO,
	-- and outputs the streaming data from the FIFO                                   
	type state is ( IDLE2,        -- This is the initial/idle state                    
	                INIT_COUNTER,  -- This state initializes the counter, once        
	                                -- the counter reaches C_M_START_COUNT count,     
	                                -- the state machine changes state to SEND_STREAM  
	                SEND_STREAM,
	                CHANGE_FIFO,
	                IDLE,
	                INIT_COUNTER2,
	                SEND_STREAM2,
	                CHANGE_FIFO2
	                
	                );  -- In this state the                               
	                             -- stream data is output through M_AXIS_TDATA        
	-- State variable                                                                 
	signal  mst_exec_state : state := IDLE2; -- start state                                                  
	-- Example design FIFO read pointer                                               
	signal read_pointer : integer range 0 to NUMBER_OF_OUTPUT_WORDS := 0;--bit_num-1;                               

	-- AXI Stream internal signals
	--wait counter. The master waits for the user defined number of clock cycles before initiating a transfer.
--	signal count	: std_logic_vector(WAIT_COUNT_BITS-1 downto 0);
	--streaming data valid
	signal axis_tvalid	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--Last of the streaming data 
	signal axis_tlast	: std_logic;
	--Last of the streaming data delayed by one clock cycle
	signal axis_tlast_delay	: std_logic;
	--FIFO implementation signals
	signal stream_data_out	: std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal tx_en	: std_logic;
	--The master has issued all the streaming data stored in FIFO
	signal tx_done	: std_logic;

    signal M_AXIS_TUSER_flag : std_logic_vector(2 downto 0) := (others=>'0');

	-----AXIs FIFO------------------------------------------------------------
     constant array_range : integer := NUMBER_OF_OUTPUT_WORDS;
     type fifo_arrays is array (0 to array_range-1) of std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0); --0~7 (31 downt 0)
     type fifo_arrayss is array (0 to 1) of fifo_arrays; -- two fifo buffer to can change
     signal fifo_array: fifo_arrayss;
     
     --FIFO Valid data size-----
--     type fifo_valid_cnts is array (0 to 1) of integer range 0 to array_range-1 ;
--     signal fifo_valid_cnt:fifo_valid_cnts;
     ----------------------------
     
     signal fi_index : integer range 0 to array_range-1 := 0;   
--     signal fo_index : integer range 0 to array_range-1 := 0;
--     signal fifo_full_flag : std_logic:='0'; -- when fifo full that to HIGH
     
      signal video_data_out_buf : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
      
      signal data_in_en_flag : std_logic:='0'; --for control frame send data at start
      --------------------------------------------------------------------------
      	-- FIFO write pointer
      signal write_pointer : integer range 0 to array_range-1 := 0; --bit_num-1 ;
      signal fifo_num_select :  integer range 0 to 1 := 0;
      
begin
	-- I/O Connections assignments

	M_AXIS_TVALID	<= axis_tvalid_delay;
	M_AXIS_TDATA	<= stream_data_out;
	M_AXIS_TLAST	<= axis_tlast_delay;
	M_AXIS_TSTRB	<= (others => '1');

    ------video in----------------------------------------------------------------------
    process(clk_video)--27Mhz
    begin
   
        if M_AXIS_ARESETN = '0' then
            fi_index <= 0;
            fifo_num_select <= 0;
            data_in_en_flag <= '0';
            for i in 0 to 1 loop
                for j in 0 to array_range-1 loop
                    fifo_array(i)(j)<= conv_std_logic_vector(i+j*array_range,C_M_AXIS_TDATA_WIDTH);
                end loop;
            end loop;

        elsif (rising_edge (clk_video)) then
        
           if data_in_en_flag_active_high = '1' and (h_blank_vga='1') and (v_blank_vga='1') then--for control frame send data at start
                data_in_en_flag <= '1';
           end if;
           
           if data_in_en_flag='1' and (h_blank_vga='0') and (v_blank_vga='0') then
               
               if fifo_num_select = 1 then
                   fifo_array(0)(fi_index) <= video_data_in;
               else
                    fifo_array(1)(fi_index) <= video_data_in;
               end if;
               
               if fi_index = array_range-1 then
                   fi_index <= 0;
                   if fifo_num_select = 1 then fifo_num_select <= 0; else fifo_num_select <= 1; end if;
               else
                   fi_index <= fi_index + 1;
               end if;
           end if;
        end if;
    end process;



	-- Control state machine implementation                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      mst_exec_state      <= IDLE2;      -- start state                                                      
--	      count <= (others => '0');  

         ---init vdma in one times------
            M_AXIS_TUSER_flag <=  (others=>'0');
--            M_AXIS_TUSER <= '0';  
         ------------------------------
                                                                     
	    else                                                                                    
	      case (mst_exec_state) is                                                              
	        when IDLE     =>                                                                    
	          -- The slave starts accepting tdata when                                          
	          -- there tvalid is asserted to mark the                                           
	          -- presence of valid streaming data                                               
	          --if (count = "0")then                                                            
	            mst_exec_state <= SEND_STREAM;--INIT_COUNTER;                                                 
	          --else                                                                              
	          --  mst_exec_state <= IDLE;                                                         
	          --end if;                                                                                  
	                                                           
--	        when INIT_COUNTER =>--## only active one times ##                                                            
--	            -- This state is responsible to wait for user defined C_M_START_COUNT           
--	            -- number of clock cycles.                                                      
----	            if ( count = NUMBER_OF_OUTPUT_WORDS-1 ) then
--	            if ( count = std_logic_vector(to_unsigned((C_M_START_COUNT - 1), WAIT_COUNT_BITS))) then
--	              mst_exec_state  <= SEND_STREAM;    
                                        
--	            else --if tx_en='1' then                                                                            
--	              count <= std_logic_vector (unsigned(count) + 1);                              
--	              mst_exec_state  <= INIT_COUNTER;                                              
--	            end if;                                                                         
	                                                                                            
	        when SEND_STREAM  =>                                                                
	          -- The example design streaming master functionality starts                       
	          -- when the master drives output tdata from the FIFO and the slave                
	          -- has finished storing the S_AXIS_TDATA                                          
	          if (tx_done = '1') then                                                           
	            mst_exec_state <= CHANGE_FIFO;                                                         
	          else                                                                              
	            mst_exec_state <= SEND_STREAM;                                                  
	          end if; 
	                                                                                    
	        when CHANGE_FIFO=>
                 if fifo_num_select = 1 then
                     mst_exec_state <= IDLE2;
                  else
                     mst_exec_state <= CHANGE_FIFO;
                 end if;
	        
--	            if data_in_en_flag='1' and (h_blank_vga='1') and (v_blank_vga='1') then
--                     M_AXIS_TUSER_flag <=(others=>'0');
--                end if;
                
	        when IDLE2     =>                                                                    

            
----                if data_in_en_flag='1' and (h_blank_vga='1') and (v_blank_vga='1') then
------                     M_AXIS_FSYNC_flag <= '0';
----                     M_AXIS_TUSER_flag <=(others=>'0');
--                if  data_in_en_flag='1' and M_AXIS_TUSER_flag /= "111" and fifo_num_select = 1 then
--                     M_AXIS_TUSER <= '1'; -- just one pulse on one clock ##maybe need one pulse?
--                     M_AXIS_TUSER_flag <= M_AXIS_TUSER_flag +1;   
                       
--                elsif M_AXIS_TUSER_flag = "111" then     
--                     M_AXIS_TUSER <= '0'; -- just one pulse on one clock  ##maybe need one pulse?
--                     mst_exec_state <= SEND_STREAM2;--INIT_COUNTER2;    
--                end if;                
                
                if  data_in_en_flag='1' and fifo_num_select = 1 then                                                                                     
                        mst_exec_state <= SEND_STREAM2;
                end if;       
                                                                                                       
--          when INIT_COUNTER2 =>                                                              
--              -- This state is responsible to wait for user defined C_M_START_COUNT           
--              -- number of clock cycles.                                                      
----              if ( count = NUMBER_OF_OUTPUT_WORDS-1 ) then
--              if ( count = std_logic_vector(to_unsigned((C_M_START_COUNT - 1), WAIT_COUNT_BITS))) then
--                mst_exec_state  <= SEND_STREAM2;    
--                count <= (others=>'0');                                                 
--              else --if tx_en='1' then                                                                            
--                count <= std_logic_vector (unsigned(count) + 1);                              
--                mst_exec_state  <= INIT_COUNTER2;                                              
--              end if;                                                                         
                                                                                              
          when SEND_STREAM2  =>                                                                
            -- The example design streaming master functionality starts                       
            -- when the master drives output tdata from the FIFO and the slave                
            -- has finished storing the S_AXIS_TDATA                                          
            if (tx_done = '1') then                                                           
              mst_exec_state <= CHANGE_FIFO2;                                                         
            else                                                                              
              mst_exec_state <= SEND_STREAM2;                                                  
            end if;      
         when CHANGE_FIFO2=>
             if fifo_num_select = 0 then
                 mst_exec_state <= IDLE;
              else
                 mst_exec_state <= CHANGE_FIFO2;
             end if;                                                                                    
	        when others    =>                                                                   
	          mst_exec_state <= IDLE;                                                           
	                                                                                            
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                


	--tvalid generation
	--axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	--number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	axis_tvalid <= '1' when (((mst_exec_state = SEND_STREAM or mst_exec_state = SEND_STREAM2) and (read_pointer < NUMBER_OF_OUTPUT_WORDS))) else '0'; 
	                                                          
	-- AXI tlast generation                                                                        
	-- axis_tlast is asserted number of output streaming data is NUMBER_OF_OUTPUT_WORDS-1          
	-- (0 to NUMBER_OF_OUTPUT_WORDS-1)                                                             
	axis_tlast <= '1' when (read_pointer = NUMBER_OF_OUTPUT_WORDS-1) else '0';                     
	                                                                                               
	-- Delay the axis_tvalid and axis_tlast signal by one clock cycle                              
	-- to match the latency of M_AXIS_TDATA                                                        
	process(M_AXIS_ACLK)                                                                           
	begin                                                                                          
	  if (rising_edge (M_AXIS_ACLK)) then                                                          
	    if(M_AXIS_ARESETN = '0') then                                                              
	      axis_tvalid_delay <= '0';                                                                
	      axis_tlast_delay <= '0';                                                                 
	    else                                                                                       
	      axis_tvalid_delay <= axis_tvalid;                                                        
	      axis_tlast_delay <= axis_tlast;                                                          
	    end if;                                                                                    
	  end if;                                                                                      
	end process;                                                                                   


	--read_pointer pointer

	process(M_AXIS_ACLK)                                                       
	begin                                                                            
	  if (rising_edge (M_AXIS_ACLK)) then                                            
	    if(M_AXIS_ARESETN = '0') then                                                
	      read_pointer <= 0;                                                         
	      tx_done  <= '0';                                                           
	    else     
	       if (read_pointer = NUMBER_OF_OUTPUT_WORDS) then                         
                -- tx_done is asserted when NUMBER_OF_OUTPUT_WORDS numbers of streaming data
                -- has been out.
                read_pointer <= 0;                                                              
                tx_done <= '1';  --##only one clock to HIGH when FIFO full
                                                                                        
	      else --if (read_pointer <= NUMBER_OF_OUTPUT_WORDS-1) then                         
                if (tx_en = '1') then                                                    
                  -- read pointer is incremented after every read from the FIFO          
                  -- when FIFO read signal is enabled.                                   
                  read_pointer <= read_pointer + 1;                                                                         
                end if;       
                   
                tx_done <= '0';   
                                                                                                          
	      end  if;                                                                   
	    end  if;                                                                     
	  end  if;                                                                       
	end process;                                                                     


	--FIFO read enable generation 

	tx_en <= M_AXIS_TREADY and axis_tvalid;                                   
	                                                                                
	-- FIFO Implementation                                                          
	                                                                                
	-- Streaming output data is read from FIFO                                      
	  process(M_AXIS_ACLK)                                                          
--	  variable  sig_one : integer := 1;                                             
	  begin                                                                         
	    if (rising_edge (M_AXIS_ACLK)) then  
	                                        
	      if(M_AXIS_ARESETN = '0') then                                             
	    	stream_data_out <= (others=>'0');--std_logic_vector(to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));  
	      elsif (tx_en = '1') then -- && M_AXIS_TSTRB(byte_index)                   
            stream_data_out <= fifo_array(fifo_num_select)(read_pointer);
--	        stream_data_out <= std_logic_vector( to_unsigned(read_pointer,C_M_AXIS_TDATA_WIDTH) + to_unsigned(sig_one,C_M_AXIS_TDATA_WIDTH));
	      end if;                                                                   
	     end if;                                                                    
	   end process;                                                                 


	-- Add user logic here

	-- User logic ends

end implementation;
