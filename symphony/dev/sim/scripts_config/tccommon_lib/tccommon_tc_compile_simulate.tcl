# --------------------------------------------------------------------//
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-25
# --------------------------------------------------------------------//
# --------------------------------------------------------------------//
# Description   : Common test case structure for compile and simulate
#
# Updated       : 2019-10-25 / author - comment
# --------------------------------------------------------------------//

puts_debug1 "==============tccommon_tc_compile_simulate.tcl================\n"

############################## Run Simulation #############################################
# Print config options/settings for information after being modified
source $SCRPTTCOMMONDIR/tccommon_print_config_options.tcl
# Create or refresh sim lib 
source $SCRPTTCOMMONDIR/tccommon_refresh_simlibs.tcl
# Compile RTL, TB, BFMs, DUT, libs
source $SCRPTTCOMMONDIR/tccommon_execute_compile_all.tcl
# Optimize compiled RTL if needed.
source $SCRPTTCOMMONDIR/tccommon_execute_optimization.tcl
# Prepare the sim commands in .tcl file to be used by the simulator
generateSimTclFile
# Call prSimCommand to do any necessary simulator-specific pre simulation prep - for example "onbrake {resume}"
preSimCommand 
simCommand 
# Close current log file and open new one just to be sure the old was closed.
transcript_reset "transcript.log"
# Exit simulator to release the license
eval $::SIMULATOR_QUIT
# When the simulator license is released then Reopens in viewer mode if the argument is selected and if not in regression
view_wave_log $::CMD_ARG_VIEW $TCSUBDIR/wave.do $TCSUBDIR $TCFILENAME

########################### Cleanup ##########################################
# Clean up variables, for safety.
unset TCFILENAME
unset TCSUBDIR
unset INITSEED
unset TCTIMESCALE


