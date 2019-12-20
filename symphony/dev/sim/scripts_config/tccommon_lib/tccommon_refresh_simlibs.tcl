# ---------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-08
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : New TC simulationlibraries compilation call
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

puts stdout "==============tccommon_refresh_simlibs.tcl================\n"

# Create sim lib
if {$::CMD_ARG_COMPILE > 0} {
   # Creates local msim directory and work library within.
   ensure_fresh_lib $SIM_LIBRARY_DIRNAME work
   # Map scripts_config/config_precompiled_lib_list.tcl's list.
   map_precompiled_lib_list }
