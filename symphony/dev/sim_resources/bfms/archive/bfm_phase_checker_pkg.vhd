------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_phase_checker_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : March 16, 2011
--Description :  bfm_phase_check Duty-cycle checker
-- - measures relative phase offset of a signal event relative to a reference event
-- 
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use ieee.math_real.all;   -- for uniform, trunc functions

package bfm_phase_checker_pkg is
   --=========== Package constants =============
   
   --=========== Procedure headers =============
   component bfm_phase_check is
      generic ( NODE_ID    : integer;     -- unique ID
                POLARITY  : std_logic ;  -- Polarity of events ('1'=Rising Edge, '0'=Falling Edge)
                PERIOD    : time;      -- Full period of PWM cycle (posedge -> posedge)
                DEV_ERROR : time;      -- acceptable deviation amount +/- 'x' ns
                TIMEOUT   : time       -- missing edge timeout duration
      );
      port (
         i_ref_event  : in std_logic;           -- input reference time event
         i_target_event : in std_logic;         -- signal event to check
         i_offset : in time;                 -- expected phase offset from reference input
         i_enable : in std_logic;                 -- testbench checker enable control (1=perform checks, 0=ignore events)
         o_fault : out std_logic := '0'   -- <optional> fault flag indication for testbench logic
      );

   end component bfm_phase_check;
   
end bfm_phase_checker_pkg;

--==========================================PACKAGE BODY==========================================
-- package body bfm_phase_checker_pkg is
-- end bfm_phase_checker_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.bfm_phase_checker_pkg.all;

entity bfm_phase_check is
      generic ( NODE_ID    : integer;     -- unique ID
                POLARITY  : std_logic ;  -- Polarity of events ('1'=Rising Edge, '0'=Falling Edge)
                PERIOD    : time;      -- Full period of PWM cycle (posedge -> posedge)
                DEV_ERROR : time;      -- acceptable deviation amount +/- 'x' ns
                TIMEOUT   : time       -- missing edge timeout duration
      );
      port (
         i_ref_event  : in std_logic;           -- input reference time event
         i_target_event : in std_logic;         -- signal event to check
         i_offset : in time;                 -- expected phase offset from reference input
         i_enable : in std_logic;                 -- testbench checker enable control (1=perform checks, 0=ignore events)
         o_fault : out std_logic := '0'   -- <optional> fault flag indication for testbench logic
      );
end bfm_phase_check;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_phase_check is

--<> INTERNAL SIGNALS
      shared variable v_delta_t  : time := 0 ns ;
      shared variable v_ref_t    : time := 0 ns ;
      -- shared variable v_check_en : std_logic := '0' ;
      signal check_en : std_logic := '0' ;
      signal target_cntr  : integer := 0;   
      signal lower_lim  : time;   
      signal upper_lim  : time;
      signal r_fault, t_fault : std_logic := '0';  -- fault flags

begin
   
   lower_lim <= (i_offset - DEV_ERROR);    -- calculate lower phase offset limit 
   upper_lim <= (i_offset + DEV_ERROR);    -- calculate upper phase offset limit

   o_fault <= r_fault or t_fault;      -- merge internal error flags to single output flag
   
   -----------------------------------
   -- reference event monitor
   p_ref_event_mon: process
   begin
      if (i_enable = '0') then        -- testbench/case checker enable control
         r_fault <= '0';                  -- clear fault on function halt
         check_en <= '0';                  -- disable checker
         wait until (i_enable = '1');
      else
         wait until (i_ref_event'event and i_ref_event = POLARITY) for TIMEOUT; -- wait for start of cycle (rising edge) with timeout
         if (i_ref_event /= POLARITY) then
            printError (("bfm_phase_check_" & str(NODE_ID)), "missing Reference event before timeout elapsed");
            r_fault <= '1', '0' after 1 ns;   -- set output flag to indicate fault condition to testbench (auto clearing)
         else
            v_ref_t := now;                      -- record simulation time when reference trigger occured
            check_en <= '1';                   -- commence checking 
         end if;
      end if;
   end process;
      
   -----------------------------------
   -- target event monitor and fault processing
   p_target_event_chk: process
   begin
      if (check_en = '0') then        -- testbench/case checker enable control
         t_fault <= '0';                  -- clear fault on function halt
         target_cntr <= 0;
         wait until (check_en = '1');
      else
         -- wait until (i_ref_event'event and i_ref_event = POLARITY); -- wait for start of cycle ... avoids simulation race loops on faults
         wait until (i_target_event'event and i_target_event = POLARITY) for TIMEOUT;  -- otherwise wait for target edge 
         target_cntr <= target_cntr +1;   -- debug event counter
         if (i_target_event /= POLARITY) then   -- timeout event check
            printError ("bfm_phase_check", "missing Target event before timeout elapsed");
            t_fault <= '1', '0' after 1 ns;   -- set output flag to indicate fault condition to testbench (auto clearing)
         else
            v_delta_t := now - v_ref_t;  -- find current delay between rising edges of ref and target
            if (v_delta_t = PERIOD) then 
               v_delta_t := 0 ns;   -- reference and target edges are aligned (no offset)...correct delta time to reflect
            end if;
            -- if (v_delta_t > DEV_ERROR) then -- we should see an offset (avoids math errors when close to co-incident
               if ((v_delta_t < lower_lim) or (v_delta_t > upper_lim)) then  -- check if phase +- MARGIN is out of bounds 
                  printError (("bfm_phase_check_" & str(NODE_ID)), "target event outside stipulated phase offset");
                  t_fault <= '1', '0' after 1 ns;   -- set output flag to indicate fault condition to testbench (auto clearing)
               end if;  -- otherwise we are good :-)
            -- else  -- otherwise we are close to co-incident
                  -- printWarning (("bfm_phase_check_" & str(NODE_ID)), "target event near simultaneous to reference edge");
            -- end if;
         end if;
      end if;
   end process;
   
end behave;
