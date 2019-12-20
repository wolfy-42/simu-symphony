----------------------------------------------------------------------
--
-- Copyright (C) 2015 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Paul Roukema
-- Created       : 2015-05-12
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Description   : global DUT interconnect signals
--               - permits Testcase manipulation of testbench interconnet ports/signals
-- Updated       : date / author - comments
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-----------------------------------------PACKAGE-------------------------------------
package global_signal_pkg is

    -----------------------------------------------------
    -- GLOBAL CONSTANTS
    --  - global constants and required by ALL Testbench/cases
    -----------------------------------------------------
    --<> Timing Constraints
    constant FPGA_CLK_PERIOD : time := 5 ns;  -- Main Oscillator (200MHz)
    --<>---------------------------------------------------
    --<> GLOBAL SIGNALS
    --<>---------------------------------------------------

    --<> ========== common VIP signals ===============
    signal sim_halt  : std_logic := '0'; -- used to stop simulation routines outside main process
    signal sim_rst   : std_logic;

    --<> =========== DUT interconnect signals =============
    signal CLK_200M  : std_logic;
    signal RESET_n   : std_logic := '1';
    signal FPGA_TEST : std_logic_vector(7 downto 0) := (others => '0');
    signal LED       : std_logic := '0';

    --<> =========== Testbench Type Declarations ===========
    --<> =========== Testbench signals/variables ===========
end global_signal_pkg;

package body global_signal_pkg is

end global_signal_pkg;


