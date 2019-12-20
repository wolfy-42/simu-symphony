# -----------------------------------------------------------------------//
#
# Copyright (C) 2018 Fidus Systems Inc.
#
# Project       : simu
# Author        : Victor Dumitriu
# Created       : 2018-03-20
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Regression simulation script. Used to perform regression
#               simulation across one or more modules.
#
#               Usage: run_regression.tcl
#               Command Line Options: Modify scripts_lib/auto_gen/cmd_line_options.tcl
#
# Updated       : 2018-07-09 / Jacob von Chorus
#               Added creation of a superlist of testcases. Multiple instances
#               of regression reserve testcases from the list and can run in parallel.
#
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

# ----------------------------------------------------------------------//
# DO NOT EDIT
# ----------------------------------------------------------------------//

puts stdout "==============regression.tcl==============\n"

# Move instance to a unqiue runx/ directory by copying run/ and cd'ing to it.
# Generate random numbers until a unique one is found using lock files in run/
# and then copying run/ to runx/ where x is that random number.
#global runDirName
puts stdout "==============regression.tcl > Create Random run Folder==============\n"
while {1} {
    set runDirName "_run[expr int([expr rand()] * 1000000)]"
    if {![catch {open .$runDirName {WRONLY CREAT EXCL}} run_lock]} {
        break
    }
}
# Change directory up a level, copy run, change to the new directory.
#onerror {resume}
cd ..
file copy -- run $runDirName
cd $runDirName
puts stdout "cd to $runDirName\n" 

puts stdout "==============regression.tcl > Print Config Options==============\n"
if {$::CMD_ARG_MODNAME eq ""} {
    set argArray(singleMod)     0
    set argArray(modName)       ""
} else {
    set argArray(singleMod)     1
    set argArray(modName)       $::CMD_ARG_MODNAME
}
# Print configured options.
if {$argArray(singleMod) == 1} {
    puts stdout "Single module selected: $argArray(modName).\n"
} else {
    puts stdout "All modules are selected for regression.\n"    
}

# If not in report mode, create a superlist if necessary and run regression.
# If in report mode, create a superlist if necessary and generate a pass/fail list.
if {$::CMD_ARG_REPORT == 0} {
    # Create superlist of testcases if it does not already exist.
    if {[file exists $SUPERLISTNAME] == 0} {
        # The 0 requests result_rtl directories to be cleaned.
        puts stdout "==============regression.tcl > Create Regressions TC List to Run==============\n"        
        createSuperList $argArray(singleMod) $argArray(modName) 0
    }

    puts stdout "==============regression.tcl > Regression TC List Run==============\n"
    # Run regression testing on test-case list.
    set is_last [runRegression]
} else {
    puts stdout "==============regression.tcl > Generate Reports by Parsing Regression Results==============\n"   
    # Recreate regression results report
    # Define so there isn't an error later.
    set is_last 0
    # Create superlist of testcases if it does not already exist.
    if {[file exists $SUPERLISTNAME] == 0} {
        # The 1 requests result_rtl directories to be preserved.
        createSuperList $argArray(singleMod) $argArray(modName) 1

        # Parse all log files and update the superlist with pass/fail/warnings etc.
        # The sum up results function then uses this list to generate the results report.
        while {1} {
            set tcPath [getAvailableTestcase ignore]
            puts stdout "Parsing TC  $tcPath \n"                       
            if {$tcPath eq "NONE"} {
                # No testcases left 
                puts stdout "No test cases left to parse. \n"            
                break
            }
            # Get results -> Update superlist with pass/fail
            # Set local parameters.
            set modSubDir [file dirname $tcPath]
            set current_tc [file rootname [file tail $tcPath]]
            # Initialize regressionStatsArray
            set regressionStatsArray(passListModuleLevel)      ""
            set regressionStatsArray(failListModuleLevel)      ""
            set regressionStatsArray(noCompleteListModuleLevel) ""
            set regressionStatsArray(warningsListModuleLevel)   ""
            # Analyze log files, update superlist..
            set logName $modSubDir/result_rtl/$current_tc.log    
            parseLogFile $logName regressionStatsArray passListModuleLevel failListModuleLevel \
                warningsListModuleLevel noCompleteListModuleLevel
            if {[llength $regressionStatsArray(warningsListModuleLevel)] > 0} {
                set withWarnings 1
            } else {
                set withWarnings 0
            }
            if {[llength $regressionStatsArray(passListModuleLevel)] > 0} {
                superlistPassFail 1 $withWarnings $tcPath
            } elseif {[llength $regressionStatsArray(failListModuleLevel)] > 0} {
                superlistPassFail 0 $withWarnings $tcPath
            } elseif {[llength $regressionStatsArray(noCompleteListModuleLevel)] > 0} {
                superlistPassFail -1 $withWarnings $tcPath
            }
        }
    }
}

puts stdout "==============regression.tcl > Regression Results Parsing==============\n"
# Only merge results once or during a report.
if {$is_last == 1 || $::CMD_ARG_REPORT == 1} {
    # Wait for regression to finish unless in report mode.
    if {$::CMD_ARG_REPORT == 0} {
        superlistWaitOnCompletion
        # Report by email that regression is complete.
        set subject {[SIMU] Regression Complete}
        set body "Regression completed at: [clock format [clock seconds] -format "%Y/%m/%d %H:%M:%S %Z"]."
        send_simulation_complete_email $subject $body
    }
    ########################regression.tcl >  Per testcase directory Reporting/Merging ######################
    set modDirList ""
    # Gets filled in with directories that contain testcases that were run.
    # Passed to overall coverage merging, ensures it doesn't try to merge ignored testcases.
    set modDirUseful ""

    # Build list of testcase directories.
    set extraTestcaseDirs [getExternalTestcaseDirs]
    # Add extra testcase directories if specified
    foreach extraTestcase $extraTestcaseDirs {
        set modDirList_temp ""
        setModList modDirList_temp $argArray(singleMod) $argArray(modName) $extraTestcase
        set modDirList [concat $modDirList $modDirList_temp]
    }

    # For each testcase subdirectory, merge contained testcases. (ie. in result_rtl)
    foreach modDir $modDirList {
        set simResSubdir $modDir/result_rtl
        set tc_list_local ""
        set tcIgnoreList [getRegressionTCIgnoreList $::TESTCASESDIR1]

        # Build a list of testcase names.
        if {[catch {listDir "$modDir/tc*.tcl"} result]} {
            # No testcases in that directory.
        } else {
            foreach tCase $result {
                # Add testcase name if not ignored
                if {[lsearch $tcIgnoreList $tCase] < 0} {
                    # Only process this directory if it contains results.
                    if {[file isdirectory $modDir/result_rtl] == 1} {
                        lappend tc_list_local [file rootname [file tail $tCase]]
                    }
                }
            }
        }
        # Don't try to merge on ignored testcases.
        if {[llength $tc_list_local] == 0} {
            continue
        } else {
            lappend modDirUseful $modDir
        }

        # Merge all coverage results.
        if {$::CMD_ARG_COVERAGE > 0} {
            combCov $tc_list_local $simResSubdir regression_coverage
        }

        # Parse logs, report recursion PASS/FAIL status.
        # Prepare regression results log file for writing.
        set regLogId 0
        catch {file delete -force $simResSubdir/regression_results.log}
        if [catch {open $simResSubdir/regression_results.log w} regLogId] {
            puts stderr "Regression failed in $modSubDir. Could not open regression_results.log for writing"
            return
        }
        putz $regLogId "\n\n"

        # Initialize regressionStatsArray
        set regressionStatsArray(passListModuleLevel)      ""
        set regressionStatsArray(failListModuleLevel)      ""
        set regressionStatsArray(noCompleteListModuleLevel) ""
        set regressionStatsArray(warningsListModuleLevel)   ""

        # Analyze all log files.
        foreach item $tc_list_local {
            set logName $simResSubdir/$item.log    
            parseLogFile $logName regressionStatsArray passListModuleLevel failListModuleLevel warningsListModuleLevel noCompleteListModuleLevel
        }

        # Print final analysis results. (Per testcase subdirectory)
        sumUpResults $regLogId regressionStatsArray $modDir

        # Close log file.
        close $regLogId
    }

    if {[llength $modDirUseful] == 0} {
        puts stdout "No results to merge."
    } else {
        ########################regression.tcl >  Overall Reporting/Merging ######################
        # Combine coverage for all modules tested (if enabled).
        if {$::CMD_ARG_COVERAGE > 0} {
            combCovAll $modDirUseful $REGRESSION_RESULTS_DIR/regression_coverage_all
        }

        # Report final regression results.
        parseResAll $modDirUseful $REGRESSION_RESULTS_DIR/regression_results_all
    }
}

# Archive Results
if {$is_last == 1} {
    puts stdout "Archiving Results."
    set archiveName regression_results_[clock format [clock seconds] -format "%m-%d-%Y_%H-%M"]
    file mkdir "$ARCHIVE_DIR/$archiveName"

    file copy -force {*}[glob -nocomplain -dir ${REGRESSION_RESULTS_DIR} reg*] "$ARCHIVE_DIR/$archiveName/"
    file copy -force $SUPERLISTNAME "$ARCHIVE_DIR/$archiveName/"

    file rename -force $SUPERLISTNAME ${SUPERLISTNAME}_prev.txt
}
# In report mode, just delete the superlist
if {$::CMD_ARG_REPORT == 1} {
    file delete -force $SUPERLISTNAME
}

puts stdout "==============regression.tcl > Regressions End Cleanup==============\n"
# Remove locally set parameter array.
unset argArray

# Remove temporary run directory and change back to normal one
cd ..
# Deletes directory
file delete -force $runDirName
cd run
close $run_lock
# Deletes run directory lock
file delete -force $runDirName
