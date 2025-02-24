# ---------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
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
preSimCommand $TCSUBDIR $TCFILENAME $TCTIMESCALE

simCommand $TCSUBDIR $TCFILENAME $TCTIMESCALE

