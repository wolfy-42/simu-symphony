#call simu library 
source ../scripts_config/run_simu.tcl
#clean previous regression results using simu function - uses modules white list function getExternalTestcaseDirs
#clean_simu
#cp ../regression_lists/REGRESSION_TC_LIST.txt ../regression_results/

#list of testcases for regression
source /home/work/des.v/trunk/simu_fixes/simu/dev/sim/testcases_envFidus_sv_simMquestaXvivado/tc_fidus_axis_video/tc_fidus_axis_video.tcl
source /home/work/des.v/trunk/simu_fixes/simu/dev/sim/testcases_envFidus_sv_simMquestaXvivado/tc_fidus_common/tc_fidus_axi4lite_mst.tcl
source /home/work/des.v/trunk/simu_fixes/simu/dev/sim/testcases_envFidus_sv_simMquestaXvivado/tc_fidus_common/tc_fidus_clock_reset.tcl

#process regression agregation and coverage agregation using simu functions - uses modules white list function getExternalTestcaseDirs
regression_results_parse
regression_results_print
regression_coverage_parse
regression_coverage_print