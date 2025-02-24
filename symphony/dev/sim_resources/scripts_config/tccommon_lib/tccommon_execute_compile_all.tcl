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
# Description   : Compiling the RTL and TB
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts_debug1 "==============tccommon_execute_compile_all.tcl================\n"

# Compile TB, BFMs, DUT, libs by calling compile_all_xxx.tcl in the TC folder

set simulator $::DEFAULT_SIMULATOR
if {[string equal $::DEFAULT_SIMULATOR ahdl_gui] || [string equal $::DEFAULT_SIMULATOR ahdl_sh]} {set simulator activehdl}
if {[file exist "$TCSUBDIR/compile_all_$simulator.tcl"]} {
    source "$TCSUBDIR/compile_all_$simulator.tcl"
} else {
    source "$TCSUBDIR/compile_all.tcl"
}
