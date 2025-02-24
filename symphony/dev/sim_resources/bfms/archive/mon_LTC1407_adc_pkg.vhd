------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : mon_ltc1407_adc_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Sept 15, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for mon_ltc1407_adc
--    - this is an output only device.
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

package mon_ltc1407_adc_pkg is
   --=========== Package constants =============
      
   --=========== Procedure headers =============

   --=========== BFM SPI Slave component =============
   component mon_ltc1407_adc is
   generic ( INST_NAME_STRING    : string ;
             CS_ACT_LVL          : std_logic ;  -- Active polarity of chipselect input
             NUM_VALID_DATA_BITS : integer;  -- # valid data bits
             NUM_PREFIX_BITS     : integer;
             NUM_SUFFIX_BITS     : integer
   );
   port (
      i_sclk  : in std_logic ;
      i_conv  : in std_logic ;
      o_sdo   : out std_logic;  -- serial out shifter
      --<> testbench inputs
      i_enable : in std_logic;  -- testbench monitor enable control
      i_a2d_value : in integer  -- value to convert and output on SDO
   );
   end component;    
   
end mon_ltc1407_adc_pkg;

--==========================================PACKAGE BODY==========================================
-- package body mon_ltc1407_adc_pkg is
   
-- end mon_ltc1407_adc_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.mon_ltc1407_adc_pkg.all;

entity mon_ltc1407_adc is
   generic ( INST_NAME_STRING    : string := "mon_ltc1407_adc";
             CS_ACT_LVL          : std_logic := '0';  -- Active polarity of chipselect input
             NUM_VALID_DATA_BITS : integer := 12;  -- # valid data bits
             NUM_PREFIX_BITS     : integer := 2;
             NUM_SUFFIX_BITS     : integer := 2
   );
   port (
      i_sclk  : in std_logic ;
      i_conv  : in std_logic ;
      o_sdo   : out std_logic :='0';  -- serial out shifter
      --<> testbench inputs
      i_enable : in std_logic;  -- testbench monitor enable control
      i_a2d_value : in integer  -- value to convert and output on SDO
   );
end mon_ltc1407_adc;

--==========================ARCHITECTURE==========================================
architecture behave of mon_ltc1407_adc is
   --<> Local Constants 
   constant NUM_X_DATA_BITS     : integer := (14 - NUM_VALID_DATA_BITS) ;  -- # "don't care" data bits

   constant FADC_FRAME_SIZE   : integer := NUM_PREFIX_BITS 
                                    + NUM_VALID_DATA_BITS 
                                    + NUM_X_DATA_BITS  
                                    + NUM_PREFIX_BITS 
                                    + NUM_VALID_DATA_BITS 
                                    + NUM_X_DATA_BITS  
                                    + NUM_SUFFIX_BITS; -- # bits for full frame
   --<> INTERNAL SIGNALS
   signal frame_cntr     : integer := 0;
   
begin

  process 
  begin
      wait for 1 ns;
      printMessage(INST_NAME_STRING, ("info: expecting Fast_ADC frame size of : " & integer'image(FADC_FRAME_SIZE)));
      wait;  -- stop process
  end process;
  

   --<>-----------------------------------------------------
   --<> Frame length determination
   p_fadc_frm_cntr: process 
   begin
      wait until (i_conv'event and i_conv = CS_ACT_LVL); -- suspend checking until Fast ADC is enabled
      loop
         if (i_enable = '0') then  -- Enable control
            frame_cntr   <= 0;      -- reset and hold counter at zero 
            wait for 10 ns;    -- avoid simulator lockup
         else
            if (i_conv = CS_ACT_LVL) then       -- reset SM if no spi_slave_A chipselect is active
               wait for 1 ns;    -- delay clear to allow previous count value to be checked below
               frame_cntr   <= 0;
            else
               frame_cntr <= frame_cntr + 1; 
            end if;
            wait until (i_sclk'event and i_sclk = '1');     -- posedge capture
         end if;
      end loop;
   end process p_fadc_frm_cntr;
   
   --<> verify frame length verification
   p_fadc_cnt_chk: process 
   begin
      wait until (frame_cntr > 0);  -- hold off checking until after the initial franesync an measurements are started
      loop
         if (i_enable = '0') then  -- Enable control
            wait for 10 ns; -- simulator lockup prevention
         else
            wait until ((i_conv'event) and  (i_conv = CS_ACT_LVL)) ;       -- on assertion of chipselect
            if (frame_cntr < FADC_FRAME_SIZE) then
               printError(INST_NAME_STRING, ("undersized frame: recieved too few sclk pulses: " & integer'image(frame_cntr)));
            end if;
            if (frame_cntr > FADC_FRAME_SIZE) then
               printError(INST_NAME_STRING, ("oversized frame: recieved too many sclk pulses: " & integer'image(frame_cntr)));
            end if;
         end if;
      end loop;
   end process p_fadc_cnt_chk;

end behave;
