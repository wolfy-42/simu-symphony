------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_misc_drivers_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : Sept 19, 2011
------------------------------------------------------------------------
--Description : Functions and Procedures for various net/pin stimulus/drivers
--
-- Included Function Calls:
--    - Gen_Pulse()
-- 
-- External Constants from "global_signals_pkg" used:
--       - <none>
--
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;

package bfm_misc_drivers_pkg is
   --=========== Package constants =============
      
   --=========== Procedure headers =============
   --<> individual pulse generation
   procedure Gen_Pulse(  polarity: in integer;
                     duration : in time;
                     netname : in string;
                     signal out_sig : out std_logic
                  );
                  
   --=========== BFM Driver component =============
   
end bfm_misc_drivers_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_misc_drivers_pkg is

   
   --<> ==============internal package signals (proceedure <-> Monitor signals) 
   
 
   --<>----------------------------------------------------------------------
   --<> Procedure to generate a pulse of arbitary duration
   --<>----------------------------------------------------------------------
   procedure Gen_Pulse(  polarity: in integer;            -- active polarity of pulse _1=high, 0=low)
                     duration : in time;              -- width of pulse in time unit
                     netname : in string;             -- signal being driven (in quotes)
                     signal out_sig : out std_logic   -- signal being driven
                  ) is
      variable active_state: std_logic;
   begin
      printMessage ("bfm_misc_drivers_pkg", ("Gen_Pulse() - asserting " & netname ));
      if (polarity = 1) then
         active_state := '1';
      else
         active_state := '0';
      end if;
      out_sig <= active_state;
      wait for duration;
      out_sig <= not active_state;
   end procedure;
   
end bfm_misc_drivers_pkg;

--==========================ENTITY==========================================
