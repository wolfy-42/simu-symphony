------------------------------------------------------------------------
--
--Copyright (C) 2006-2023 Fidus Systems Inc. 
--SPDX-License-Identifier: Apache-2.0 OR MIT
--The licenses stated above take precedence over any other contracts, agreements, etc.
--
--File name   : bfm_clock_generator_pkg.vhd
--Project     : VIP_VHDL
--Author      : Arnold Balisch)
--Created     : April 2011
--Description : 
--    - module to generate a clock signal with user-definable 
--      jitter, phase and duty-cycle control.  
------------------------------------------------------------------------
-- Modifications:
--    -- April 2011 - converted from original design "bfm_clock1_gen_pkg.vhd" by Chris Hesse (Fidus 2007)
--       to remove proceedure calls to enable multi-instance capability
--         - (new implementation sacrifices the original's on-the-fly changeability.)
--    -- Jan 23,2012 - converted to full 'real' numerical type on jitter calculations
--
------------------------------------------------------------------------
-- $Author: Arnold.Balisch $     $Revision: 1.1 $    $Date: 2012-09-21 10:22:40 $
------------------------------------------------------------------------

--==========================================PACKAGE HEADER==========================================

library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;


package bfm_clock_pkg is
   
   --=========== BFM Driver components =============
   component bfm_clock_gen is
      generic (   
         CLOCK_PERIOD  : time       := 100.0 ns;   -- period of clock (time)
         CLOCK_JITTER  : real       := 0.0e0;      -- amount of +/- jitter in # of nanoseconds
         CLOCK_PHASE   : real       := 0.0e00;     -- phase skew in # of degrees (0-360)
         CLOCK_DUTY_HI : integer    := 50          -- Duty cycle (HIGH portion before jitter) in percentage of full period (0-100)
         );
      port (
         o_clock    : out std_logic := '0';        -- output clock 
         i_clock_en : in std_logic  := '1'         -- clock enable input (disabled clock held LOW)
         );
   end component ;
   
end bfm_clock_pkg;

--==========================================PACKAGE BODY==========================================
package body bfm_clock_pkg is
   
end bfm_clock_pkg;
 
 
 
--==========================================PACKAGE ENTITY==========================================
-- BFM CLOCK GEN
library ieee, std, work;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use std.textio.all;
use work.txt_util.all;
use work.sim_management.all;

entity bfm_clock_gen is
   generic (   
      CLOCK_PERIOD  : time       := 100.0 ns;   -- period of clock (time)
      CLOCK_JITTER  : real       := 0.0e0;      -- amount of +/- jitter in # of nanoseconds
      CLOCK_PHASE   : real       := 0.0e00;     -- phase skew in # of degrees (0-360)
      CLOCK_DUTY_HI : integer    := 50          -- Duty cycle (HIGH portion before jitter) in percentage of full period (0-100)
      );
   port (
      o_clock    : out std_logic := '0';        -- output clock 
      i_clock_en : in std_logic  := '1'         -- clock enable input (disabled clock held LOW)
      );
end bfm_clock_gen;

architecture bfm_clock_gen_v of bfm_clock_gen is

-- constants derived from instance generics.
constant CLOCK_PERIOD_REAL : real    := real(CLOCK_PERIOD / 1 ns);  -- convert time to real
constant CLOCK_DUTY_LO     : integer := 100 - CLOCK_DUTY_HI;         -- duty_cycle balance
constant CLOCK_PERIOD_HI   : real := ((real(CLOCK_DUTY_HI)/1.0e02) * CLOCK_PERIOD_REAL); -- time of high dutycycle
constant CLOCK_PERIOD_LO   : real := ((real(CLOCK_DUTY_LO)/1.0e02) * CLOCK_PERIOD_REAL); -- time of low dutycycle
constant CLOCK_PHASE_DLY   : real    := (CLOCK_PHASE/3.60e02) * CLOCK_PERIOD_REAL;  -- phase offset unit

-- INTERNAL CLOCK SIGNALS
signal clock_reg            : std_logic := '0';

-- JITTER SIGNALS
signal clock_current_jitter : real   := 0.0e0;

begin

   -- check validity of input GENERICS immediately on startup.  Halt simulation if values invalid.
   process
   begin
      if (CLOCK_PHASE > 3.6e02 or CLOCK_PHASE < 0.0e00) then
         printError ("bfm_clock_gen", ("CLOCK_PHASE must be between 0 and 360 degrees"));
         assert (TRUE) severity failure;
      end if;
      if (CLOCK_PERIOD_REAL <= 0.0e00) then
         printError ("bfm_clock_gen", ("CLOCK_PERIOD must be greater than 0"));
         assert (TRUE) severity failure;
      end if;
      if (CLOCK_DUTY_HI > 99 or CLOCK_DUTY_HI < 1) then
         printError ("bfm_clock_gen", ("DUTY_CYCLE_HI =" & str(CLOCK_DUTY_HI) &" must be within 1 to 99"));      
         assert (TRUE) severity failure;
      end if;
      wait;    -- once verified, suspend process until end of simulation
   end process;
     
       
   -- generate jittered clock edges
   process
   begin
     wait for (CLOCK_PERIOD_LO + clock_current_jitter) * 1 ns;
       clock_reg <= '1';
     wait for (CLOCK_PERIOD_HI - clock_current_jitter) * 1 ns;
       clock_reg <= '0';
   end process;

   -- drive clock output with phase offset
   process (clock_reg, i_clock_en)
   begin
     if (clock_reg = '1' and i_clock_en = '1') then
       o_clock <= '1' after (CLOCK_PHASE_DLY) * 1 ns;    -- enabled and high 
     else
       o_clock <= '0' after (CLOCK_PHASE_DLY) * 1 ns;    -- enabled and low, or not_enabled
     end if;
   end process;

   -- perform randomized clock edge/period jitter perturbation calculations.
   process (clock_reg)
      variable random : real;
      variable seed1  : positive := 2;
      variable seed2  : positive := 199;
   begin  -- process clock_reg
     if (rising_edge(clock_reg)) then
       uniform(seed1,seed2,random);
       clock_current_jitter <= (random * real(CLOCK_JITTER));    
       if (integer(random*4.0e00) mod 2 = 1) then
         clock_current_jitter <= -clock_current_jitter;
       end if;
     end if;
   end process;
        
end bfm_clock_gen_v;
  
   --<> sample instance
   
   -- ------------------------------------------------------   
   -- -- main system clock (jitter capable)
   -- ------------------------------------------------------      
   -- clk_source_inst: bfm_clock_gen 
      -- generic map (   
         -- CLOCK_PERIOD  => 100 ns ,      -- period for 50MHz 
         -- CLOCK_JITTER  => 1.0e0 ,          -- amount of +/- jitter in # of nanoseconds
         -- CLOCK_PHASE   => 0.0e00,      -- phase skew in # of degrees (0-360)
         -- CLOCK_DUTY_HI => 50           -- Duty cycle (HIGH portion before jitter) in percentage of full period (0-100)
         -- )
      -- port map (
         -- o_clock    =>  ??,  -- output clock 
         -- -- i_clock_en =>  '1'         -- clock enable input ('1' = free run)
         -- i_clock_en =>  not sim_halt         -- clock enable input ('1' = free run)...halt clk at end of simulation
         -- );
         