# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Victor Dumitriu
# Created       : 2018-06-22
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : README.txt
#
# Updated       : date / author - comments
# -----------------------------------------------------------------------//

===============================================================================================
Xilinx VIP Integration into SIMU Environment
===============================================================================================

To use the Xilinx VIP suite, the desired IP must first be generated in Vivado. An example "Manage IP" project is provided with this example test-case and
test-bench which allows the creation and customization of three VIPs: AXI Lite Master, AXI Master and AXI Stream Master. 

To generate these IPs:
1. Run Vivado 2017.4.
2. Change directory to "Ripl/ip/simu/simu_systemverilog/dev/sim/bfms/xilinx_axi_vip".
3. Source vip_management_project_script.tcl (make sure no project is currently open).

Running the Example
-----------------------------------------------------------------------------------------------
1. cd dev/sim/run
2. ./simu.tcl
3. select_simulator vsim
4. compile_xilinx_libs ip
    * As instructed at the end of the command, copy the labelled output to scripts_config/precompiled_lib_list.tcl.
    * Tested with Vivado 2017.4.
5. run_testcase ../testcases/tc_vip_axis/tc_vip_axis.tcl -opt

Expected Output:
  -------------------------------------------------------
  NAME                               VALUE
  -------------------------------------------------------
  XIL_AXI4STREAM_TRANSACTION
    SIGNAL_SET                     0b10010011
    USER
    0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
    LAST                           0x1
    PAYLOAD                        4
      Byte[  0]:                   data: 67 
      Byte[  1]:                   data: 45 
      Byte[  2]:                   data: 23 
      Byte[  3]:                   data: 01 
  -------------------------------------------------------


Questa Setup
-----------------------------------------------------------------------------------------------

To be able to simulate the included VIPs, Xilinx simulation libraries have to be compiled, and a modelsim.ini file pointing to their location has to be included
in the "Ripl/ip/simu/simu_systemverilog/dev/sim/run" directory.

The section of the test-case simulation script which specifies simulation and optimization invocations must be edited to enable Questa settings, as shown below:

# ##########################################################################################
# Append libraries to the test-case compilation command and the optimization command
# as needed.
# ##########################################################################################

# Questa setup.
append ::optimization_invocation " -L xilinx_vip -L axi4stream_vip_v1_1_3"
append ::simulator_invocation " -L xilinx_vip -L axi4stream_vip_v1_1_3"
set tcLibList " -L xilinx_vip"

# Xsim setup.
#append ::xelab_invocation " -initfile=xsim_ip.ini -L xilinx_vip -L axi4stream_vip_v1_1_3 -L axis_protocol_checker_v1_2_1 -L smartconnect_v1_0"
#set tcLibList " -initfile=xsim_ip.ini -L xilinx_vip"

# Compile current test-case.
compile_tc $tcSubDir $tcFileName $tcTimeScale $tcLibList

# Optimize simulation models if needed.
if {$regressionArgArrayT(optimization) > 0} {
    eval $::optimization_invocation
}

# ##########################################################################################
# ##########################################################################################



XSIM Setup
-----------------------------------------------------------------------------------------------

To be able to simulate the included VIPs, Xilinx simulation libraries are necessary. Unlike Questa, these libraries do not need to be compiled. However, the XSIM
simulator must be pointed to the locations of the simulation IPs included with the Vivado installation; these libraries are usually found under
"vivado_install_directory/data/xsim/ip". To accomplish this, copy xsim_ip.ini from "vivado_install_directory/data/xsim/ip" into
"Ripl/ip/simu/simu_systemverilog/dev/sim/run".

The section of the test-case simulation script which specifies simulation and optimization invocations must be edited to enable XSIM settings, as shown below:

# ##########################################################################################
# Append libraries to the test-case compilation command and the optimization command
# as needed.
# ##########################################################################################

# Questa setup.
#append ::optimization_invocation " -L xilinx_vip -L axi4stream_vip_v1_1_3"
#append ::simulator_invocation " -L xilinx_vip -L axi4stream_vip_v1_1_3"
#set tcLibList " -L xilinx_vip"

# Xsim setup.
append ::xelab_invocation " -initfile=xsim_ip.ini -L xilinx_vip -L axi4stream_vip_v1_1_3 -L axis_protocol_checker_v1_2_1 -L smartconnect_v1_0"
set tcLibList " -initfile=xsim_ip.ini -L xilinx_vip"

# Compile current test-case.
compile_tc $tcSubDir $tcFileName $tcTimeScale $tcLibList

# Optimize simulation models if needed.
if {$regressionArgArrayT(optimization) > 0} {
    eval $::optimization_invocation
}

# ##########################################################################################
# ##########################################################################################


NOTE: currently, XSIM generates a memory error AFTER the simulations complete successfully.
