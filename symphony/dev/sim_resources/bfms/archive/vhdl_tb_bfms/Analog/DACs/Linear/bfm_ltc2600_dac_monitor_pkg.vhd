------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_ltc2600_dac_monitor_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Sept 15, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for bfm_ltc2600_dac_monitor
--    - this is an input only device...no readback hence no turnaround
--    - provides registered SPI transaction compliance
--    - sdo port echos previous recieved frame (or null on first access after reset)
--
-- Included Function/procedure Calls:
--    - <none>
-- 
------------------------------------------------------------------------
-- $Author: Arnold.Balisch $     $Revision: 1.2 $    $Date: 2012-06-22 09:23:04 $
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;

package bfm_ltc2600_dac_monitor_pkg is
   --=========== Package constants =============
      
   --=========== Procedure headers =============

   --=========== BFM SPI Slave component =============
   component bfm_ltc2600_dac_monitor is
      generic ( INST_NAME_STRING    : string ;
                CS_ACT_LVL      : std_logic;  -- Active polarity of chipselect input
                MODE             : integer;  -- 
                NUM_PAD_BITS     : integer;  -- # read/write input command bits
                NUM_CMD_BITS     : integer;  -- # read/write input command bits
                NUM_ADDR_BITS    : integer;  -- # address bits in header
                NUM_DATA_BITS    : integer  -- # data bits
         );
      port (
         i_sclk  : in std_logic ;
         i_cs    : in std_logic ;
         i_sdi : in std_logic;
         o_sdo : out std_logic;  
         -- testbench interfaces
         i_rst  : in std_logic;                                   -- board-level/power-on reset input (affects return value)
         o_evnt : out std_logic;                                  -- <<RFU>> irq flag indicating transaction detected
         o_cmd  : out std_logic_vector(NUM_CMD_BITS-1 downto 0);  -- command portion of header detected
         o_addr : out std_logic_vector(NUM_ADDR_BITS-1 downto 0); -- address portion of header detected
         o_data : out std_logic_vector(NUM_DATA_BITS-1 downto 0)  -- data portion detected
      );
   end component;    
   
end bfm_ltc2600_dac_monitor_pkg;

--==========================================PACKAGE BODY==========================================
-- package body bfm_ltc2600_dac_monitor_pkg is
   
-- end bfm_ltc2600_dac_monitor_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
-- use work.global_signal_pkg.all;
use work.bfm_ltc2600_dac_monitor_pkg.all;

entity bfm_ltc2600_dac_monitor is
   generic ( INST_NAME_STRING    : string := "bfm_ltc2600_dac_monitor";
             CS_ACT_LVL      : std_logic := '0';  -- Active polarity of chipselect input
             MODE             : integer := 1;  -- 
             NUM_PAD_BITS     : integer := 0;  -- # read/write input command bits
             NUM_CMD_BITS     : integer := 4;  -- # read/write input command bits
             NUM_ADDR_BITS    : integer := 4;  -- # address bits in header
             NUM_DATA_BITS    : integer := 16  -- # data bits
      );
   port (
      i_sclk  : in std_logic;
      i_cs    : in std_logic;
      i_sdi : in std_logic;
      o_sdo : out std_logic;  
      -- testbench interfaces
      i_rst  : in std_logic;                             -- board-level/power-on reset input (affects return value)
      o_evnt : out std_logic        := '0';              -- <<RFU>> irq flag indicating transaction completed
      o_cmd  : out std_logic_vector(NUM_CMD_BITS-1 downto 0) := (others => '0');  -- command portion of header detected
      o_addr : out std_logic_vector(NUM_ADDR_BITS-1 downto 0) := (others => '0');  -- address portion of header detected
      o_data : out std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0')   -- data portion detected
   );
end bfm_ltc2600_dac_monitor;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_ltc2600_dac_monitor is
   -- Local Constants 
   constant CMD_LOC     : integer := NUM_PAD_BITS;       -- # bits before start of command field
   constant ADDR_LOC    : integer := NUM_PAD_BITS + NUM_CMD_BITS; -- # bits before start of addressing field
   constant PAYLOAD_LOC : integer := NUM_PAD_BITS + NUM_CMD_BITS + NUM_ADDR_BITS; --  -- # bits in the payload (may vary from generic)
   constant PAYLOAD_CNT : integer := NUM_DATA_BITS;         -- # bits in the payload (may vary from generic)
   constant FRAME_CNT   : integer := NUM_PAD_BITS + NUM_CMD_BITS + NUM_ADDR_BITS + NUM_DATA_BITS; -- # bits for full frame

   -- constant SDIO_OUT_ENABLE   : std_logic := '1';  -- condition for bi-directional port's OUTPUT_ENABLE assertion
   
   -- INTERNAL SIGNALS
   signal cmd_shft            : std_logic_vector(NUM_CMD_BITS-1 downto 0) := (others => '0');  -- command portion of header detected
   signal addr_shft           : std_logic_vector(NUM_ADDR_BITS-1 downto 0) := (others => '0');  -- address portion of header detected
   signal data_shft           : std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0');   -- data portion detected
   signal raw_frame_shft_in   : std_logic_vector(FRAME_CNT-1 downto 0) := (others => '0');   -- current frame being recieved
   signal raw_frame_shft_out  : std_logic_vector(FRAME_CNT-1 downto 0) := (others => '0');   -- current frame being recieved
   signal raw_frame_reg       : std_logic_vector(FRAME_CNT-1 downto 0) := (others => '0');   -- buffer for previous frame recieved

   signal int_sdio_in   : std_logic := '0';
   signal int_sdio_out  : std_logic := '0';
   signal sdio_dir      : std_logic := '0';
   
   -- signal sdo_cntr      : integer := 0;
   signal frame_cntr    : integer := 0;
   
   type t_states  is (s_START, s_CMD, s_ADDR, s_DATA);
   signal sm_state   : t_states;

   type t_rw_modes is (M_WR, M_RD);  -- Note: read vs write direction is from perspective of external Master
   signal rw_mode     : t_rw_modes := M_WR;       -- Command mode
   
begin


   -------------------------------------------------------
   -- Bus read
   p_spi_clk_drv: process (i_cs, i_sclk)
   begin
      if (i_cs /= CS_ACT_LVL) then
         -- hdr_cntr        <= 0;
         -- data_cntr      <= 0;
         frame_cntr      <= 0;   -- offset one in counting to accomadate FF setup/propagation
         rw_mode         <= M_WR;
         if (NUM_PAD_BITS > 0) then
            sm_state       <= s_START; -- prep for "don't care" prefix
         else
            sm_state       <= s_CMD; -- short burst mode
         end if;
      elsif (i_sclk'event and i_sclk = '1') then                                
         frame_cntr <= frame_cntr + 1;
         case sm_state is
            when s_START => 
               if (frame_cntr >= CMD_LOC) then  -- greatter-than used to help avoid start fault alignment issues
                  sm_state <= s_ADDR;
               end if;
            when s_CMD => 
               if (frame_cntr = ADDR_LOC-1) then
                  sm_state <= s_ADDR;
               end if;
            when s_ADDR => 
               if (frame_cntr = PAYLOAD_LOC-1) then
                  sm_state <= s_DATA;
               end if;
            when s_DATA => 
               if (frame_cntr > FRAME_CNT) then
                  printError(INST_NAME_STRING, "recieved Chipselect duration too long..too many sclk pulses");
               end if;
            when others =>
               sm_state <= s_START;    -- fault recovery
         end case;
      end if;
   end process;

   -------------------------------------------------------
   -- capture CMD frame
   process (i_sclk, i_cs)
   begin
      -- if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         -- cmd_shft   <= (others => '0');
      -- els
      if (i_sclk'event and i_sclk = '1') then     -- posedge capture
         if (sm_state = s_CMD) then
               cmd_shft <= cmd_shft(cmd_shft'high-1 downto 0) & i_sdi;    -- left shift in values (MSbit rx'ed first)
         end if;
      end if;
      if (i_cs'event and i_cs = not CS_ACT_LVL) then
         o_cmd <= cmd_shft;
      end if;
   end process;
 
   -------------------------------------------------------
   -- capture addr frame
   process (i_sclk, i_cs)
   begin
      -- if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         -- addr_shft   <= (others => '0');
      -- els
      if (i_sclk'event and i_sclk = '1') then     -- posedge capture
         if (sm_state = s_ADDR) then
               addr_shft <= addr_shft(addr_shft'high-1 downto 0) & i_sdi;    -- left shift in values (MSbit rx'ed first)
         end if;
      end if;
      if (i_cs'event and i_cs = not CS_ACT_LVL) then
         o_addr <= addr_shft;
      end if;
   end process;

   -------------------------------------------------------
   -- capture data frame
   process (i_sclk, i_cs)
   begin
      -- if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         -- data_shft   <= (others => '0');
         -- o_data <= data_shft; -- output latest value
      -- els
      if (i_sclk'event and i_sclk = '1') then     -- posedge capture
         if (sm_state = s_DATA) then
            data_shft <= data_shft(data_shft'high-1 downto 0) & i_sdi;    -- left shift in values (MSbit rx'ed first)
         end if;
      end if;
      if (i_cs'event and i_cs = not CS_ACT_LVL) then
         o_data <= data_shft;
      end if;
   end process;


   -- -------------------------------------------------------
   -- -- RAW capture for replay
   -- process (i_sclk, i_cs)
   -- begin
      -- if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         -- raw_frame_shft_in   <= (others => '0');
      -- elsif (i_sclk'event and i_sclk = '1') then     -- negative edge output
         -- if (sm_state = s_DATA) then
               -- raw_frame_shft_in <= raw_frame_shft_in(raw_frame_shft_in'high-1 downto 0) & i_sdi;    -- left shift in values (MSbit rx'ed first)
         -- end if;
      -- end if;
   -- end process;

   -- -------------------------------------------------------
   -- -- Previous frame raw capture buffering (independant of processing)
   -- --  NOTE: reset by i_rst input, Active High
   -- --        CLOCKED by chipselect
   -- process (i_cs, i_rst)
   -- begin
      -- if (i_rst = '1') then       -- reset SM if no spi_slave_A chipselect is active
         -- raw_frame_reg   <= (others => '0');
      -- elsif (i_cs'event and i_cs = not CS_ACT_LVL) then     -- clock process on chipselect -DE-assertion
         -- raw_frame_reg   <= raw_frame_shft_in;
      -- end if;
   -- end process;

   -- -------------------------------------------------------
   -- -- Output previous RAW capture to port
   -- process (i_sclk, i_cs)
   -- begin
      -- if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         -- raw_frame_shft_out   <= (others => '0');
         -- sdo_cntr <= 0;
      -- elsif (i_sclk'event and i_sclk = '0') then     -- negative edge output
         -- sdo_cntr <= sdo_cntr + 1;
         -- o_sdo <= raw_frame_reg(raw_frame_reg'high - sdo_cntr);  -- output MSbit first
      -- end if;
   -- end process;
   o_sdo <= '0';  -- tie off as unused.
   
end behave;
