# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Paul Roukema
# Created       : 2021-05-17
# -----------------------------------------------------------------------//

===============================================================================================
Xilinx VIP Integration into SIMU Environment - Interface/Class only
===============================================================================================

Running the Example
-----------------------------------------------------------------------------------------------
1. cd dev/sim/run
2. ./simu.tcl
3. select_simulator vsim
4. compile_xilinx_libs ip
    * As instructed at the end of the command, copy the labelled output to scripts_config/precompiled_lib_list.tcl.
    * Tested with Vivado 2018.2
5. run_testcase ../testcases/tc_vip_axi_intf/tc_vip_axi_intf.tcl -opt

Expected Output:
        820ns:     MESSAGE (tc_vip_axi): Data read:
        820ns:     MESSAGE (tc_vip_axi): Burst beat           0: 12345678.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           1: 12345679.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           2: 1234567a.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           3: 1234567b.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           4: 1234567c.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           5: 1234567d.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           6: 1234567e.
        820ns:     MESSAGE (tc_vip_axi): Burst beat           7: 1234567f.


Simulator Setup
-----------------------------------------------------------------------------------------------

For Questa to be able to simulate the included VIPs, Xilinx simulation libraries have to be compiled, and a modelsim.ini file pointing to their location has to be includedt
in the "Ripl/ip/simu/simu/dev/sim/run" directory.

For XSIM ro be able to simulate the included VIPs, Xilinx simulation libraries are necessary. Unlike Questa, these libraries do not need to be compiled. However, the XSIM
simulator must be pointed to the locations of the simulation IPs included with the Vivado installation; these libraries are usually found under
"vivado_install_directory/data/xsim/ip". To accomplish this, copy xsim_ip.ini from "vivado_install_directory/data/xsim/ip" into
"Ripl/ip/simu/simu/dev/sim/run".

Within the always run portion of compile_all.tcl or in the tc_*.tcl file add the following to have the required libraried loaded by the simulator:

lappend ::EXTRA_LIBS xilinx_vip


