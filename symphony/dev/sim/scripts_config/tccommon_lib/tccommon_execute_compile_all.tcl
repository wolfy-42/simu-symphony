# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
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

puts stdout "==============tccommon_execute_compile_all.tcl================\n"

# Compile TB, BFMs, DUT, libs by calling compile_all_xxx.tcl in the TC folder
if {[string equal $::DEFAULT_SIMULATOR vsim]} {source $TCSUBDIR/compile_all_vsim.tcl}
if {[string equal $::DEFAULT_SIMULATOR xsim]} {source $TCSUBDIR/compile_all_xsim.tcl}
if {[string equal $::DEFAULT_SIMULATOR ahdl_gui] || [string equal $::DEFAULT_SIMULATOR ahdl_sh]} {source $TCSUBDIR/compile_all_activehdl.tcl}

