cd ..\run
REM This is a comment
REM . ../jenkins/setting_licenses_all.sh
echo ">>> Licenses are set"
echo %LM_LICENSE_FILE%

copy ..\jenkins\config_options\optionDefaults\*.* ..\scripts_config\
echo ">>>optionDefaults config scripts are copied over"
copy ..\jenkins\config_options\optionDefaults.0010\*.* ..\scripts_config\
echo ">>> optionDefaults.0010 config scripts are copied over"


cd ..\run
del /Q /f ..\regression_results\*.*
echo ">>> Cleaned the regression folder manually"
echo ">>> Starting regression"
REM call manually w:\windows_tools\lattice\lscc\diamond\3.10_x64\active-hdl\bin\vsimsa.exe
REM or have vsimsa.bat in your path and run
REM vsimsa -do ../scripts_config/run_regression.tcl
vsimsa -do ../scripts_config/run_regression.tcl
echo ">>> Jenkins regression completed <<<"




