---------------------------------------------------------------------
--
-- Copyright (C) 2015 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Paul Roukema
-- Created       : 2015-05-12
---------------------------------------------------------------------
---------------------------------------------------------------------
-- Description   : Sample top level for VHDL simulation environment.
-- Updated       : date / author - comments
---------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity top_simuvhdl is
port(
    -- 200 MHz Differential clock
    i_CLK_200p      : in    std_logic;
    i_CLK_200n      : in    std_logic;

    i_RESET_n       : in    std_logic;

    ov_FPGA_TEST    :   out std_logic_vector(7 downto 0);
    o_LED           :   out std_logic
);
end top_simuvhdl;




architecture rtl of top_simuvhdl is

    component module1 is
    port(
        i_CLK       : in    std_logic;
        i_RESET_n   : in    std_logic;

        -- Test bus
        ov_FPGA_TEST:   out std_logic_vector(7 downto 0);
        -- LEDs turn on when high
        o_LED       :   out std_logic
        );
    end component;
begin

    module1_inst: module1
    port map(
        i_CLK           => i_CLK_200p,
        i_RESET_n       => i_RESET_n,
        ov_FPGA_TEST    => ov_FPGA_TEST,
        o_LED           => o_LED
    );


end rtl;


