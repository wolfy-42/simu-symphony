# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Prepare simulation and run simulation
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_execute_simulation.tcl================\n"

# Call prSimCommand to do any necessary simulator-specific pre simulation prep - for example "onbrake {resume}"
preSimCommand $TCFILENAME $TCTIMESCALE

# Prep the sim command and execute it
if {$::CMD_ARG_OPTIMIZE > 0} {append SIMULATOR_INVOCATION " $::OPTIMIZATION_ON "
} else                       {append SIMULATOR_INVOCATION " $::OPTIMIZATION_OFF $::EXTRA_UNITS"}
if {$::CMD_ARG_COVERAGE > 0} {append SIMULATOR_INVOCATION " $::COVERAGE_ON"
} else                       {append SIMULATOR_INVOCATION " $::COVERAGE_OFF"}
eval $SIMULATOR_INVOCATION
