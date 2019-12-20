# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : TC coverage configuration
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_adjust_coverage.tcl================\n"

# Xsim does not support coverage
if {[string equal $::DEFAULT_SIMULATOR xsim]} {
    set ::CMD_ARG_COVERAGE    0
} 
# Sets coverage parameters if enabled in the commandline arguments
set ::COVERAGE_PARAMS $::COVERAGE_YES_PARAMS
if {$::CMD_ARG_COVERAGE == 0} {set ::COVERAGE_PARAMS $::COVERAGE_NO_PARAMS}
puts stdout "Coverage is set to $COVERAGE_PARAMS"
