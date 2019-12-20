# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Do RTL optimization if required and supported
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_execute_optimization.tcl================\n"

# Optimize simulation models if needed.
if {$::CMD_ARG_OPTIMIZE > 0} {
    eval "$OPTIMIZATION_INVOCATION $::EXTRA_UNITS"
}
