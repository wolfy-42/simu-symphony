#-----------------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Dessislav Valkov
# Created       : 2019-10-22
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : A pointer to be used to easily switch to different config_settings_general.tcl files
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW
# --------------------------------------------------------------------//

puts stdout "==============config_settings_general_pointer.tcl================\n"


# overwrite the simulator for all scripts, except when set in simu shell it will be overwritten
set ::DEFAULT_SIMULATOR activehdl

# can be changed here and it will affect all scripts
source ../scripts_config/config_settings_general.tcl
