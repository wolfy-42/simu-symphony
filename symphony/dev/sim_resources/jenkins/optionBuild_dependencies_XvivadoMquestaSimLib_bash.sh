cd ../run
. ../jenkins/setting_licenses_all.sh
echo ">>> Licenses are set"
echo $LM_LICENSE_FILE

. ../jenkins/setting_mentor_questa.sh
echo ">>> Mentor Questa is set"
cd ../run
which vsim

. ../jenkins/setting_xilinx_vivado.sh
echo ">>> Xilinx Vivado is set"
cd ../run
which vivado

tclsh ./create_dependencies_XvivadoMquestaSimLib.tcl
cd ../run
echo ">>> Jenkins Vivado  & Mentor Questa simulation libraries dependencies build completed <<<"

