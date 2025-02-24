puts "==============proj_create.tcl================\n"

# Create HLS project in Vitis 2023.2

set SCRIPTSDIR [pwd]
source proj_paths.tcl

cd $::HLSPROJDIR_FROMSCRIPTS

puts "----------> Create HLS project and adding HLS synthesizable sources (witout TB and TC) ............................"
open_project $::HLSPROJDIR_FROMPROJ/$::HLSPROJNAME

# Project config
puts "----------> Set HLS project parameters ............................"
open_solution "solution1" -flow_target vivado
set_part {xc7z020clg400-1} 
create_clock -period 10 -name default
#set_clock_uncertainty 0.5



###########################
### RTL HLS C++
puts "----------> Set HLS project name ............................"
set_top axi4_sqrt
puts "----------> Adding HLS synthesizable cpp ............................"
add_files $::HLSSOURCESDIR_FROMPROJ/axi4_sqrt.cpp
puts "----------> Adding HLS synthesizable cpp ............................"
add_files $::HLSSOURCESDIR_FROMPROJ/axi4_sqrt.hpp


puts "----------> Adding Synthesizable HLS Config ............................"
apply_ini $::SCRIPTSDIR/proj_create.cfg
puts "----------> Writing Synthesizable HLS Proj Creation Config ............................"
write_ini $::SCRIPTSDIR/backup_proj_create.cfg -all=true


###########################
### TBs and TCs HLS C++ (default or TC specific)
if {[file exists $::SCRIPTSDIR/autogen_simu_paths.tcl]} {
    puts stdout "---------> Not adding TB & TC names and paths, becuse, will be added later from simu_create_tbtc.tcl from TC folder > $::TCSUBDIR ................."
} else {
    puts "---------> Adding default TB & TC from proj_create.tcl > $::SCRIPTSDIR/..._default_tbtc.cpp ................."  
    add_files -tb $::HLSSOURCESDIR_FROMPROJ/axi4_sqrt_default_tbtc.cpp

    #puts "----------> Adding HLS Config ............................"
    #apply_ini $::SCRIPTSDIR/proj_config_tbtc.cfg
    puts "----------> Writing TB&TCHLS Proj Creation Config ............................"
    write_ini $::SCRIPTSDIR/backup_proj_tbtc.cfg 
}

cd $::SCRIPTSDIR
puts "----------> Back to scripts folder............................after project with syntesizable HLS is created > $::SCRIPTSDIR"

puts "---------> Project created, sythesizable HLS added to project, project closed .............."

exit

