cd ../run
. ../jenkins/setting_licenses_all.sh
echo ">>> Licenses are set"
echo $LM_LICENSE_FILE

. ../jenkins/setting_intel_quartus.sh
echo ">>> Intel Quartus is set"
cd ../run
which qsys-generate


tclsh ./create_dependencies_IquartusQSys.tcl
cd ../run
echo ">>> Jenkins Intel Quartus project dependencies build completed <<<"

