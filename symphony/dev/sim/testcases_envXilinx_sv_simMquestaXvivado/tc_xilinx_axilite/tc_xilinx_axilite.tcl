# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-06-22
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Template testbench for clock and reset BFMs.
#               Intentionally fails for demonstration purposes.
#
#               Command Line Options: uses modified scripts_lib/auto_gen/cmd_line_options.tcl
#
#               test-case: tc_xilinx_axilite.tcl
# Updated       : date / author - comments
# --------------------------------------------------------------------//

puts stdout "==============tc_... .tcl================\n"
# Include all config files
source ../scripts_config/config_settings_general_pointer.tcl

# ##########################################################################################
# Modify these two variables to reflect the current test-case and its location.
# TESTCASESDIR1 comes from confug_settings_general.tcl
# ##########################################################################################
set TCFILENAME tc_xilinx_axilite
set TCSUBDIR $TESTCASESDIR_XILINX/tc_xilinx_axilite

puts stdout "Executing $TCSUBDIR/$TCFILENAME.tcl"

# Test case configuration
source $TCCOMMON_TCCONFIG

# Can modify config variables here.
if {[string equal $::DEFAULT_SIMULATOR vsim]} {
    append ::OPTIMIZATION_INVOCATION " -L xilinx_vip -L axi_vip_v1_1_3"
    append ::SIMULATOR_INVOCATION " -L xilinx_vip -L axi_vip_v1_1_3"
} elseif {[string equal $::DEFAULT_SIMULATOR xsim]} {
    append ::XELAB_INVOCATION " -initfile=xsim_ip.ini -L xilinx_vip -L axi_vip_v1_1_3 -L axi_protocol_checker_v2_0_3 -L smartconnect_v1_0"
}


# Execute compilation and simulation
source $TCCOMMON_TCCOMPILESIMULATE

