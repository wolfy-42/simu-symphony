//--------------------------------------------------------------------//
//
// Copyright (C) 2018 Fidus Systems Inc.
//
// Project       : simu
// Author        : Victor Dumitriu
// Created       : 2018-08-10
//--------------------------------------------------------------------//
//--------------------------------------------------------------------//
// Description   : README.txt
// Updated       : date / author - comments
//--------------------------------------------------------------------//

Quartus Platform Designer Test-Bench Example README
=========================================================================================================

Tested in 18.1 Standard.

Provided files:

intel_avalon_example_system.qsys    : Platform Designer example system containing an Intel Avalon MM master BFM
                                      and a PIO controller (acting as the DUT in this case).
                                   
gen_tb_cmd                          : Test-bench generation shell script, consisting of an invocation to the
                                      qsys_generate program.
                                      
tb.sv                               : Top-level test-bench file which instantiates the test-system as well as
                                      Intel clock and reset sources. This test-bench is copied from the
                                      intel_avalon_example_system/testbench/intel_avalon_example_system_tb/simulation
                                      renamed and edited as necessary (in this case, the test-case instantiation
                                      is added to the test-bench).

tc_avalon_mm_read_write.sv          : Example test-case, is responsible for generating stimulus.

tc_avalon_mm_read_write.tcl         : Test-case simulation script.

compile_all_vsim.tcl                : Compilation script for the provided test-case. NOTE: no XSIM compilation
                                      script is provided, this example assumes the use of the Questa simulator.



Simulation Setup
--------------------------------

To generate the test-bench use the command (Linux systems): . gen_tb_cmd

NOTE: make sure that the location of the /quartus/sopc_builder/bin directory has been added to you PATH
environment variable IN ADDITION to the quartus/bin directory.

Once the test-bench files are generated, run the simulation using the SIMU scripts.
