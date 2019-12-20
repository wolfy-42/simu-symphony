# FPGA simulation framework Symphony
As a design services company, at [Fidus](http://fidus.com/) we have to be able to quickly simulate our FPGA, independent of the underlying OS, simulation tool or FPGA vendor. 
- short setup time and learning curve, because we don't like wasting time
- sticking to simple language constructs for fast ramp-up
- promote all good practices in the field of verification - regression, randomization, scalability, etc
- flexible scripting structure to switch quickly between different OS, HDL languages and simulation tool vendors

# Features
- HDL supported - SystemVerilog, Verilog, VHDL
- Simulation tools supported - Mentor ModelSim/Questa, Vivado XSim, Active-HDL
- TCL based - works inside the tool (Modelsim/Quasta/Vivado) or in OS terminal (Linux/Windows) using the native/installed TCL interpreter 
- A preset template of a test-case, sticking to the basics, ready to be reused
- Code Coverage statistics reports
- Single Randomization seed for the whole environment
- Pass/Fail statistics per test-case and per regression run
- Automated regression executing all test-cases named with a with "tc_" prefix with back-list and white-lists 
- Regression statistics history accumulation
- Multithreaded regression runs for complex simulation environments, executing many test-cases in parallel, requiring one license per thread
- Send an email when regression is completed

# ToDo List
- Integrate UVVM, UVM, HLS
- Simulation tools support - Cadence Incisive, Aldec Riviera, Synopsys VCS
- submit jobs to remote machines

# Simple run commands
### Run a single test-case
```
cd symphony/sim/run
vsim -c -do ../testcases/tc_reset/tc_reset.tcl -do quit
```
### Run regression
```
cd symphony/sim/run
vsim -c -do ../scripts_configure/run_regression.tcl -do quit
```
