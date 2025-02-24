-------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_ad7942_pkg_v2.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch 
--Created     : June 25, 2012
------------------------------------------------------------------------
--Description : Functional simulation model for ad7942 A2D converter
--    - VIO=3.3v
--    - CS Mode, 3-Wire, without Busy Indicator
--
-- Included Function Calls:
--       - <none>
-- 
-- External Constants from "global_signals_pkg" used:
--       - <none>
-- NOTES:
--    i_enable          --> used to disable BFM if desired
--
-- datasheet : http://www.analog.com/static/imported-files/data_sheets/AD7942.pdf
------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.sim_management.all;

package bfm_ad7942_pkg_v2 is
   constant BFM_NAME     : string    := "bfm_ad7942";

   --<> Timing contraints for ADC bfm_ad7942 VIO=3.3v - CS Mode 3-Wire without Busy Indicator
   constant ts_CYC      : time := 4 us; -- 5 us;
   constant ts_SSDICNV  : time := 15 ns;--30 ns;
   constant ts_HSDICNV  : time := 0 ns;
   constant ts_CONV_MIN : time := 0.5 us;--0.7 us;
   constant ts_CONV_MAX : time := 2.2 us;--3.2 us;
   constant ts_EN       : time := 18 ns;
   constant ts_HSDO     : time := 5 ns;
   constant ts_DSDO     : time := 15 ns; --24 ns;
   constant ts_SCK      : time := 15 ns;--25 ns;
   constant ts_SCKL     : time := 7 ns;-- 12 ns;
   constant ts_DIS      : time := 25 ns;

   component bfm_ad7942_v2 is
   generic (   BFM_NAME       : string := "bfm_LTC1407 ";      -- instance name for logfile message prefexing
               NUM_CONV_BITS  : integer := 14                  -- number of bits of sample resolution 
         );
      port (
         --<> Device SPI port
         i_sclk : in  std_logic ;                                        -- transfer clock
         i_conv : in  std_logic ;                                        -- conversion enable
         i_sdi  : in std_logic ;
         o_sdo  : out std_logic ;                                        -- serial out shifter (POR default low)
         --<> testbench inputs
         i_enable    : in std_logic;                                      -- testbench monitor enable control
         i_a2d_value : in std_logic_vector(NUM_CONV_BITS-1 downto 0);  -- value to output on SDO (2's complement)
         evnt_strb   : buffer std_logic := '0'                            -- flag to testbench 
      );
   end component;

end package;

--========================================================================================================= ENTITY PORTION
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_misc.all;
use IEEE.std_logic_unsigned.all;
use work.txt_util.all;
use work.sim_management.all;
use work.bfm_ad7942_pkg_v2.all;

entity bfm_ad7942_v2 is
   generic (   BFM_NAME       : string := "bfm_LTC1407 ";      -- instance name for logfile message prefexing
               NUM_CONV_BITS  : integer := 14                  -- number of bits of sample resolution 
   );
   port (
      --<> Device SPI port
      i_sclk : in  std_logic ;                                        -- transfer clock
      i_conv : in  std_logic ;                                        -- conversion enable
      i_sdi  : in std_logic ;
      o_sdo  : out std_logic ;                                        -- serial out shifter (POR default low)
      --<> testbench inputs
      i_enable    : in std_logic;                                      -- testbench monitor enable control
      i_a2d_value : in std_logic_vector(NUM_CONV_BITS-1 downto 0);  -- value to output on SDO (2's complement)
      evnt_strb   : buffer std_logic := '0'                            -- flag to testbench 
   );
end bfm_ad7942_v2;
   
architecture behavioural of bfm_ad7942_v2 is
   --<> ------------------------------------------------------------
   --<> Module local parameter/constants
   constant CONV_ACT_LVL    : std_logic := '0';               -- active level of conversion strobe start of data output  (from datasheet)
   constant FADC_FRAME_SIZE : integer := NUM_CONV_BITS ;    -- calculate # bits in a full frame
   
   --<> ------------------------------------------------------------
   --<> internal BFM variables
   signal frame_cntr :integer := 0;
   signal i : integer;     -- shift register index pointer
   signal ch0_word      : std_logic_vector(NUM_CONV_BITS-1 downto 0)  ; 
   signal sdo_frame     : std_logic_vector(FADC_FRAME_SIZE-1 downto 0)      ;
   signal sdo_buffer    : std_logic_vector(FADC_FRAME_SIZE-1 downto 0)      ;
   
begin   
   --<> ------------------------------------------------------------
   --<> OUTPUT GENERATOR
                     
   --<> ------------------------------------------------------------
   --<> build output frame (with datasheet sample delay)
   process (i_conv) 
   begin
      if (i_conv'event and i_conv = CONV_ACT_LVL) then
         ch0_word    <= i_a2d_value;       -- latch  input values for output on SPI transaction
         sdo_frame   <= ch0_word ;                    -- {NUM_VALID_DATA_BITS {1'b0}},
         if (i_enable = '1') then
            printMessage(BFM_NAME, ("Current Analog Input ==> " & hstr(ch0_word)));
         end if;
      end if;
   end process;

   --<> ------------------------------------------------------------
   --<> Perform data output on request
   process
   begin
      wait until i_conv = CONV_ACT_LVL;
      for i in FADC_FRAME_SIZE-1 downto 0 loop  -- vector index for output counts from MSbit -> LSbit  (count based from '1' for stop on zero)
         wait until (i_sclk = '1');
         -- wait for ts_EN;
            o_sdo <= sdo_frame(i);     -- assert data onto port with propagation delay 
      end loop;
   end process;
   
   --<> ------------------------------------------------------------
   --<> FRAME CHECKERS

   --<>-------------------------------------------- 
   --<> verify mode of operation is 3-wire, no Busy
   process
   begin
      wait until i_conv = CONV_ACT_LVL;          -- hold off checking until after the initial conversion cycle is started
      wait until i_sclk = '1';
      if i_sdi = '0' then
         -- assert false report "ERROR: bfm_ad7942: Detect SDI not asserted when CNV is asserted." severity failure;
         printError(BFM_NAME, "ERROR: bfm_ad7942: Detected SDI low - wrong interface mode in use" );
         wait until i_conv = not CONV_ACT_LVL;  -- limit # errors reported to one per transaction cycle
      end if;   
   end process;

   --<>-------------------------------------------- 
   --<> Frame length determination
   process
   begin
      wait until i_conv = CONV_ACT_LVL;
      loop
         if (i_enable = '0') then                 -- Enable control
            frame_cntr <= 0;                         -- reset and hold counter at zero 
            wait for 10 ns;                                    -- delay to avoid simulator lockup
         else 
            if (i_conv = CONV_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
               wait for 1 ns;                                  -- delay clear to allow previous count value to be checked below
               frame_cntr <= 0;
            else 
               frame_cntr <= frame_cntr + 1; 
            end if;
            wait until i_sclk = '1';                      -- posedge capture
         end if;
      end loop;
   end process;
   
   --<>-------------------------------------------- 
   --<> verify frame length verification by spacing of i_conv arrivial
   process
   begin
      wait until frame_cntr > 0;          -- hold off checking until after the initial franesync and measurements are started
      loop
         if (i_enable = '0') then         -- Enable control
            wait for 10 ns;               -- delay avoids simulator lockup 
         else 
            wait until i_conv = CONV_ACT_LVL;   -- wait for conversion event
            if (frame_cntr < FADC_FRAME_SIZE-1) then
               printError(BFM_NAME, ("undersized frame: recieved too few sclk pulses: " & str(frame_cntr)));
            end if;
            if (frame_cntr > FADC_FRAME_SIZE-1) then
               printError(BFM_NAME, ("oversized frame: recieved too many sclk pulses: " & str(frame_cntr)));
            end if;
         end if;
      end loop;
   end process;

   --<>-------------------------------------------- 
   --<> verify Minimum converstion time is met
   -- process
   -- variable t_mark: time;
   -- begin
      -- wait until i_conv = not CONV_ACT_LVL;          -- hold off checking until after the initial conversion cycle is started
      -- wait for ts_conv;
      -- if (i_conv'last_event < ts_conv) then
         -- printError(BFM_NAME, "i_conv signal sample duration too short for conversion cycle minimum:" &);
      -- end if;
   -- end process;
      
end behavioural;

--* -----------------------------Outline--------------------------------
--  --------------------------------*-----------------------------------
--######################################################################
-- Local Variables:
-- mode: outline-minor
-- outline-regexp: " *\/\/\\*"
-- End:
 
 -- bfm_LTC1407
   -- #( .BFM_NAME             ("bfm_LTC1407 "),
      -- .NUM_VALID_DATA_BITS  (12),
      -- .NUM_PREFIX_BITS      (2),
      -- .NUM_SUFFIX_BITS      (2)
   -- ) bfm_LTC1407_inst
   -- (
      -- .i_sclk  (),     -- transfer clock
      -- .i_conv  (),    -- conversion enable
      -- .o_sdo   (),    -- serial out shifter
      -- --testbench inputs
      -- .i_enable   (),    -- testbench monitor enable control
      -- .i_a2d_value_ch0  (),     -- [NUM_VALID_DATA_BITS-1:0]   CH0 value to output on SDO (2's complement)
      -- .i_a2d_value_ch1  ()      -- [NUM_VALID_DATA_BITS-1:0]   CH1 value to output on SDO (2's complement)
   -- ); 