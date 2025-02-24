# -----------------------------------------------------------------------//
#
# Copyright (C) 2006-2023 Fidus Systems Inc. 
# SPDX-License-Identifier: Apache-2.0 OR MIT
# The licenses stated above take precedence over any other contracts, agreements, etc.
#
# Project       : simu
# Author        : Xianxin Du
# Created       : 2021-06-04
# ----------------------------------------------------------------------//
# ----------------------------------------------------------------------//
# Description   : Module-wide compilation commands used by test-case
#                 simulation scripts for VHDL.
# Updated       : date / author - comments
# ----------------------------------------------------------------------//

puts stdout "==============compile_all.tcl================.\n"

# ##########################################################################################
# Add your code to compile your module level testbench and module level test case here.
# ##########################################################################################
# When no-compile is specified, only the testcase is recompiled.
if {$::CMD_ARG_COMPILE > 0} {

# source path to osvvm repo
set OSVVM_DIR "$SIMDIR/bfms/osvvm"

# create libraries
ensure_fresh_lib "$SIMDIR/run/osvvm_libs/osvvm" osvvm
ensure_fresh_lib "$SIMDIR/run/osvvm_libs/osvvm_common" osvvm_common
ensure_fresh_lib "$SIMDIR/run/osvvm_libs/osvvm_uart" osvvm_uart

# main library files
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/NamePkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/OsvvmGlobalPkg.vhd"
# Compile VendorCovApiPkg_Aldec.vhd for RivieraPro and ActiveHDL, otherwise compile VendorCovApiPkg.vhd
# if {[info exists aldec]} {
#   simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/VendorCovApiPkg_Aldec.vhd"
# } else {
  simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/VendorCovApiPkg.vhd"
# }
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/TranscriptPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/TextUtilPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/AlertLogPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/MessagePkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/SortListPkg_int.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/RandomBasePkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/RandomPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/CoveragePkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/MemoryPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/ScoreboardGenericPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/ScoreboardPkg_slv.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/ScoreboardPkg_int.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/ResolutionPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/TbUtilPkg.vhd"
simu_vcom -2008 -work osvvm "$OSVVM_DIR/osvvm/OsvvmContext.vhd"

# common library files OSVVM_Common
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/StreamTransactionPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/AddressBusTransactionPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/AddressBusResponderTransactionPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/AddressBusVersionCompatibilityPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/ModelParametersPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/FifoFillPkg_slv.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/InterruptHandler.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/InterruptHandlerComponentPkg.vhd"
simu_vcom -2008 -work osvvm_common "$OSVVM_DIR/Common/src/OsvvmCommonContext.vhd"

# UART IP library
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartTbPkg.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/ScoreboardPkg_Uart.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartTxComponentPkg.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartRxComponentPkg.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartContext.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartTx.vhd"
simu_vcom -2008 -work osvvm_uart "$OSVVM_DIR/UART/src/UartRx.vhd"

simu_vcom -2008 -cover "$OSVVM_DIR/UART/testbench/TestCtrl_e.vhd"

simu_vcom -2008 -cover "$TCSUBDIR/tb.vhd"

}

# TC
eval $TC_COMP_INVOCATION_VHDL

# ##########################################################################################
