cd ../run
echo ">>> Calling ../jenkins/optionBuild_dependencies_Xvivado_Mquesta_bash.sh"
. ../jenkins/optionBuild_dependencies_Xvivado_bash.sh
. ../jenkins/optionBuild_dependencies_XvivadoMquestaSimLib_bash.sh
cd ../run

cp -f ../jenkins/config_options/optionDefaults/* ../scripts_config/
cp -f ../jenkins/config_options/optionXilinx.0000/* ../scripts_config/
echo ">>> optionXilinx.0000 config scripts are copied over"

cd ../run
rm -rf ../regression_results
echo ">>> Cleaned the regression folder manually"
echo ">>> Starting regression"
vsim -c -do ../scripts_config/run_regression.tcl -do exit
echo ">>> Jenkins regression completed <<<"




