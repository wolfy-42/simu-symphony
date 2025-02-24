# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : DV
# Created       : 2024-08-11
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Test-bench and test-case addition script
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts stdout "==============tbtc_add.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################s

# set VITISDIR [pwd] 
# cd $::TCSUBDIR
# set TBTCDIR [pwd] 
# cd $::VITISDIR

# Sim management lib
puts "Adding Sim management lib..."
add_files -tb ../../sim/libraries/sim_management_pkg.cpp
add_files -tb ../../sim/libraries/sim_management_pkg.h

# TB
puts "Adding TB..."
#add_files -tb $::TCSUBDIR/tb1.cpp

# TC
puts "Adding TC..."
add_files -tb $::TCSUBDIR/$::TCFILENAME.cpp
#add_files -tb $::TBTCDIR/$::TCFILENAME.cpp


# ##########################################################################################
