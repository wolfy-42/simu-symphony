#!/bin/bash
# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2019-02-15
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Creates dependencies required to run a regression of all testcases               
#               Usage:
#                   cd sim/run/
#                   tclsh create_regression_dependencies.tcl
#   CURRENT TOOL VERSION REQUIREMENTS
#   - Vivado 2018.2
#   - Quartus 18.1 Standard
#   - Questa 10.6d
#   - Redhat 7
#       * Change checks below if versions change.
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------//

# Check licenses.
puts stdout "################################################################"
puts stdout "Checking /export/ssd/common_settings_licenses"
puts stdout "################################################################"
if { ![info exists ::env(LM_LICENSE_FILE)] } {
    puts stdout "ERROR LICENSES NOT SOURCED: source /export/ssd/common_settings/licenses"
    return;
}

# Check vivado 2018.2 path.
puts stdout "################################################################"
puts stdout "Checking /export/ssd/set_vivado.sh for 2018.2"
puts stdout "################################################################"
if { [catch {exec which vivado} msg] } {
    puts stdout "ERROR NO VIVADO: source /export/ssd/common_settings/set_vivado.sh 2018.2"
    return;
} else {
    # Check version
    if {[regexp -line "2018\\.2" $msg] == 0} {
        puts stdout "ERROR WRONG VIVADO VERSION: Requries 2018.2"
        return;
    }
}

# Check Questa 10.6d path.
puts stdout "################################################################"
puts stdout "Checking /export/ssd/Mentor/questa10.6d_1/questasim/linux_x86_64 in PATH"
puts stdout "################################################################"
if { [catch {exec which vsim} msg] } {
    puts stdout "ERROR NO VSIM: export PATH=/export/ssd/Mentor/questa_10_6_d/questasim/linux_x86_64:\$PATH"
    return;
}


######################################################################
# Compile Xilinx VSIM libraries.
puts stdout "################################################################"
puts stdout "Compiling Xilinx IP libraries for Questa."
puts stdout "################################################################"
if { ![file exists xsimlib] } {
    exec >&@stdout vivado -mode batch -notrace -source ../scripts_config/scripts_lib/compile_xilinx_libs.tcl -tclargs ip
} else {
    puts stdout ">>>>>>XILINX IP LIBRARIES FOR QUESTA ALREADY BUILT."
}

puts stdout "################################################################"
puts stdout "FINISHED: Dependencies for regression are complete."
puts stdout "################################################################"
