# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Postprocess the coverage results and save them.
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_postprocess_coverage.tcl================\n"

# Post processing of coverage reports and saving
if {$::CMD_ARG_COVERAGE > 0} {
    puts stdout "Coverage report invocation...\n"
    eval $COVERAGE_REPORT_INVOCATION
    puts stdout "Coverage save invocation...\n"    
    eval $COVERAGE_SAVE_INVOCATION
    puts stdout "Coverage processing complete\n"
} else {
    puts stdout "No coverage selected.\n"
}
