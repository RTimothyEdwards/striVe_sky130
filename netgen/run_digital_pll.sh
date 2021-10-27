#!/bin/bash
#
# Run netgen on digital_pll
#
PDK_PATH=/home/tim/projects/efabless/tech/SW
# PDK_PATH=/ef/tech/SW

NETGEN_SETUP=${PDK_PATH}/EFS8A/libs.tech/netgen/EFS8A_setup.tcl

netgen -batch lvs "../spi/lvs/digital_pll.spice digital_pll" "../verilog/gl/digital_pll.synthesis.v digital_pll" ${NETGEN_SETUP} digital_pll_comp.out -json | tee digital_pll_lvs.log
