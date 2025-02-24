---------------------------------------------------------------------
-Copyright (C) 2006-2023 Fidus Systems Inc. 
-SPDX-License-Identifier: Apache-2.0 OR MIT
-The licenses stated above take precedence over any other contracts, agreements, etc.
---------------------------------------------------------------------
- RIPL IP SIMULATION REUSE
-   Verilog_BFMs Readme
-------------------------
Description:
This archive holds a variety of bus functional models (BFMs) to be used in 
SIMU_Verilog simulation projects.

The BFMs are sorted here by general type (analog, clock, processor_bus, etc) 
with additional subdirectories as required for sub-type/vendor.

----------------------
--- Initial Usage ---
----------------------
The intent is NOT to replicate this subdirectory tree structure within the active 
simu simulation project's /tb/bfm directrory.  Rather, the user should cut&paste 
the desired BFM(s) from this repository into the their projects /tb/bfm directory.  

(Note: That said, it may still be advantageous to use sub-directories in your project...
...so long as the /simu/config_files.tcl script encompasses this, there should be no issues.)

----------------------
--- RE-USE Updates ---
----------------------
At the end of the project, any revisions, bugfixes, or enhancements, to ANY of the BFMs used in your project should be merged back into 
the  RIPL/Simu/Simu_BFM archive where the original is located.

Any *NEW* BFMs created for your project that may have reuse potential should be added into the RIPL archive under an appropriate 
tree branch/leaf within the Simu_verilog_BFMs/ directory structure.

