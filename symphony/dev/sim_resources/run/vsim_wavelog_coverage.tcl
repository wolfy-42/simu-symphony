#wave log creation for vsim for all signals
log -r /* 
#run simulation until end
run -all
#Coverage report invocation .tcl prep
coverage report -output /home/work/des.v/trunk/simu/simu/dev/sim/testcases_envFidus_sv_simMquestaXvivadoCxcelium/tc_fidus_common/result_rtl/tc_fidus_clock_reset.coverage_report.rep
#Coverage database save invocation .tcl prep
coverage save /home/work/des.v/trunk/simu/simu/dev/sim/testcases_envFidus_sv_simMquestaXvivadoCxcelium/tc_fidus_common/result_rtl/tc_fidus_clock_reset.cov
#exit simulation
quit -sim
#exit simulation
exit
