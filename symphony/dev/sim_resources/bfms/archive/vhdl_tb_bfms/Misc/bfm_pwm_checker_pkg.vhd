------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_pwm_checker_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch   
--Created     : March 16, 2011
--Description :  bfm_pwm_checker Duty-cycle checker
-- - measures positive duty cycle period is as expected (within Margin of error)
-- 
------------------------------------------------------------------------
-- $Author: Arnold.Balisch $     $Revision: 1.5 $    $Date: 2012-10-29 09:50:06 $
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use ieee.math_real.all;   -- for uniform, trunc functions

package bfm_pwm_checker_pkg is
   --=========== Package constants =============
   
   --=========== Procedure headers =============
   component bfm_pwm_checker is
      generic ( NODE_ID    : integer;     -- unique ID
                PERIOD_ns : integer;  -- total period of incoming PWM signal (in ns)
                LIMIT : integer;       -- total period of incoming PWM signal in terms of SPI value to register
                MARGIN : time --;   -- Margin of error of duty cycle 
      );
      port (
         i_pwm  : in std_logic;           -- From DUT PWM output port 
         i_pwm_duty : in integer;         -- duty cycle expected - raw register input (range 1 to LIMIT) 
         i_chk_enable : in std_logic;     -- testcase checker control
         o_fault : out std_logic := '0'   -- <optional> fault flag indication for testbench logic
      );
   end component bfm_pwm_checker;
   
end bfm_pwm_checker_pkg;

--==========================================PACKAGE BODY==========================================
-- package body bfm_pwm_checker_pkg is
-- end bfm_pwm_checker_pkg;

--==========================ENTITY==========================================
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;
use work.bfm_pwm_checker_pkg.all;

entity bfm_pwm_checker is
   generic ( NODE_ID    : integer;  -- unique ID
             PERIOD_ns : integer;   -- total period of incoming PWM signal (in ns)
             LIMIT   : integer;     -- upper range of duty cycle values
             MARGIN : time          -- Margin of error of duty cycle 
   );
   port (
      i_pwm  : in std_logic;           -- From DUT PWM output port 
      i_pwm_duty : in integer;         -- duty cycle expected - raw register input (range 1 to LIMIT) 
      i_chk_enable : in std_logic;     -- testcase checker control
      o_fault : out std_logic := '0'   -- <optional> fault flag indication for testbench logic
   );
end bfm_pwm_checker;

--==========================ARCHITECTURE==========================================
architecture behave of bfm_pwm_checker is

--<> INTERNAL SIGNALS
      shared variable delta_period : time := 0 ns;
      shared variable v_delta_t    : time := 0 ns;
      shared variable v_rise_t     : time := 0 ns;
      signal v_target_int  : integer;
      signal v_target_t  : time;
      signal upper_lim  : time;
      signal lower_lim  : time;
      signal ts_period : time;
      signal percent : real := 0.0;
      signal duty_fault : std_logic:='0';
      
      shared variable last_rising : time;
      shared variable current_rising : time;
      signal period_fault : std_logic:='0';
      
      
begin
   
   ts_period <= PERIOD_ns * 1 ns;   -- convert integer to time units
   percent <= real(real(i_pwm_duty) / real(LIMIT));   -- calculate expected duty-cycle limit in percentage of full period
   v_target_int <= integer(trunc(real(PERIOD_ns) * percent));  -- Calculate current duty cycle target width 
   v_target_t <= v_target_int * 1 ns;     -- convert integer to time units
   lower_lim <= (v_target_t - MARGIN);    -- 
   upper_lim <= (v_target_t + MARGIN);

   
   -----------------------------------
   -- PWM duty cycle monitor
   p_pwm_duty_mon: process
   begin
      if (i_chk_enable = '0') then        -- testbench/case checker enable control
         duty_fault <= '0';                  -- clear fault on function halt
         wait until (i_chk_enable = '1');
      else 
         wait until (i_pwm'event and i_pwm = '1') for ts_period*2;  -- wait for start of cycle (rising edge) with timeout
         v_rise_t := now;                       -- note when trigger occured
         duty_fault <= '0';                        -- on start of new cycle clear any previous fault indication
         if (i_pwm /= '1') then                 -- timeout check - occured if still low...
            printError (("bfm_pwm_checker_" & str(NODE_ID)), "pwm output stuck LOW ");
         else
            wait until (i_pwm'event and i_pwm = '0') for ts_period;  -- wait on duty cycle falling or timeout
            if (i_pwm /= '0') then              -- timeout check - occured if still high...
               printError (("bfm_pwm_checker_" & str(NODE_ID)), "pwm output stuck HIGH");
            else
               v_delta_t := now - v_rise_t;     -- capture elapsed time since last rising edge
               if ((v_delta_t < lower_lim) or (v_delta_t > upper_lim)) then  -- check if High duty +- MARGIN is out of bounds 
                  printError (("bfm_pwm_checker_" & str(NODE_ID)), ("pwm dutycycle out of bounds: "));
                  duty_fault <= '1';
               end if;               
            end if;
         end if;
      end if;
   end process;

   
   -----------------------------------
   -- period checker - verify period is as expected
   p_period_mon: process
   begin
      if (i_chk_enable = '0') then
         period_fault <= '0';                  -- clear fault on function halt
         wait until (i_chk_enable = '1');
      end if;
      wait until (i_pwm'event and i_pwm = '1') for (ts_period*1.5);  -- wait for start of first cycle of testing (rising edge) with timeout
      last_rising := now;                       -- note when trigger occured
      -- <<add timeout check>>
      if (i_pwm /= '1') then                 -- timeout check - occured if still low/tristate...
         printError (("bfm_pwm_checker_" & str(NODE_ID)), "pwm output stuck LOW ");
         period_fault <= '1';
         wait for 1 ns;  -- ensure fault pulse width
      end if;
      while (i_chk_enable = '1') loop
         wait until (i_pwm'event and i_pwm = '1') for (ts_period*1.5);  -- wait for start of cycle (rising edge) with timeout
         period_fault <= '0';                        -- on start of new cycle clear any previous fault indication
         if (i_pwm /= '1') then                 -- timeout check - occured if still low...
            printError (("bfm_pwm_checker_" & str(NODE_ID)), "pwm output stuck LOW ");
            period_fault <= '1';
            wait for 1 ns;  -- ensure fault pulse width
         else
            current_rising := now;
            delta_period := (current_rising - last_rising);
            if ( (delta_period <= (ts_period - margin)) or (delta_period >= (ts_period + margin)) ) then 
               printError (("bfm_pwm_checker_" & str(NODE_ID)), "pwm out of frequency spec");
               period_fault <= '1';
            end if;
            last_rising := current_rising;
         end if;
      end loop;
   end process;

   --<> Merge faults to single output port
   o_fault <= duty_fault or period_fault;

end behave;
