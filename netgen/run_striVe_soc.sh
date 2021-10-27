#!/bin/bash
#
# Run netgen on striVe_soc
#
PDK_PATH=/home/tim/projects/efabless/tech/SW
# PDK_PATH=/ef/tech/SW

NETGEN_SETUP=${PDK_PATH}/EFS8A/libs.tech/netgen/EFS8A_setup.tcl

netgen -batch lvs "../spi/lvs/striVe_soc.spice striVe_soc" "../verilog/gl/striVe_soc.synthesis.v striVe_soc" ${NETGEN_SETUP} striVe_soc_comp.out -json | tee striVe_soc_lvs.log
