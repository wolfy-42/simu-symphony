# -----------------------------------------------------------------------//
#
# Copyright (C) 2019 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-07-09
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : Creates Microblaze example design and outputs Questa simulation
#               scripts. 
#
#               Use Vivado 2018.1.
#               From bash:
#               > cd builds/vivado/projects
#               > vivado -mode tcl -source ../../scripts/create_project.tcl
# Updated       : date / author - comments
# ----------------------------------------------------------------------//
create_project ipi_example . -part xc7k325tffg900-2
set_property board_part xilinx.com:kc705:part0:1.5 [current_project]
set_property target_language VHDL [current_project]
create_bd_design "base_mb" -mode batch
instantiate_example_design -template xilinx.com:design:base_mb:1.0 -design base_mb
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
set_property target_language Verilog [current_project]

# Generate 3rd party sim scripts for Xsim
launch_simulation -scripts_only -absolute_path

# Generate 3rd party sim scripts for Questa.
set_property target_simulator Questa [current_project]
launch_simulation -scripts_only -absolute_path
