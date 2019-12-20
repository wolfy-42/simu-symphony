1. Before running any commands you might need to compile all libraries and example projects:
     cd dev/sim/run
     tclsh create_regression_dependencies.tcl

2. It is possible to run a single test case to be simulated.
     cd dev/sim/run
     vsim -c -do ../testcases/tc_reset/tc_reset.tcl -do exit

3. When many test cases are developed then it is common to run regression which will scan the testcases folder and run all test cases TCL files which name starts with tc_...
     cd dev/sim/run
     vsim -c -do ../scripts_config/run_regression.tcl -do exit

4. If you want a bit of a fancier environment, to bring up the simu CLI on a linux machine:
    cd dev/sim/run
    tclsh runme_simu_shell.tcl
  or 
    vsim -c -do runme_simu_shell.tcl
  or from inside a TCL interpreter of Vivado or Questa:
    source runme_simu_shell.tcl

It should list all commands available to you in that CLI with all options.
All simulations are always run from this folder location - dev/sim/run



