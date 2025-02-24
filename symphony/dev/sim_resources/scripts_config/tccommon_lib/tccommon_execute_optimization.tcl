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
# Description   : Do RTL optimization if required and supported
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts_debug1 "==============tccommon_execute_optimization.tcl================\n"

# Optimize simulation models if needed.
if {$::CMD_ARG_OPTIMIZE > 0} {
    optimizeCommand $TCSUBDIR $TCFILENAME $TCTIMESCALE
}
