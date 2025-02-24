cd ../run
. ../jenkins/setting_licenses_all.sh
echo ">>> Licenses are set"
echo $LM_LICENSE_FILE

. ../jenkins/setting_xilinx_vivado.sh
echo ">>> Xilinx Vivado is set"
cd ../run
which vivado


tclsh ./create_dependencies_XvivadoAxiVip.tcl
echo ">>> Jenkins Vivado AXI-VIP project dependencies build completed <<<"

tclsh ./create_dependencies_XvivadoIPI.tcl
cd ../run
echo ">>> Jenkins Vivado IPI & AXI-VIP project dependencies build completed <<<"
echo ">>> Jenkins !!!If Required then Compile Questa Simulation Libraries as well to use them!!! <<<"

