onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/test_case_inst/slave_sda
add wave -noupdate /tb/test_case_inst/slave_scl
add wave -noupdate /tb/test_case_inst/i2c_master_if/scl_in
add wave -noupdate /tb/test_case_inst/i2c_master_if/scl_out
add wave -noupdate /tb/test_case_inst/i2c_master_if/scl_t
add wave -noupdate /tb/test_case_inst/i2c_master_if/sda_in
add wave -noupdate /tb/test_case_inst/i2c_master_if/sda_out
add wave -noupdate /tb/test_case_inst/i2c_master_if/sda_t
add wave -noupdate /tb/test_case_inst/i2cSlave/clk
add wave -noupdate /tb/test_case_inst/i2cSlave/sda
add wave -noupdate /tb/test_case_inst/i2cSlave/scl
add wave -noupdate /tb/test_case_inst/i2cSlave/sdaOut
add wave -noupdate /tb/test_case_inst/i2cSlave/startStopDetState
add wave -noupdate /tb/test_case_inst/i2cSlave/startEdgeDet
add wave -noupdate /tb/test_case_inst/i2cSlave/sclDeb
add wave -noupdate /tb/test_case_inst/i2cSlave/sdaDelayed
add wave -noupdate /tb/test_case_inst/i2cSlave/sdaPipe
add wave -noupdate /tb/test_case_inst/i2cSlave/sclPipe
add wave -noupdate /tb/test_case_inst/i2cSlave/regAddr
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/startStopDetState
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/CurrState_SISt
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/next_streamSt
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/scl
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/next_regAddr
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/dataOut
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/rxData
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/bitCnt
add wave -noupdate /tb/test_case_inst/end_wr
add wave -noupdate -divider {New Divider}
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg4
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg5
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg6
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg7
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg0
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg1
add wave -noupdate /tb/test_case_inst/i2cSlave/myReg2
add wave -noupdate /tb/test_case_inst/i2cSlave/u_registerInterface/dataOut
add wave -noupdate /tb/test_case_inst/i2cSlave/u_registerInterface/addr
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/next_regAddr
add wave -noupdate /tb/test_case_inst/i2cSlave/u_registerInterface/dataIn
add wave -noupdate /tb/test_case_inst/i2cSlave/u_registerInterface/writeEn
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/CurrState_SISt
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/NextState_SISt
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/bitCnt
add wave -noupdate /tb/test_case_inst/i2cSlave/u_serialInterface/rxData
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {236601000 ps} 0} {{Cursor 3} {68321000 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 382
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {117864868 ps} {118658905 ps}
