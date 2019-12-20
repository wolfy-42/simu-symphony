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
#   - Quartus 18.1 Standard
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

# Check Quartus 18.1 path.
puts stdout "################################################################"
puts stdout "Checking /export/ssd/altera/18.1/quartus/sopc_builder/bin in PATH"
puts stdout "Checking /export/ssd/altera/18.1/quartus/bin in PATH"
puts stdout "################################################################"
if { [catch {exec which qsys-generate} msg] } {
    puts stdout "ERROR NO QUARTUS: export PATH=/export/ssd/altera/18.1/quartus/sopc_builder/bin:/export/ssd/altera/18.1/quartus/bin:\$PATH"
    return;
} else {
    # Check version
    if {[regexp -line "18\\.1\\/" $msg] == 0} {
        puts stdout "ERROR WRONG QUARTUS VERSION: Requries 18.1 standard"
        return;
    }
}


######################################################################
# Build Intel QSYS example.
puts stdout "################################################################"
puts stdout "Building Intel QSYS example design."
puts stdout "################################################################"
cd ../testcases_envIntel_sv_simMquesta/tc_intel_quartus
if { ![file exists intel_avalon_example_system] } {
    exec >&@stdout bash -c "source gen_tb_cmd"
} else {
    puts stdout ">>>>>>INTEL QSYS EXAMPLE DESIGN ALREADY BUILT."
}
cd ../../run/

