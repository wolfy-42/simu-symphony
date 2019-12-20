# --------------------------------------------------------------------//
# Copyright (C) 2018 Fidus Systems Inc.
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

puts stdout "==============tccommon_tc_compile_simulate.tcl================\n"

############################## Run Simulation #############################################
# Print config options/settings for information after being modified
source $SCRPTTCOMMONDIR/tccommon_print_config_options.tcl
# Create or refresh sim lib
source $SCRPTTCOMMONDIR/tccommon_refresh_simlibs.tcl
# Compile RTL, TB, BFMs, DUT, libs
source $SCRPTTCOMMONDIR/tccommon_execute_compile_all.tcl
# Optimize compiled RTL if needed.
source $SCRPTTCOMMONDIR/tccommon_execute_optimization.tcl
# Prep the sim command and execute it to enter simulation mode
source $SCRPTTCOMMONDIR/tccommon_execute_simulation.tcl
# Wave log output (wlf in questa) configure which signals to store
source $SCRPTTCOMMONDIR/tccommon_execute_simvarlogging.tcl
# Run simulation
eval $RUN_COMMAND
# Post process the coverage reports and save them
source $SCRPTTCOMMONDIR/tccommon_postprocess_coverage.tcl
# Close current log file and open new one just to be sure the old was closed.
transcript_reset "transcript.log"
# Exit simulator to release the license 
eval $SIMULATOR_QUIT
# When the simulator license is released then Reopens in viewer mode if the argument is selected and if not in regression
view_wave_log $::CMD_ARG_VIEW $TCSUBDIR/wave.do $TCSUBDIR $TCFILENAME

########################### Cleanup ##########################################
# Clean up local variables, for safety.
unset TCFILENAME
unset TCSUBDIR
unset INITSEED
unset TCTIMESCALE


