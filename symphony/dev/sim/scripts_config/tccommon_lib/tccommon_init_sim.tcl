# ---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-17
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Initial settings before the simulation can start
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts_debug1 "==============tccommon_init_sim.tcl================"

# Ensure in new sim environment
eval $::SIMULATOR_QUIT

puts stdout "Quit simulation"

# Create result_rtl if it doesn't already exist.
if [file exists "$TCSUBDIR/result_rtl"] {
    } else {
        file mkdir "$TCSUBDIR/result_rtl"
        puts stdout "Created result_rtl log folder"
    }

# Clear previous text logs for a testcase
text_logs_init

# Close current log file, and open new transcript file
transcript_reset "$TCSUBDIR/result_rtl/$TCFILENAME.log"

puts stdout "\n"
