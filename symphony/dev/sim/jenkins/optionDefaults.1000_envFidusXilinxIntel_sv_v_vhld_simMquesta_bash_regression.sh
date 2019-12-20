cd ../run
. ../jenkins/setting_licenses_all.sh
echo ">>> Licenses are set"
echo $LM_LICENSE_FILE

. ../jenkins/setting_mentor_questa.sh
echo ">>> Mentor Questa is set"
cd ../run
which vsim

cp -f ../jenkins/config_options/optionDefaults/* ../scripts_config/
cp -f ../jenkins/config_options/optionDefaults.1000/* ../scripts_config/
echo ">>> Default config scripts are copied over"

cd ../run
rm -rf ../regression_results
echo ">>> Cleaned the regression folder manually"
echo ">>> Starting regression"
vsim -c -do ../scripts_config/run_regression.tcl -do exit
echo ">>> Jenkins regression completed <<<"




