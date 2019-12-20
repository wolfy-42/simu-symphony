# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-10-05
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : README.txt for tc_ipi
#
# Updated       : date / author - comments
# -----------------------------------------------------------------------//

The tc_ipi testcases run a testbench involving a microblaze IPI design that prints several words to
a uart. 

Vivado Version Tested: 2018.1

Steps
=====

Build the project:
    1. cd dev/builds/vivado/projects
    2. vivado -mode tcl -source ../../scripts/create_project.tcl

Precompile Simulation Libraries:
    1. cd /dev/sim/run
    2. ./simu.tcl
    3. compile_xilinx_libs
    4. Update scripts_config/precompiled_lib_list.tcl as insctructed by compile_xilinx_libs

Run in Questa (vsim):
    1. cd dev/sim/run
    2. ./simu.tcl
    3. select_simulator vsim
    4. run_testcase ../testcases/tc_ipi/tc_ipi_vsim.tcl -opt

Run in Vivado (xsim):
    1. cd dev/sim/run
    2. ./simu.tcl
    3. select_simulator xsim
    4. run_testcase ../testcases/tc_ipi/tc_ipi_xsim.tcl

Expected Output:
    INITIAL
    Simulation is running, wait till simulation completes
    UART OUTPUT: =   G P I O   a n d   U A R T   t e s t s   P A S S E D
