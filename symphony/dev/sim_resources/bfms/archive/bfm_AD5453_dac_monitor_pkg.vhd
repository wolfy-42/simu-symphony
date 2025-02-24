------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_ad5453_dac_monitor_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Sept 15, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for bfm_ad5453_dac_monitor
--    - this is an input only device...no readback hence no turnaround
--    - provides registered SPI transaction compliance
--    - sdo port echos previous recieved frame (or null on first access after reset)
--
-- Included Function/procedure Calls:
--    - <none>
--
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;

package bfm_ad5453_dac_monitor_pkg is
   --=========== Package constants =============
      
   --=========== Procedure headers =============

   --=========== BFM SPI Slave component =============
   component bfm_ad5453_dac_monitor is
      generic ( INST_NAME_STRING    : string ;
                CS_ACT_LVL       : std_logic ;  -- Active polarity of chipselect input
                NUM_DATA_BITS    : integer  -- # data bits
         );
      port (
         i_sclk  : in std_logic ;
         i_cs    : in std_logic ;
         i_sdi : in std_logic;
         -- testbench interfaces
         i_rst  : in std_logic;                             -- board-level/power-on reset input (affects return value)
         o_evnt : out std_logic        := '0';              -- irq flag indicating transaction detected
         o_data : out std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0')   -- data portion detected
      );
   end component;    
   
end bfm_ad5453_dac_monitor_pkg;

--==========================================PACKAGE BODY==========================================
-- package body bfm_ad5453_dac_monitor_pkg is
   
-- end bfm_ad5453_dac_monitor_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
-- use work.global_signal_pkg.all;
use work.bfm_ad5453_dac_monitor_pkg.all;

entity bfm_ad5453_dac_monitor is
   generic ( INST_NAME_STRING    : string := "bfm_ad5453_dac_monitor";
             CS_ACT_LVL       : std_logic := '0';  -- Active polarity of chipselect input
             NUM_DATA_BITS    : integer := 16  -- # data bits
      );
   port (
      i_sclk  : in std_logic ;
      i_cs    : in std_logic ;
      i_sdi : in std_logic;
      -- testbench interfaces
      i_rst  : in std_logic;        -- board-level/power-on reset input (affects return value)
      o_evnt : out std_logic        := '0';              -- irq flag indicating transaction detected
      o_data : out std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0')   -- data portion detected
   );
end bfm_ad5453_dac_monitor;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_ad5453_dac_monitor is
   -- Local Constants 
   constant FRAME_CNT   : integer := NUM_DATA_BITS; -- # bits for full frame
   
   -- INTERNAL SIGNALS
   signal data_shft : std_logic_vector(NUM_DATA_BITS-1 downto 0) := (others => '0');   -- data portion detected
   signal raw_frame_shft_in : std_logic_vector(FRAME_CNT-1 downto 0) := (others => '0');   -- current frame being recieved
   signal raw_frame_reg : std_logic_vector(FRAME_CNT-1 downto 0) := (others => '0');   -- buffer for previous frame recieved
   signal frame_cntr     : integer := 0;
   
begin

   -------------------------------------------------------
   -- RAW capture for replay
   process (i_sclk, i_cs)
   begin
      if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         raw_frame_shft_in   <= (others => '0');
      elsif (i_sclk'event and i_sclk = '0') then     -- posedge output/ negedge latch
         raw_frame_shft_in <= raw_frame_shft_in(raw_frame_shft_in'high-1 downto 0) & i_sdi;    -- left shift in values (MSbit rx'ed first)
      end if;
   end process;

   -------------------------------------------------------
   -- Latch Previous frame raw capture 
   --  NOTE: reset by i_rst input, Active High
   --        CLOCKED by chipselect *DE*assertion
   process (i_cs, i_rst)
   begin
      if (i_rst = '1') then       -- reset SM if no spi_slave_A chipselect is active
         raw_frame_reg   <= (others => '0');
      elsif (i_cs'event and i_cs = not CS_ACT_LVL) then     -- clock process on chipselect -DE-assertion
         raw_frame_reg   <= raw_frame_shft_in;  -- latch shifted data before cleared in shift process
      end if;
   end process;

   o_data <= raw_frame_reg;   -- map value to output port
   
   -------------------------------------------------------
   -- Frame length counter
   process (i_sclk, i_cs)
   begin
      if (i_cs /= CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
         frame_cntr   <= 0;
      elsif (i_sclk'event and i_sclk = '1') then     -- posedge capture
         frame_cntr <= frame_cntr + 1; 
      end if;
   end process;
   
   -------------------------------------------------------
   -- verify frame length 
   process (i_cs)
   begin
      if (i_cs'event and  i_cs = not CS_ACT_LVL) then       -- Chipselect deasserted?
         if (frame_cntr > 0 and frame_cntr < FRAME_CNT) then  -- check for undersized (but ignore initial reset state)
            printError(INST_NAME_STRING, ("undersized frame: too few sclk, rcvd=" &  str(frame_cntr)));
         end if;
         if (frame_cntr > FRAME_CNT) then
            printError(INST_NAME_STRING, ("oversized frame: too many sclk, rcvd=" & str(frame_cntr)));
         end if;
      end if;
   end process;
   
   o_evnt <= '1' when (frame_cntr = FRAME_CNT) else '0';
   
end behave;
