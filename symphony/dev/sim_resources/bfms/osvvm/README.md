# Open Source VHDL Verification Methodology (OSVVM)
This folder contains files from the OSVVM project.
https://github.com/OSVVM

It currently supports simulation models for AXI4, AXI4-Lite, AXI4-Stream, and UART protocols.

Documentation is available here: 
https://github.com/OSVVM/Documentation

### Running a test case
A few example tests have been ported to testcases_envOsvvm_vhdl_simMquesta.  
```run_testcase ../testcases_envOsvvm_vhdl_simMquesta/tc_osvvm_axi4/TbAxi4_BasicReadWrite.tcl -optimize```  
```run_testcase ../testcases_envOsvvm_vhdl_simMquesta/tc_osvvm_axi4l/TbAxi4_RandomReadWrite.tcl -optimize```  
```run_testcase ../testcases_envOsvvm_vhdl_simMquesta/tc_osvvm_axi4s/TbStream_SendCheckBurst1.tcl -optimize```  
```run_testcase ../testcases_envOsvvm_vhdl_simMquesta/tc_osvvm_uart/TbUart_SendGet1.tcl -optimize```  

**Note: The "-optimize" argument is mandatory for these tests.** Otherwise, vsim will fail with the following:  
```Error: (vcom-1004) Dependencies have changed since the last compilation. Cannot refresh this design unit. Use the -force_refresh option to override this check"```

These tests have only been verified on Questasim 10.6d.

### Porting a test bench/case:
1. Testbench file: AXI4/Axi4Lite/testbench/TbAxi4.vhd  
Copied to tc folder and renamed to tb.vhd.  
Modified the entity name to "tb".
2. Testcase file: AXI4/Axi4Lite/testbench/TbAxi4_RandomReadWrite.vhd  
Copied to tc folder.  
Modified the Configuration target to "tb".  
Modified the TranscriptOpen filepath to point to the tc results folder.

The list of source files (and vhdl libraries) for compilation was retrieved from the .pro (tcl) files.  
(Note: The only difference is we compile the test bench / case files into the default work library instead of a tb library.)

## Version Info (2021-06-07)
https://github.com/OSVVM/OsvvmLibraries.git  
Revision: 1acfcf0da3f6aaad908f01bfc080ccd3eb84bd35  
Date: 2021-05-21 1:23:59 AM  
Subrepos:
* AXI4 @ 638eee1
* Common @ bc9ef23
* UART @ ec0e17f
* osvvm @ 3ace82e
