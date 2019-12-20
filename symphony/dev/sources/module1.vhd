-----------------------------------------------------------------------------//
--
-- Copyright (C) 2015 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Paul Roukema
-- Created       : 2015-05-12
-----------------------------------------------------------------------------//
-----------------------------------------------------------------------------//
-- Description   : Sample module for VHDL simulation environment.
-- Updated       : date / author - comments
-----------------------------------------------------------------------------//
library ieee;
use ieee.std_logic_1164.all;

entity module1 is
port(
    i_CLK       : in    std_logic;
    i_RESET_n   : in    std_logic;

    -- Test bus
    ov_FPGA_TEST:   out std_logic_vector(7 downto 0);
    -- LEDs turn on when high
    o_LED       :   out std_logic
    );
end module1;

architecture rtl of module1 is
    signal local_clk : std_logic;
begin
    local_clk <= i_CLK and i_RESET_n;

    ov_FPGA_TEST <= "00000" & local_clk & i_RESET_n & i_CLK;

    o_LED <= i_RESET_n;
end rtl;
