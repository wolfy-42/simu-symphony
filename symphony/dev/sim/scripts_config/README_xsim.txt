# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-13
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Readme
#
# Updated       : date / author - comments
# -----------------------------------------------------------------------//

Vivado's XSim works with the testcases contained in this testbench. Some quirks are listed below.
    - $fread causes the simulator to crash if it is contained in a function/task inside a class. 
    - @(event) does not work with static events in a class.
    - xsim is stricter with SystemVerilog than vsim so a few small changes had to be made:
        * itoa in vsim can accept real data types, in xsim use realtoa
        * vsim allows tasks to be called from functions, xsim does not, use:
            fork
                task_call();
            join_none

Random/Urandom:
    - xsim can generate random numbers through $random().
    - It however does not support setting different seeds, ie. $urandom(seed).

Waveform data is saved in VCD format by default.
    The VCD can be opened in gtkwave
    > gtkwave ./testcases_module_level/tc_module1/rtl_result/tc_module1_test.vcd
    Wdb databases are also produced which can be opened in Vivado.

Waveform data is saved in WDB
    The WDB can be oppened in Vivado
    > open_wave_database file.wdb
    if you pass -view to run_testcase it is handled automatically and a viewer is opened.

