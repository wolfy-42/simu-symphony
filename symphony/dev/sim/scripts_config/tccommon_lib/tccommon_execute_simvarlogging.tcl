# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Configure what signals to be logged during simulation
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_execute_simvarlogging.tcl================\n"

# Wave log output (wlf in questa)
if {$::CMD_ARG_LOGGING > 0} {eval $LOGGING_INVOCATION}