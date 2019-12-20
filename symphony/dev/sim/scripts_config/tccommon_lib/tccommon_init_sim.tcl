# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
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

puts stdout "==============tccommon_init_sim.tcl================"

# Ensure in new sim environment
catch [eval $::SIMULATOR_QUIT]
puts stdout "Quit simulation"

# Create result_rtl if it doesn't already exist.
if [file exists "$TCSUBDIR/result_rtl"] {
    } else {
        file mkdir "$TCSUBDIR/result_rtl"
        puts stdout "Created result_rtl log folder"
    }

# Close current log file, and open new transcript file
transcript_reset "$TCSUBDIR/result_rtl/$TCFILENAME.log"

puts stdout "\n"
