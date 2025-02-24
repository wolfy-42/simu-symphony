cd ../run
echo ">>> Calling ../jenkins/optionBuild_dependencies_Xvivado_bash.sh"
. ../jenkins/optionBuild_dependencies_Xvivado_bash.sh
cd ../run

cp -f ../jenkins/config_options/optionDefaults/* ../scripts_config/
cp -f ../jenkins/config_options/optionXilinx.0010/* ../scripts_config/
echo ">>> optionXilinx.0100 config scripts are copied over"

cd ../run
rm -rf ../regression_results
echo ">>> Cleaned the regression folder manually"
echo ">>> Starting regression"
vivado -nolog -nojournal -notrace -mode batch -source ../scripts_config/run_regression.tcl
echo ">>> Jenkins regression completed <<<"




