----------------------------------------------------------------------//
--
-- Copyright (C) 2015 Fidus Systems Inc.
--
-- Project       : simu
-- Author        : Paul Roukema
-- Created       : 2015-05-13
----------------------------------------------------------------------//
----------------------------------------------------------------------//
-- Description   : template for device level test case
-- Updated       : date / author - comments
----------------------------------------------------------------------//

library ieee;
use ieee.std_logic_1164.all;

library work;
use work.seed_pkg.all;
use work.lib_math.all;
use work.txt_util.all;
use work.sim_management_vhdl.all;
use work.random_lib.all;
use work.global_signal_pkg.all;  -- contains all board-level interconnect signals for global access

entity test_case is
end test_case;

architecture simulation of test_case is
    --<> VIP env required declarations
    constant TC_NAME     : string  := "tc_resets1"; -- used to label all log-file output messages
    constant BFM_WRITE   : integer := 0;
    constant BFM_READ    : integer := 1;

   signal   rrr : real := 3.14;
   signal   hhh : std_logic_vector(31 downto 0) := x"abcd1234";

begin


    process is
        variable j   : integer := 14;
    begin
        wait for 1 ps;  -- delay to help keep message out of regression coverage log file
        --<>===== Common testcase startup conditions ===========
        printMessage (TC_NAME, "test case starting");

        --<>==== Initialize required testcase data structures
        printMessage (TC_NAME, "set Initial testcase Conditions");
        printMessage (TC_NAME, "Global Reset asserted");
        RESET_n <= '0';

        wait for 2 us;
        wait for Random_int(0,255) * 1 ns;

        RESET_n <= '1';

        wait for 2 us;

        -- check reset level
        if(LED = '1') then
            printMessage(TC_NAME, "RESET output released OK after initial global reset");
        else
            printError(TC_NAME, "RESET output released Bad after initial global reset");
        end if;

        -- Print display examples
        report(time'image(now) & " Compare task: Data Base centroid " & str(j) & " with expected : h = " & hstr(hhh) & " r = " & real'image(rrr) );
        printWarning(TC_NAME, time'image(now) & " Compare task: Data Base centroid " & str(j) & " with expected : h = " & hstr(hhh) & " r = " & real'image(rrr)  );

        --<>-----------------------------------------------------------------------------
        --<> halt simulation cleanly and close logfiles with pass/fail status
        allBfmsPleaseDoEndOfSimCheck(SEED_INITIAL_VALUE);
        testComplete(SEED_INITIAL_VALUE);
    end process;

end simulation;
