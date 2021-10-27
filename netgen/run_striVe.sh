#!/bin/bash
#
# Run netgen on striVe (top level)
#
PDK_PATH=/home/tim/projects/efabless/tech/SW
# PDK_PATH=/ef/tech/SW

NETGEN_SETUP=${PDK_PATH}/EFS8A/libs.tech/netgen/EFS8A_setup.tcl

netgen -batch lvs "../spi/lvs/striVe.spice striVe" "../verilog/rtl/striVe.v striVe" ${NETGEN_SETUP} striVe_comp.out -json | tee striVe_lvs.log
