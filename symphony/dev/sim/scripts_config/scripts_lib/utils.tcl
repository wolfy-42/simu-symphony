# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Victor Dumitriu
# Created       : 2018-03-20
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Source file for utility procedures used in the updated RIPL
#               SIMU simulation scripting environment. These procedures are
#               used as part of the regression testing process. Some of the
#               procedures (or parts of them) are taken from the original
#               SIMU scripts.
#
# Updated       : 2018-07-07 / Jacob
#               Added creation of a superlist of testcases. Multiple instances
#               of regression reserve testcases from the list and can run in parallel.
#
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

# ----------------------------------------------------------------------//
# DO NOT EDIT
# ----------------------------------------------------------------------//

puts_debug1 "==============utils.tcl================\n"

global fname_utils
set fname_utils "---->utils.tcl: "

# proc prn {}
# Purpose: This procedure prints under Linux and Windows.
# Inputs:
#        in     --> String to be printed.
# Outputs: passes the string to the proper function.
proc prn {in} {
global tcl_platform
switch -glob $tcl_platform(os) {
	[lL]inux*   {prnLin $in}
	[wW]indows* {prnLin $in}
	default {error "$::fname_utils determine OS in use: unrecognised OS - $tcl_platform(os)"}
    }
}


# proc prnLin {}
# Purpose: This procedure prints under Linux in the ModelSim window, contrary to
#          puts and printf which print in the terminal window.
# Inputs:
#         in    --> String to be printed.
# Outputs: Printed text in the MdelSim window.
proc prnLin {in} {
    echo $in
}


# proc listDir {}
# Purpose: Gets directory listings. Works under both Windows and Linux.
# Inputs:
#        argsList   --> list of arguments, such as *.v, to be passed to the
#                       directory listing facility on your OS of choice.
# Outputs: directory listing, in list format.
proc listDir {{argsList *}} {
    global tcl_platform
    set result ""
    switch -glob $tcl_platform(os) {
        [wW]indows* {set result [listDirLinux $argsList]}
        [lL]inux*   {set result [listDirLinux $argsList]}
        CYGWIN*     {set result [listDirLinux $argsList]}
        default  {puts stderr "$::fname_utils unknown OS -->$tcl_platform(os)"}
    }
    return $result
}


# proc listDirDos {}
# Purpose: Gets directory listings under Windows.
# Inputs:
#        argsList   --> list of arguments, such as *.v, to be passed to the
#                       dir command.
# Outputs: directory listing, in list format.
proc listDirDos {argsList} {
    catch {exec cmd.exe /c dir /b [file nativename $argsList]} result
    return $result
}


# proc listDirLinux {}
# Purpose: Gets directory listings under Linux.
# Inputs:
#        argsList   --> list of arguments, such as *.v, to be passed to the
#                       ls command.
# Outputs: directory listing, in list format.
proc listDirLinux {argsList} {
    catch {glob -nocomplain $argsList} fls
    set result " "
    foreach f $fls {set result $result$f\n}
    return $result
}


# proc putz {}
# Purpose: To write the message to both stdout and the specified channel.
# Inputs:
#        channel    --> the channel to write to.
#        message    --> the message to write.
# Outputs: none.
proc putz {channel message} {
    puts stdout   $message
    #prn $message
    puts $channel $message
    flush $channel
    return
}

# proc del_script_line {}
# Purpose: To delete a line in a script based on a regular expression.
# Inputs:
#        path:  file to modify
#        regex: search term
#           - do not include "^" or "$" in regex, they are added automatically
#           - to match something at the beginning of a line: {term.*}
#           - to match at the end of a line: {.*term}
#           - to match inside a line: {.*term.*}
# Outputs: none.
proc del_script_line {path regex} {
    set fp [open $path r]
    set file_data [read $fp]
    close $fp

    # Replace matches with nothing - deletion
    set file_data [regsub -all -line -- ^$regex\(?:\\n|\$) $file_data {}]

    set fp [open $path w]
    puts $fp $file_data
    close $fp
}

# proc mod_script {}
# Purpose: To modify a line in a script based on a regular expression.
# Inputs:
#        path:  file to modify
#        regex: search term - passed directly to regsub
#        sub: text to replace regex's matches with
#        line_based: 1 causes ^/$ to match the beginning and end of a line
#                    0 causes ^/$ to match the beginning and end of the script
# Outputs: none.
proc mod_script {path regex sub line_based} {
    set fp [open $path r]
    set file_data [read $fp]
    close $fp

    # Replace matches with nothing - deletion
    if {$line_based} {
        set file_data [regsub -all -line -- $regex $file_data $sub]
    } else {
        set file_data [regsub -all -- $regex $file_data $sub]
    }

    set fp [open $path w]
    puts $fp $file_data
    close $fp
}

# proc add_script_line {}
# Purpose: Adds a line to the end of a script.
# Inputs:
#        path:  file to modify
#        newline: text to add on a newline
# Outputs: none.
proc add_script_line {path newline} {
    set fp [open $path r]
    set file_data [read $fp]
    close $fp

    append file_data "\n" $newline

    set fp [open $path w]
    puts $fp $file_data
    close $fp
}

# proc del_lib_arg {}
# Purpose: Deletes a library from a library argument list
# Inputs:
#        lib_list: list of libraries to delete
#        lib:      library to delete
# Returns: new library list
proc del_lib_arg {lib_list lib} {
    set del_index [lsearch -exact $lib_list "\-L $lib"]

    set new_list [lreplace $lib_list $del_index $del_index]
    return $new_list
}

# proc add_lib_arg {}
# Purpose: Adds a library from to the library argument list
# Inputs:
#        lib_list: list of libraries to delete
#        lib:      library to add
# Returns: new library list
proc add_lib_arg {lib_list lib} {
        set new_list $lib_list
        lappend new_list "-L $lib"
        return $new_list
}

# proc combCov {}
# Purpose: Procedure which combines a set of coverage data files for a given module.
# Inputs:
#        tc_list        --> List of test-case names.
#        covDatSubdir   --> Path for test-case coverage data sub-directory, relative to tb/.
#        covCombName    --> Intended name for the complete coverage data file and report.
# Outputs: A combined coverage file and coverage report are created in the coverage data
#          sub-directory.
proc combCov {tc_list covDatSubdir covCombName} {
    puts_debug2 "==============utils::combCov================\n"
    set next_index -1
    for {set i 0} {$i < [llength $tc_list]} {incr i} {
        #Loop until first valid coverage file
        if {![file exists $covDatSubdir/[lindex $tc_list $i].cov]} {
            puts stdout "INFO: Could not open $covDatSubdir/[lindex $tc_list $i].cov for merging."
            continue
        }
        coverageMergeCmd $covDatSubdir/$covCombName.cov $covDatSubdir/[lindex $tc_list $i].cov {}
        set next_index [expr $i + 1]
        break
    }
    # No coverage in this directory to merge.
    if {$next_index == -1} {
        return
    }

    for {set i $next_index} {$i < [llength $tc_list]} {incr i} {
        if {$i == 1} {
            file rename -force $covDatSubdir/$covCombName.cov $covDatSubdir/temp.cov
            coverageMergeCmd $covDatSubdir/$covCombName.cov $covDatSubdir/[lindex $tc_list $i].cov $covDatSubdir/temp.cov
        } else {
            file delete -force $covDatSubdir/temp.cov
            file rename -force $covDatSubdir/$covCombName.cov $covDatSubdir/temp.cov
            coverageMergeCmd $covDatSubdir/$covCombName.cov $covDatSubdir/[lindex $tc_list $i].cov $covDatSubdir/temp.cov
        }
    }

    file delete -force $covDatSubdir/temp.cov

    coverageReportCmd $covDatSubdir/$covCombName.cov.rep $covDatSubdir/$covCombName.cov

    return
}


# proc combCovAll {}
# Purpose: Procedure which combines test coverage data from multiple modules.
# Inputs:
#        modList        --> List of module names.
#        covCombName    --> Name for the complete coverage data and report.
# Outputs: A combined coverage data file and report are created in the root tb/
#          directory.
proc combCovAll {modList covCombName} {
    puts_debug2 "==============utils::combCovAll================\n"
    set next_index -1
    for {set i 0} {$i < [llength $modList]} {incr i} {
        #Loop until first valid coverage file
        if {![file exists [lindex $modList $i]/result_rtl/regression_coverage.cov]} {
            puts stdout "INFO: Could not open [lindex $modList $i]/result_rtl/regression_coverage.cov for merging."
            continue
        }
        coverageMergeCmd $covCombName.cov [lindex $modList $i]/result_rtl/regression_coverage.cov {}
        set next_index [expr $i + 1]
        break
    }
    # No coverage in this directory to merge.
    if {$next_index == -1} {
        return
    }

    for {set i $next_index} {$i < [llength $modList]} {incr i} {
        if {$i == 1} {
            file rename -force $covCombName.cov temp.cov
            coverageMergeCmd $covCombName.cov [lindex $modList $i]/result_rtl/regression_coverage.cov temp.cov
        } else {
            file delete -force temp.cov
            file rename -force $covCombName.cov temp.cov
            coverageMergeCmd $covCombName.cov [lindex $modList $i]/result_rtl/regression_coverage.cov temp.cov
        }
    }

    file delete -force temp.cov

    coverageReportCmd $covCombName.cov.rep $covCombName.cov

    return
}


# proc parseLogFile {}
# Purpose: This script parses through a simulation log file and hunts for the
#          SIMULATION STATUS line in a log file. If the log file indicates PASS,
#          then the test case name is added to the regressionStatsArray($passIndex).
#          If the log file indicates FAIL, then the test case name is added to the
#          regressionStatsArray($failIndex). If the log file specifies neither
#          PASS nor FAIL, then the test case name is added to the
#          regressionStatsArray($noCompleteIndex).
# Inputs :
#         logFileNameAndPath      --> The full path and file name of the
#                                     log file to be parsed.
#        regressionStatsArrayName --> name of the array containing the pass,
#                                     fail, no complete lists.
#        passIndex                --> stats array index where we should add the name of passing test cases
#        failIndex                --> stats array index where we should add the name of failing test cases
#        warningsIndex            --> stats array index where we should add the name of test cases with warnings
#        noCompleteIndex          --> stats array index where we should add the name of test cases which did not complete
# Outputs: none.
proc parseLogFile {logFileNameAndPath regressionStatsArrayName passIndex failIndex warningsIndex noCompleteIndex} {
    puts_debug2 "==============utils::parseLogFile================\n"
    upvar 1 $regressionStatsArrayName statsArray

    if [catch {open $logFileNameAndPath r} fileId] {
        puts stderr "Could not open $logFileNameAndPath for reading"
    } else {
        set tcName [file tail [file rootname $logFileNameAndPath]]
        set splitPathElements [file split $logFileNameAndPath]
        set path ""
        for {set i 0} {$i < [expr [llength $splitPathElements] - 2]} {incr i 1} {
            set path [file join $path [lindex $splitPathElements $i]]
        }
        #if {[string match verilog $::LANGUAGE]} {
        set tcName "[file join $path $tcName].sv"
        #} else {
        #    set tcName "[file join $path $tcName].vhd"
        #}
        set foundStatus false
        while {[gets $fileId line] >= 0} {
            if [string match {*SIMULATION STATUS:*FAIL} $line] {
                lappend statsArray($failIndex) $tcName
                set foundStatus true
            } elseif [string match {*SIMULATION STATUS:*PASS} $line] {
                lappend statsArray($passIndex) $tcName
                set foundStatus true
            } elseif {[string match "\# WARNINGS*:*" $line] || [regexp -line "^WARNINGS:\\s\\d" $line]} {
                set index [string first {: } $line]
                set index [expr $index + 1]
                set nbOfWarnings [string range $line $index [string length $line]]
            #	puts stdout "nb of warnings in $logFileNameAndPath=$nbOfWarnings"
                if [string match " 0" $nbOfWarnings] {
                } else {
                    lappend statsArray($warningsIndex) $tcName
                }
            }
        }
        if [string match false $foundStatus] {
            lappend statsArray($noCompleteIndex) $tcName
        }
        close $fileId
    }
    return
}


# proc parseRegLog {}
# Purpose: This script parses through a module-level regression result log file and
#          checks for lines indicating how many test-cases passed or failed. Based on
#          the parsing results, the module directory name is added to a list of passing
#          or failing module regressions.
#
# Inputs:
#        logFileNameAndPath         --> The full path and file name of the
#                                       log file to be parsed.
#        regressionStatsArrayName   --> name of the array containing the pass and
#                                       fail lists.
#        passIndex                  --> stats array index where we should add the name of passing test cases.
#        failIndex                  --> stats array index where we should add the name of failing test cases.
# Outputs: none.
proc parseRegLog {logFileNameAndPath regressionStatsArrayName passIndex failIndex} {
    puts_debug2 "==============utils::parseRegLog================\n"
    upvar 1 $regressionStatsArrayName statsArray

    if [catch {open $logFileNameAndPath r} fileId] {
        puts stderr "Could not open $logFileNameAndPath for reading"
    } else {
        #set tcName [file tail [file rootname $logFileNameAndPath]]
        set splitPathElements [file split $logFileNameAndPath]
        set path ""
        for {set i 0} {$i < [expr [llength $splitPathElements] - 2]} {incr i 1} {
            set path [file join $path [lindex $splitPathElements $i]]
        }
        #if {[string match verilog $::LANGUAGE]} {
        #set tcName "[file join $path $tcName]"
        set tcName $path
        #} else {
        #    set tcName "[file join $path $tcName].vhd"
        #}
        set foundStatus false
        while {[gets $fileId line] >= 0} {
            if {[string match {*FAILURES: 0*} $line] && [string match {*TESTS THAT DID NOT COMPLETE: 0*} $line]} {
                lappend statsArray($passIndex) $tcName
                set foundStatus true
            } elseif {[string match {*PASSES:*} $line] && [string match {*FAILURES:*} $line]} {
                lappend statsArray($failIndex) $tcName
                set foundStatus true
            }
        }
        close $fileId
    }
    return
}


# proc sumUpResults {}
# Purpose: To summarize regression results and update a module-level regression log.
# Inputs:
#        channel                    --> Channel to regression_results.log file, assumes it
#                                       is already opened for writing.
#        regressionStatsArrayName   --> Name of the array containing the pass,
#                                       fail, no complete lists.
#        tdDir                      --> Directory being summed up
# Outputs: none.
proc sumUpResults {channel regressionStatsArrayName tcDir} {
    puts_debug2 "==============utils::sumUpResults================\n"
    upvar 1 $regressionStatsArrayName regressionStatsArray

    set nbOfPasses    [expr [llength $regressionStatsArray(passListModuleLevel)]]
    set nbOfFails     [expr [llength $regressionStatsArray(failListModuleLevel)]]
    set nbOfNoComplete [expr [llength $regressionStatsArray(noCompleteListModuleLevel)]]

    putz $channel "\nSIMULATION STATUS: $tcDir"
    putz $channel "NUMBER OF TEST CASES EXECUTED: [expr $nbOfPasses + $nbOfFails + $nbOfNoComplete]"
    putz $channel "PASSES: $nbOfPasses \tFAILURES: $nbOfFails \tTESTS THAT DID NOT COMPLETE: $nbOfNoComplete"
    putz $channel "========================== STATS ============================="

    putz $channel "\n\nPASS LIST:"
    foreach testCase $regressionStatsArray(passListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\nFAIL LIST:"
    foreach testCase $regressionStatsArray(failListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\nDID NOT COMPLETE LIST:"
    foreach testCase $regressionStatsArray(noCompleteListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\nTESTS WITH WARNINGS:"
    foreach testCase $regressionStatsArray(warningsListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\n=============== END OF STATS ================================="

    return
}


# proc sumUpResultsAll {}
# Purpose: To summarize regression results and update a module-level  and testcase-level
#           regression log.
# Inputs:
#        channel                    --> Channel to regression_results.log file, assumes it
#                                       is already opened for writing.
#        regressionStatsArrayName   --> Name of the array containing the pass,
#                                       fail, no complete lists.
# Outputs: none.
proc sumUpResultsAll {channel regressionStatsArrayName} {
    puts_debug2 "==============utils::sumUpResultsAll================\n"
    upvar 1 $regressionStatsArrayName regressionStatsArray

    set nbOfPasses    [expr [llength $regressionStatsArray(passListModuleLevel)]]
    set nbOfFails     [expr [llength $regressionStatsArray(failListModuleLevel)]]

    putz $channel "\nREGRESSION STATUS (MODULES LEVEL):"
    putz $channel "Analyzed modules: [expr $nbOfPasses + $nbOfFails]"
    putz $channel "PASSES: $nbOfPasses \tFAILURES: $nbOfFails"
    putz $channel "========================= STATS =============================="

    putz $channel "\n\nPASS LIST:"
    foreach testCase $regressionStatsArray(passListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\nFAIL LIST:"
    foreach testCase $regressionStatsArray(failListModuleLevel) {
        putz $channel $testCase
    }

    putz $channel "\n\n=============== END OF STATS ================================="

    putz $channel "\n=========== REGRESSION SUMMARY (TESTCASE LEVEL) =============="

    set fp_lock [acquireSuperlistLock]
    # Locked access begins
    # Read superlist - return NONE if it has been removed.
    if {[catch  {open $::SUPERLISTNAME r} fp_list]} {
        # Locked access ends
        putz $channel "Failed to parse results."
        releaseSuperlistLock $fp_lock
        return
    }
    set list_data [read $fp_list]
    close $fp_list
    # Locked access ends
    releaseSuperlistLock $fp_lock

    set tcPassList [regexp -all -line -inline "^.*\\|Pass" $list_data]
    set tcFailList [regexp -all -line -inline "^.*\\|Fail" $list_data]
    set tcNoCompleteList [regexp -all -line -inline "^.*\\|Did Not Complete" $list_data]
    set tcWarningsList [regexp -all -line -inline "^.*\\|.*Warnings$" $list_data]

    putz $channel "\n\nPASS LIST:"
    foreach testCase $tcPassList {
        # Duration string is the 4th column.
        set data_cols [split $testCase "|"]
        putz $channel "[regexp -inline "^.*?(?=\\|)" $testCase] (Duration: [lindex $data_cols 3])"
    }

    putz $channel "\n\nFAIL LIST:"
    foreach testCase $tcFailList {
        # Duration string is the 4th column.
        set data_cols [split $testCase "|"]
        putz $channel "[regexp -inline "^.*?(?=\\|)" $testCase] (Duration: [lindex $data_cols 3])"
    }

    putz $channel "\n\nDID NOT COMPLETE LIST:"
    foreach testCase $tcNoCompleteList {
        # Duration string is the 4th column.
        set data_cols [split $testCase "|"]
        putz $channel "[regexp -inline "^.*?(?=\\|)" $testCase] (Duration: [lindex $data_cols 3])"
    }

    putz $channel "\n\nTESTS WITH WARNINGS:"
    foreach testCase $tcWarningsList {
        putz $channel [regexp -inline "^.*?(?=\\|)" $testCase]
    }

    putz $channel "\n\n=============== END OF TC PASS/FAIL LIST ====================="

    if {$nbOfFails == 0 && $nbOfPasses > 0} {
        putz $channel "\n\n=============== ALL TESTCASES PASSED ====================="
    } else {
        putz $channel "\n\n!!!!!!!!!!!!!!! SOME TESTCASES FAILED !!!!!!!!!!!!!!!!!!!!!"
    }

    return
}


# proc setModList {}
# Purpose: Creates a test-case list for all modules under consideration.
#          The list contains the subdirectories.
#
# Inputs:
#        modListName   -> Name of the module list in the original calling script.
#        singleMod     -> Flag specifying a single module is simulated.
#        singleModName -> Module name if a single module is used.
#        moduleDir     -> Modules directory location.
#
# Outputs: appends a list of one or more module names to the mod list specified by modListName.
proc setModList {modListName singleMod singleModName moduleDir} {
    puts_debug2 "==============utils::setModList================\n"
    upvar 1 $modListName modList

    if {$singleMod > 0} {
        lappend modList $moduleDir/$singleModName
    } else {
        if {[catch {listDir "$moduleDir/tc*"} result]} {
            puts stderr "\n\n No test-case directories were found.\n\n"
        } else {
            foreach tCase $result {
                lappend modList $tCase
            }
        }
    }

    return
}

# proc createSuperList {}
# Purpose: Creates superlist of all testcases, excluding those that have
#          been ignored in regression_settings. The list is saved to a file
#          where later runs of run_regression can claim testcases.
#
# Inputs:
#        singleMod     -> Flag specifying a single module is simulated.
#        singleModName -> Module name if a single module is used.
#        noDelete      -> Do not delete result_rtl; used by the regenerate
#                           reports function.
#
# Superlist format:
#     <testcase path>|<Available or Taken or Passed or Failed>
#
#
# Outputs: Creates a superlist in file according to SUPERLISTNAME
proc createSuperList {singleMod singleModName noDelete} {
    puts_debug2 "==============utils::createSuperList================\n"
    set fp_lock [acquireSuperlistLock]
    # Locked access begins

    set modDirList ""
    set tcList ""

    puts stdout "Generating superlist in regression_results:"


    set extraTestcaseDirs [getExternalTestcaseDirs]
    # Add extra testcase directories if specified
    foreach extraTestcase $extraTestcaseDirs {
        set modDirList_temp ""
        setModList modDirList_temp $singleMod $singleModName $extraTestcase
        set modDirList [concat $modDirList $modDirList_temp]
    }

    # Go through each dirctory and find testcases
    foreach tcDir $modDirList {
        if {[catch {listDir "$tcDir/tc*.tcl"} result]} {
            # No testcases in that directory.
        } else {
            set tcIgnoreList [getRegressionTCIgnoreList $tcDir]
            foreach tCase $result {
                # Adds full relative path
                if {[lsearch $tcIgnoreList $tCase] < 0} {
                    lappend tcList $tCase
                    puts stdout "Found testcase: $tCase"
                } else {
                    # Just ignore.
                }
            }
        }

        # Clear previous results for the module.
        set simResSubdir $tcDir/result_rtl
        if {[file exists $simResSubdir] && $noDelete == 0} {
            if [catch [file delete -force $simResSubdir] result] {
                puts stderr "Could not delete the result_rtl directory.\n"
                puts stderr $result
            } else {
                puts stdout "Deleted the result_rtl directory."
            }
        }
    }

    # Write superlist
    set fp [open $::SUPERLISTNAME w]
    foreach tc $tcList {
        puts $fp "$tc|start_time|end_time|duration|Available"
    }
    close $fp

    # Locked access ends
    releaseSuperlistLock $fp_lock

    puts stdout ""
}

# proc acquireSuperlistLock {}
# Purpose: Creates exclusive lock file. No other process can acquire it until
#          it is deleted. The open function succeeds when the lock file does not
#          already exist. Otherwise it loops and retries.
#
# Outputs: Creates a superlist lockfile when it becomes available.
proc acquireSuperlistLock {} {
    puts_debug2 "==============utils::acquireSuperlistLock================\n"
    if {![file isdirectory [file dirname $::SUPERLISTLOCK]]} {
        file mkdir [file dirname $::SUPERLISTLOCK]
    }
    # Loop until lock is acquired.
    while {1} {
        if {![catch {open $::SUPERLISTLOCK {WRONLY CREAT EXCL}} fp_lock]} {
            return $fp_lock
        }
    }
}

# proc releaseSuperlistLock {}
# Purpose: Releases lock file by deleting it.
proc releaseSuperlistLock {fp_lock} {
    puts_debug2 "==============utils::releaseSuperlistLock================\n"
    close $fp_lock
    file delete -force $::SUPERLISTLOCK
}

# proc getAvailableTestcase {}
# Purpose: Aquires testcase file with locking, and claims a test case if available.
#
# Outputs:
#   return value:   testcase path
#                   or 'NONE' if none found
#   last:           set to 1 if this is the last testcase (for merging),
#                   set to 0 otherwise
proc getAvailableTestcase {last} {
    puts_debug2 "==============utils::getAvailableTestcase================\n"
    upvar 1 $last _last

    set fp_lock [acquireSuperlistLock]
    # Locked access begins

    # Read superlist - return NONE if it has been removed.
    if {[catch  {open $::SUPERLISTNAME r} fp_list]} {
        # Locked access ends
        releaseSuperlistLock $fp_lock

        set _last 0
        return NONE
    }
    set list_data [read $fp_list]
    close $fp_list

    # Get all "Available" testcases
    set tc_avail [regexp -all -inline -line {^.*\|Available$} $list_data]
    if {[llength $tc_avail] == 0} {
        # Locked access ends
        releaseSuperlistLock $fp_lock

        set _last 0
        return NONE
    } elseif {[llength $tc_avail] == 1} {
        set _last 1
    } else {
        set _last 0
    }

    # Get first testcase's path
    set tcPath [regexp -inline -line {^.*?\|} [lindex $tc_avail 0]]
    # Remove trailing '|'
    set tcPath [string trimright $tcPath "|"]
    # Sanitize for regular expression matching
    set tcPathClean [string map {/ \\/ . \\. - \\-} $tcPath]
    # Replace Available with Taken in superlist by substituting the line.
    # Replace start_time with ISO 8601 UTC datetime
    set start_time [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
    set list_data [regsub -line "^$tcPathClean\\|start_time\\|end_time\\|duration\\|Available$" $list_data "$tcPath|$start_time|end_time|duration|Taken"]

    # Write superlist with updated testcase
    set fp_list [open $::SUPERLISTNAME w]
    puts -nonewline $fp_list $list_data
    close $fp_list

    # Locked access ends
    releaseSuperlistLock $fp_lock

    return $tcPath
}

# proc superlistPassFail {}
# Purpose: Update superlist with pass or fail.
#
# Inputs:
#       pass: 1 for pass, 0 for fail, -1 for not complete
#       warning: 0 for none, 1 for warnings
#       tcPath: path of testcase
proc superlistPassFail {pass warning tcPath} {
    puts_debug2 "==============utils::superlistPassFail================\n"
    set fp_lock [acquireSuperlistLock]
    # Locked access begins

    # Read superlist - return NONE if it has been removed.
    if {[catch  {open $::SUPERLISTNAME r} fp_list]} {
        # Locked access ends
        releaseSuperlistLock $fp_lock
        return
    }
    set list_data [read $fp_list]
    close $fp_list

    if {$pass == 1} {
        set tcStatus "Pass"
    } elseif {$pass == 0} {
        set tcStatus "Fail"
    } elseif {$pass == -1} {
        set tcStatus "Did Not Complete"
    } else {
        set tcStatus "Invalid Status"
    }
    if {$warning == 1} {
        append tcStatus " -- With Warnings"
    }
    # Sanitize for regular expression matching
    set tcPathClean [string map {/ \\/ . \\. - \\-} $tcPath]
    # Replace Taken with Pass/Fail in superlist by substituting the line.
    # Replace end_time with ISO 8601 UTC datetime
    set end_time [clock format [clock seconds] -gmt 1 -format "%Y-%m-%dT%H:%M:%SZ"]
    # Read start time and calculate duration
    # Start time is the second column.
    set data_cols [split [regexp -line -inline "^$tcPathClean.*$" $list_data] "|"]
    set start_time [clock scan [lindex $data_cols 1] -format "%Y-%m-%dT%H:%M:%SZ"]
    set duration [expr [clock scan $end_time -format "%Y-%m-%dT%H:%M:%SZ"] - $start_time]
    # Convert to hours minutes seconds format.
    set duration_string "[expr $duration / 3600]h "
    set duration [expr $duration - ($duration / 3600)*3600]
    append duration_string "[expr $duration / 60]m "
    set duration [expr $duration - ($duration / 60)*60]
    append duration_string "[expr $duration]s"
    # Update superlist content
    set list_data [regsub -line "(^$tcPathClean.*\\|)end_time\\|duration\\|Taken$" $list_data "\\1$end_time|$duration_string|$tcStatus"]

    # Write superlist with updated testcase
    set fp_list [open $::SUPERLISTNAME w]
    puts -nonewline $fp_list $list_data
    close $fp_list

    # Locked access ends
    releaseSuperlistLock $fp_lock
}

# proc superlistWaitOnCompletion {}
# Purpose: Polls the superlist unil all testcases have been completed, then returns.
#
proc superlistWaitOnCompletion {} {
    puts_debug2 "==============utils::superlistWaitOnCompletion================\n"
    while {1} {
        set fp_lock [acquireSuperlistLock]
        # Locked access begins

        # Read superlist - return if it has been removed.
        if {[catch  {open $::SUPERLISTNAME r} fp_list]} {
            # Locked access ends
            releaseSuperlistLock $fp_lock
            return
        }
        set list_data [read $fp_list]
        close $fp_list

        # Locked access ends
        releaseSuperlistLock $fp_lock


        # If there are no taken or available cases, the regression is done..
        if {[regexp -line "\\|Taken$" $list_data] == 0} {
            if {[regexp -line "\\|Available$" $list_data] == 0} {
                return
            }
        }
        puts stdout "Waiting for regression to complete..."
        # Sleep several seconds to avoid execessively holding the superlist lock.
        after 3000
    }
}

# proc runRegression {}
# Purpose: Run regression testing over a set of module directories.
#           Grabs testcases from the superlist and executes them until none are left.
# Inputs:
# Outputs: 1: if executed the last testcase -> triggers script to merge coverage
#               and show stats
#          0: otherwise
proc runRegression {} {
    puts_debug2 "==============utils::runRegression================\n"
    # Set when last testcase is taken to indicate coverage merging and final reporting
    # needs to take place.
    set is_last 0

    set ::REGRESSION yes


    # Loop broken when all testcases completed.
    # Keep track of last testcase, if it was in the same directory, don't recompile.
    set prev_modSubDir ""
    while {1} {
        set tcPath [getAvailableTestcase is_last]
        puts stdout "Executing TC  $tcPath"
        if {$tcPath eq "NONE"} {
            # No testcases left to execute.
            puts stdout "No test cases left to execute!!!. You might need to delete the Regression TC list file to start a fresh regression. \n"
            break
        }
        # Set local parameters.
        set modSubDir [file dirname $tcPath]
        # Save previous subdirectory. If it hasn't changed, don't recompile.
        if {$modSubDir == $prev_modSubDir} {
            set ::REGRESSION_COMPILE_ALL 0
        } else {
            set ::REGRESSION_COMPILE_ALL 1
        }
        set prev_modSubDir $modSubDir

        # Run testcase
        set current_tc [file rootname [file tail $tcPath]]
        source $modSubDir/$current_tc.tcl

        # Quit out of simulation, but do not kill simulator.
        eval $::SIMULATOR_QUIT

        # Get results -> Update superlist with pass/fail
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


        # When last testcase is completed, trigger the run_regression.tcl script to
        # merge all coverage and report final results.
        if {$is_last == 1} {
            break;
        }
    }

    unset -nocomplain ::REGRESSION_COMPILE_ALL
    unset ::REGRESSION

    return $is_last
}


# proc parseResAll {}
# Purpose: Procedure to parse regression results for multiple modules and report pass or fail
#          status for the complete run.
# Inputs:
#        modList        --> List of module directory names, where regression log files are expected
#                           to reside.
#        resultsLogPath --> Path to the results file to save to.
# Outputs: none.
proc parseResAll {modList resultsLogPath} {
    puts_debug2 "==============utils::parseResAll================\n"
    # Parse logs, report recursion PASS/FAIL status.
    # Prepare regression results log file for writing.
    set parseId 0
    catch {file delete -force $resultsLogPath.log}
    if [catch {open $resultsLogPath.log w} parseId] {
        puts stderr "Regression failed. Could not open $resultsLogPath.log for writing"
        return
    }
    putz $parseId "\n\n"

    # Initialize regressionStatsArray
    set regressionStatsArray(passListModuleLevel)      ""
    set regressionStatsArray(failListModuleLevel)      ""

    # Analyze all log files.
    foreach item $modList {
        set logName $item/result_rtl/regression_results.log
        parseRegLog $logName regressionStatsArray passListModuleLevel failListModuleLevel
    }

    # Print final analysis results.
    sumUpResultsAll $parseId regressionStatsArray

    # Close log file.
    close $parseId
}


#* -----------------------------Outline--------------------------------
#  --------------------------------*-----------------------------------
#######################################################################
# Local Variables:
# mode: outline-minor
# outline-regexp: " *#\\*"
# End:
