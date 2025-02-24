puts "==============proj_paths.tcl================\n"


set HLSPROJNAME axi4_sqrt
set HLSPROJDIR_FROMSCRIPTS ../../vitis
set HLSPROJDIR_FROMPROJ .
set HLSSOURCESDIR_FROMPROJ ../../sources_hls

# if the HLS TC variables are not accessible inside Vitis then use the auto-generated paths script
if {![info exists ::TCTYPE]} {
    puts "---------> Atempting to add SIMU TC paths default file to run inside Vitis..."
    #if {[info exists ::SCRIPTSDIR/simu_paths_autogen.tcl]} {
    #  puts "---------> Adding SIMU TC paths auto-generated to run inside Vitis - autogen file exists"
        source $::SCRIPTSDIR/autogen_simu_paths.tcl
    #}
}