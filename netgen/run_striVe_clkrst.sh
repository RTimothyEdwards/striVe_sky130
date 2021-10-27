#!/bin/bash
#
# Run netgen on striVe_clkrst
#
PDK_PATH=/home/tim/projects/efabless/tech/SW
# PDK_PATH=/ef/tech/SW

NETGEN_SETUP=${PDK_PATH}/EFS8A/libs.tech/netgen/EFS8A_setup.tcl

netgen -batch lvs "../spi/lvs/striVe_clkrst.spice striVe_clkrst" "../verilog/gl/striVe_clkrst.synthesis.v striVe_clkrst" ${NETGEN_SETUP} striVe_clkrst_comp.out -json | tee striVe_clkrst_lvs.log
