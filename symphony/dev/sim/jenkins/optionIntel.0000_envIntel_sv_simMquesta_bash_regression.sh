cd ../run
echo ">>> Calling ../jenkins/optionBuild_dependencies_....sh"
. ../jenkins/optionBuild_dependencies_Iquartus_bash.sh
cd ../run

. ../jenkins/setting_mentor_questa.sh
echo ">>> Mentor Questa is set"
cd ../run
which vsim

cp -f ../jenkins/config_options/optionDefaults/* ../scripts_config/
cp -f ../jenkins/config_options/optionIntel.0000/* ../scripts_config/
echo ">>> optionIntel.0000 config scripts are copied over"

cd ../run
rm -rf ../regression_results
echo ">>> Cleaned the regression folder manually"
echo ">>> Starting regression"
vsim -c -do ../scripts_config/run_regression.tcl -do exit
echo ">>> Jenkins regression completed <<<"




