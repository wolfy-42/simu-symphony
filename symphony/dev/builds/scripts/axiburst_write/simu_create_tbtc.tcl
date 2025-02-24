puts "==============simu_create_tbtc.tcl================\n"

# TB & TC added to project (single TC only, TC is switched by the TCL scripts during execution)

set SCRIPTSDIR [pwd]
source proj_paths.tcl

cd $::HLSPROJDIR_FROMSCRIPTS

puts "----------> Open HLS project to add SIMU TB and TC ............................"
open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME
open_solution "solution1" -flow_target vivado

# add SIMU TBs and TCs HLS C++ 
puts "---------> Add SIMU TB & TC from TC folder > $::TCSUBDIR ................."
source $::TCSUBDIR/tbtc_add.tcl



#apply_ini ::SCRIPTSDIR/simu_config_tbtc.ini
puts "----------> Writing SIMU HLS TB/TC Config ............................"
write_ini $::SCRIPTSDIR/backup_simu_config_tbtc.cfg -all=true

puts "---------> SIMU TB & TC added to project, project closed .............."

cd $::SCRIPTSDIR
puts "---------> Back to scripts folder..............after SIMU TB and TC are added to project > $::SCRIPTSDIR"


exit
