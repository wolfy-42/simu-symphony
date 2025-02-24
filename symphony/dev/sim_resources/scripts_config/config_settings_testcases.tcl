# ---------------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Paul Roukema
# Created       : 2019-01-03
# ---------------------------------------------------------------------------//
# ---------------------------------------------------------------------------//
# Description   : Regression testcase selection
#
#-----------------------------------------------------------------------------//


##################### Ignored testcases setup - Black-listed testcases ##################
# proc getRegressionTCIgnoreList
# Purpose: Returns a list of all testcases (tc_example.tcl) which should NOT be
#          included in the regression. To add TCs to this ignore list,
#          append the name of the testcases tcl script using the TCL lappend command.
# Inputs :
#       testcasesDir: Points to the local testcases directory.
# Outputs: regressionTCIgnoreList
proc getRegressionTCIgnoreList {testcasesDir} {
    puts_debug2 "==============config_settings_testcases::getRegressionTCIgnoreList================\n"
    set regressionTCIgnoreList ""

    # To add directories to this ignore list, simply append the name of the directory
    # using the TCL lappend command as shown in the next line.

    if { $::DEFAULT_SIMULATOR != "vsim" } { lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_vsim.tcl }
    if { $::DEFAULT_SIMULATOR != "xsim" } { lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_vivado/tc_xilinx_vivado_xsim.tcl }
    lappend regressionTCIgnoreList ../testcases_envFidus_sv_simMquestaXvivado/tc_fidus_axi4lite_10b_addr_i2c_master/tc_fidus_axi4lite_10b_addr_i2c_master.tcl 
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axi/tc_xilinx_axi.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axis/tc_xilinx_axis.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_XILINX/tc_xilinx_axilite/tc_xilinx_axilite.tcl
#    lappend regressionTCIgnoreList $::TESTCASESDIR_INTEL/tc_intel_quartus/tc_intel_quartus_mm_read_write.tcl

    return $regressionTCIgnoreList
}

############################## External Testcase Directory White List ##########################
# proc getExternalTestcaseDirs
# Purpose: Returns a list of paths to external testcase directories, containing several modules folders inside
#          These are used in regression.
#          Paths can be relative to dev/sim/run, or absolute.
proc getExternalTestcaseDirs {} {
    puts_debug2 "==============config_settings_testcases::getExternalTestcaseDirs================\n"
    set testcaseDirList ""

    # Local testcases
    lappend testcaseDirList $::TESTCASESDIR_FIDUS_SV
#    lappend testcaseDirList $::TESTCASESDIR_FIDUS_SV2
#    lappend testcaseDirList $::TESTCASESDIR_FIDUS_V
#    lappend testcaseDirList $::TESTCASESDIR_FIDUS_VHDL
#    lappend testcaseDirList $::TESTCASESDIR_XILINX
#    lappend testcaseDirList $::TESTCASESDIR_INTEL

}

