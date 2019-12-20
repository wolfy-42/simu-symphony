----------------------------------------------------------------------
--
-- Copyright (C) 2015 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Paul Roukema
-- Created       : 2015-05-12
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Description   : Simple sample top level testbench
-- Updated       : date / author - comments
----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_misc.all;
use ieee.std_logic_unsigned.all;  -- required for std_logic_vector -> integer conversion
use ieee.math_real.all;   -- for uniform, trunc functions

library work;
--<> General VIP Simulation libraries
use work.seed_pkg.all;
use work.txt_util.all;
use work.sim_management_vhdl.all;
use work.global_signal_pkg.all;  -- contains all board-level interconnect signals for global access
--<> bus functional model packages
use work.fidus_clock_gen_bfm_pkg.all;

entity tb is
end entity;

architecture behave of tb is
    component top_simuvhdl is
    port(
        -- 200 MHz Differential clock
        i_CLK_200p      : in    std_logic;
        i_CLK_200n      : in    std_logic;

        i_RESET_n       : in    std_logic;

        ov_FPGA_TEST    :   out std_logic_vector(7 downto 0);
        o_LED           :   out std_logic
    );
    end component;

   -- Component declaration for generic testcase (loaded by simulation scripting)
   component test_case
   end component;
begin



    ------------------------------------------------------------------
    -- main system clock (jitter capable)
    ------------------------------------------------------------------
    bfm_clk200Mhz_inst: fidus_clock_gen_bfm
    generic map (
         CLOCK_PERIOD  => FPGA_CLK_PERIOD , -- period for Main FPGA Clock
         CLOCK_JITTER  => 0.0e0 ,           -- amount of +/- jitter in # of nanoseconds
         CLOCK_PHASE   => 0.0e00,           -- phase skew in # of degrees (0-360)
         -- Duty cycle (HIGH portion before jitter) in percentage of full period (0-100 )
         CLOCK_DUTY_HI => 50
    )
    port map (
         o_clock    => CLK_200M,            -- output clock
    -- clock enable input ('1' = free run)... halt clk at end of simulation
         i_clock_en =>  not sim_halt
    );

    ------------------------------------------------------------------
    -- DEVICE UNDER TEST
    ------------------------------------------------------------------
    dut_inst : top_simuvhdl
    port map (
        -- Clocks and resets
        i_CLK_200p      => CLK_200M,
        i_CLK_200n      => not CLK_200M,

        i_RESET_n       => RESET_n,

        ov_FPGA_TEST    => FPGA_TEST,
        o_LED           => LED
    );

    ------------------------------------------------------
    -- instantiate Testcase pointed to by Modelsim compilation/run scripting
    ------------------------------------------------------
    test_case_inst : test_case;

end behave;



