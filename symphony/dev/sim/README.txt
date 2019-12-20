# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Jacob von Chorus
# Created       : 2018-10-09
# -----------------------------------------------------------------------//
# -----------------------------------------------------------------------//
# Description   : README.txt for ../sim
#
# Updated       : date / author - comments
# -----------------------------------------------------------------------//

Simu contains modules, testcases, configuration scripts, bfms, and libraries.

Modules/Testcases:
    Modules are contained in folders under "./testcases/". These folders must begin with "tc". Each
    module may have several testcases, each with an associated .tcl file. Testcases must also begin with "tc".
    eg. ./testcases/tc_something/tc_xxxx.sv and ./testcases/tc_something/tc_xxxx.tcl 

    The module's testbench, required bfms, libraries, and rtl are compiled using a compile_all_<simulator>.tcl
    script located in each module folder.  There is one compile script (for each simulator)
    common to all testcases in a testcase folder.  These are sourced by each testcases' tc_xxxx.tcl
    script. The appropriate compilation script is chosen based on the simulator used.

    To create a new testcase:
        1. Module directories can be placed anywhere as long as the name begins with "tc". Testcases
            are placed in this directory.
        2. The testcase name must begin with "tc". A subdirectory can contain multiple testcases;
            the name of the module directory does not have to match the testcase name.
        3. Each testcase requires two files: a ".sv" file and a ".tcl" file where the filenames are
            identical to the testcase name. (eg. tc_vidgen.tcl and tc_vidgen.sv).
        4. A subdirectory contains a single tb.sv common to all testcases. The testcase is
            instantiated within the "tb" module. The compilation script
            (compile_all_vsim.tcl or compile_all_xsim.tcl) is common to all testcases. It compiles
            everything required by the testcase EXCEPT the testcase's .sv source file. The testcase is
            compiled in the testcase's .tcl script (see compile_tc in the testcase's .tcl script).
        5. Near the top of the testcase's .tcl script, the testcase name and the subdirectory must
            be configured. If the subdirectory is under sim/testcases/, use
            "$SIMDIR/$TESTCASESDIR/<tc_module> for the subdir variable. Otherwise use an absolute path,
            or a relative path from sim/run/.

Configuration:
    Configuration scripts allow for switching simulators and tweaking global simulation command options. See
    scripts_config/README.txt for details.

    Passing additional options to the simulation/optimization/compilation commands:
        - Prior to the "runSim" call in a testcase's .tcl script, additional parameters (such as
          libraries) can be appended to "simulator_invocation". Note, this is a global variable.
          The runSim command accepts a string as its last argument which is appended to the sim
          call.
        - Additional options can be passed to the optimization call by adding them to "eval
          $::optimization_invocation" in the testcase's .tcl script.
        - Compilation can be customized for everything except the testcase through
          compile_all_vsim.tcl (or its xsim counterpart).
        - Compilation of the testcase can be customized through the call to compile_tc in the
          testcase's .tcl script. Its last argument is a string appened to the compilation call.

Running a Testcase:
    - cd run/
    - ./simu
    - select_simulator <vsim | xsim>
    - run_testcase <path test testcase's .tcl script> -arg -arg
    (or)
    A single testcase can be run from the appropiate simulator.
    The simulator must be invoked from sim/run/.
    For Questa:
        vsim -do "do ../sim/testcases/tc_module/tc_testcase.tcl" [-c]
    For Vivado:
        vivado -mode batch -source ../sim/testcases/tc_module/tc_specific.tcl
    Or from within either simulator's command lines:
        source ../sim/testcases/tc_something/tc_specific.tcl

Regression:
    - cd run/
    - ./simu
    - select_simulator <vsim | xsim>
    - run_regression -arg -arg -arg
    (or)
    Regression runs every testcases automatically except those ignored in regression_settings_{v/x}sim.tcl.
    To run regression:
    For Questa:
        vsim -do "do ../sim/scripts_lib/run_regression.tcl" [-c]
    For Vivado:
        vivado -mode batch -source ../sim/scripts_lib/run_regression.tcl
    Or from within either:
        source ../sim/scripts_lib/run_regression.tcl

    The first invocation of regression creates a superlist of testcases under regression_results/. Regression can be
    invoked multiple times after and each instance will use the superlist to process testcases in parallel.

    Each regression instance creates a temporary directory _runxxxxxx, where xxxxxx is a unique number, to process its testcases.
    This ensures multiple instances of the simulator do not collide, ie. that they can run testcases in parallel without corrupting
    each other.

    Testcases Directories:
        By default, sim/testcases/ is searched. Additional testcases directories (containing module directories) can be added using
        "testcaseDirList" in regression_settings_{v/x}sim.tcl.

    Ignoring Testcases Under Testcases:
        Add the testcase to the list in regression_settings_{v/x}sim.tcl with the format:
            $moduleDir/tc_module/tc_testcase.tcl
    Ignoring Testcases Under External Testcases Directories:
        Add the testcase to the list in regression_settings_{v/x}sim.tcl with the path as specified in the external directory list:
            <path to module directory>/tc_testcase.tcl
    Ignoring Module Directories:
        Change the name of the directory so it does not begin with "tc". Eg. "_tc" or "ztc".

    Email:
        An email can be sent out when regression completes. To enable: Set use_email_notifications
        to 1 in config_scripts/general_settings.tcl. Set email_from and email_to to the sender and
        receiver. Set email_server to the mail server.

Command Line Options (single testcase and regression):
    To promote portability in Simu, command line arguments are not used. Instead
    scripts_lib/auto_gen/cmd_line_options.tcl contains the equivalent of commmand line options and is sourced by 
    each testcase and by regression.

    Simu.tcl allows normal command line options to be passed to run_regression and run_testcase; it
    copies cmd_line_options_default.tcl to cmd_line_options.tcl, modifies it with any additional
    arugments passed, and then passes it off to regression and testcases.

Results:
    Results for each test case are placed under ./testcases/tc_something/results_rtl/tc_specific.{wlf/log/wdb/etc}.
    Results include the transcript, the waveform database, and coverage.
    In a regression, every testcases' results are placed under results_rtl. Merged results/coverage are placed under
    regression_results/ and archived user regression_results/results_archive/ with a timestamp.
    The following results files can be produced (coverage can be disabled):
        regression_coverage_results.cov     -> Merged coverage in a format that can be opened in Questa with vcover.
        regression_coverage_results.cov.rep -> Text coverage report, human readable.
        regresion_results_all.log           -> Pass/Fail/Imcomplete/Warnings list at both the module and testcase levels.

IPI:
    Vivado can output simulation scripts for Questa or Xsim using: launch_simulation -scripts_only -absolute_path
    This must be run WITHOUT precompiling the simulation libraries from within Vivado, otherwise "launch_simulation..."
    does not produce compilations commands for the IP required. Unisim is precompiled under simu using 
    ./scripts_lib/compile_xilinx_libs.tcl. See that file for details.

    Module directories require an import_ipi_{v/x}sim.tcl script to handle extracting library
    arguments, and modifying the compile script Vivado produces.
    A testcase showing the import from IPI is included under ./testcases/tc_ipi/. The import scripts
    can be copied from there to new testcases.

    The import script uses functions defined in utils.tcl for appending/modifying/deleting lines in the ipi compilation script. Regular expressions
    are used for matching.

    Note, IPI requires Questa 10.6 (tested with Vivado 2018.1, 2018.2, and Questa 10.6d.) or xsim.

Pre-Compiled Libraries:
    From simu.tcl, Xilinx libraries can be pre-compiled with "compile_xilinx_libs". Two optional
    command line argments are "ip" which causes Vivado to compile all IP libraries as well as the
    basic unisim libraries. The second option is path=<path> which allows a custom output path to be
    selected (eg. /export/ssd/). By default run/xsimlibs is used.

    The compile_xilinx_libs command finishes by printing commands that can be copied and pasted into
    scripts_lib/precompiled_lib_list.tcl which tells simu which libraries to map into the simulator.

Directory Structure:
dev
|
----sim: is the root folder.
    |
    -bfms:          SystemVerilog BFMs used in testbenches. Eg. AXI4Stream Video Source/Sink
    -libraries:     Utility function used in testcases. Most important are the printPass and printError
                        functions found in sim_management_pkg.sv.
    -cores:         Contains an old glbl.v that may be required. May be safe to remove.
    -scripts_lib:   TCL utilities sourced when running simulations. Also contains scripts for running regression
                        and precompiling libraries.
        |-auto_gen/
        |       - cmd_line_options.tcl:     Where regression and testcases source "command line options" with.
        |       - config_settings.tcl:      Where simulator specific testcase settings are sourced from, copied from config_settings_{v/x}sim.tcl.
        |       - regression_settings.tcl:  Where simulator specific regression settings are sourced from, copied from regression_settings_{v/x}sim.tcl.
        |-run_regression.tcl:       Run regression.
        |-compile_xilinx_libs.tcl:  Precompile unisim.
        |-import_ipi_vsim.tcl:      Invoked within a testcase .tcl script to import an IPI design exported for Questa.
        |-import_ipi_xsim.tcl:      Invoked within a testcase .tcl script to import an IPI design exported for Xsim.
        |-utils.tcl:                Helper functions used by other .tcl scripts.
    -scripts_config:  Simulator specific configuration files.
        |-config_settings_{v/x}sim.tcl:     Global settings used by each testcase, comes in two flavours: vsim, xsim.
        |-regression_settings_{v/x}sim.tcl: Global settings used by regression, comes in two flavours: vsim, xsim.
        |-cmd_line_options_default.tcl:     Contains default command line options.
        |-precompiled_sim_libs.tcl:         List of pre-compiled libraries to map into the simulator.
    -testcases:     Location of testcase folders.
        |-tc_something: A testcase folder.
            |-compile_all_(vsim/xsim).tcl: Compilation script for testbench, one for each simulator.
            |-tc_specific.tcl:  Testcase simulation script.
            |-tc_specific.sv:   Testcase systemverilog code.
            |-tb.sv:            Testbench used by testcases. Testcases are instantiated in tb.
            |-results_rtl:      Directory containing simulation results. Created in simulation.
 
    -run
        |
        -simu.tcl:      Simu run environment, source or run this script to run simu.
        -msim:          Libraries created during Questa simulation. Deleted and recreated during each simulation.
        -modelsim.ini   Questa library mapping file, handled internally by Questa.
        -xsim.dir       Libraries created during Vivado simulation.
        -xsimlib:       Precompile unisim libraries. Required for IPI imports.


Helper
    A helper script, simu.tcl, is located in run/ and can be executed from there, either by executing directly in bash which brings up a tclsh instance, 
    or by sourcing in either Vivado or Questa. Running simu_help shows a list of commands with descriptions/usage. 

    Simulator selection (renaming the configuration files) is done through: select_simulator <name>. When simu.tcl is sourced in Vivado or Questa, select_simulator
    is automatically run for the appropiate simulator.

    Testcases and regression can be executed with run_testcase and run_regression respectively. Both support normal command line arguments, the helper functions 
    handle parsing them and modifying cmd_line_options.tcl as necessary. Regression results and coverage can be re-parsed with regression_results_parse and
    regression_coverage_parse. These also work if several instances of run_testcase was used, their results are merged for reporting. Regression_results_print and
    regression_coverage_print report merged results and coverage.

    Multi-threading can be achieved by running several instances of run_regression in different terminals. The regression script handles reserving and executing testcases.

Default Simulator
    A default simulator can be supplied to simu.tcl through scripts_config/general_settings.tcl.
    The simu.tcl helper script calls select_simulator on the default simulator and copies the
    appropriate simulator-specific settings files to scripts_lib/auto_gen/.

Further Information:
    Samples are included under ./testcases/. Documentation can be found in simu_doc/VIP_Environment_Script_Update.docx.
