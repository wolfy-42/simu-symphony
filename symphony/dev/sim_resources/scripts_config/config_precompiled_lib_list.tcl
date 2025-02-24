#-----------------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-10-04
#-----------------------------------------------------------------------------//
#-----------------------------------------------------------------------------//
# Description   : Contains a list of libraries (name and path) to be mapped into the simlation.
#                    Each list entry contains the name of the library, a space, and then its path.
#
#                    There are two lists, one for vsim and one for xsim, because the entries will be
#                    different.
#
# Updated       : date / author - comments
#-----------------------------------------------------------------------------//

# --------------------------------------------------------------------//
# EDIT BELOW
# --------------------------------------------------------------------//

set VSIM_PRECOMPILED_LIB_LIST ""

# These get added to modelsim.ini via vmap. Called from a testcase's .tcl script.
# Append libraries here:
# Xilinx libs
#lappend VSIM_PRECOMPILED_LIB_LIST "secureip /home/jacob.von-chorus/Downloads/outputlibs/secureip"
#lappend VSIM_PRECOMPILED_LIB_LIST "unifast /home/jacob.von-chorus/Downloads/outputlibs/unifast"
#lappend VSIM_PRECOMPILED_LIB_LIST "unifast_ver /home/jacob.von-chorus/Downloads/outputlibs/unifast_ver"
#lappend VSIM_PRECOMPILED_LIB_LIST "unimacro /home/jacob.von-chorus/Downloads/outputlibs/unimacro"
#lappend VSIM_PRECOMPILED_LIB_LIST "unimacro_ver /home/jacob.von-chorus/Downloads/outputlibs/unimacro_ver"
#lappend VSIM_PRECOMPILED_LIB_LIST "unisim /home/jacob.von-chorus/Downloads/outputlibs/unisim"
#lappend VSIM_PRECOMPILED_LIB_LIST "unisims_ver /home/jacob.von-chorus/Downloads/outputlibs/unisims_ver"

# Active-HDL libs
#lappend VSIM_PRECOMPILED_LIB_LIST "lifmd_vlg lattice_simlibs/lifmd_vlg"
#lappend VSIM_PRECOMPILED_LIB_LIST "lifmd lattice_simlibs/lifmd"
#lappend VSIM_PRECOMPILED_LIB_LIST "pmi_work lattice_simlibs/pmi_work"

# ===========================================================================================================

set XSIM_PRECOMPILED_LIB_LIST ""

# These get added to xsim.ini directly. Called from a testcase's .tcl script.
# Append libraries here:
#lappend XSIM_PRECOMPILED_LIB_LIST "test1 /home/jacob.von-chorus/Downloads/test1"
#lappend XSIM_PRECOMPILED_LIB_LIST "test2 /home/jacob.von-chorus/Downloads/test2"

# ===========================================================================================================

set ACTIVEHDL_PRECOMPILED_LIB_LIST ""

# These get added to xsim.ini directly. Called from a testcase's .tcl script.
# Append libraries here:
#lappend XSIM_PRECOMPILED_LIB_LIST "test1 /home/jacob.von-chorus/Downloads/test1"
#lappend XSIM_PRECOMPILED_LIB_LIST "test2 /home/jacob.von-chorus/Downloads/test2"


# ===========================================================================================================

set XM_PRECOMPILED_LIB_LIST ""
# Append libraries here:

# ===========================================================================================================

# Set general list based on chosen simulator.
# DO NOT EDIT BELOW
if {$::DEFAULT_SIMULATOR eq "vsim"} {
    set PRECOMPILED_LIB_LIST $VSIM_PRECOMPILED_LIB_LIST}
if {$::DEFAULT_SIMULATOR eq "xsim"} {
    set PRECOMPILED_LIB_LIST $XSIM_PRECOMPILED_LIB_LIST}
if {$::DEFAULT_SIMULATOR eq "ahdl_gui" || $::DEFAULT_SIMULATOR eq "ahdl_sh"} {
    set PRECOMPILED_LIB_LIST $ACTIVEHDL_PRECOMPILED_LIB_LIST}
if {$::DEFAULT_SIMULATOR eq "xm"} {
    set PRECOMPILED_LIB_LIST $XSIM_PRECOMPILED_LIB_LIST}
