#!/bin/bash
#
# Run netgen on striVe_spi
#
PDK_PATH=/home/tim/projects/efabless/tech/SW
# PDK_PATH=/ef/tech/SW

NETGEN_SETUP=${PDK_PATH}/EFS8A/libs.tech/netgen/EFS8A_setup.tcl

netgen -batch lvs "../spi/lvs/striVe_spi.spice striVe_spi" "../verilog/gl/striVe_spi.synthesis.v striVe_spi" ${NETGEN_SETUP} striVe_spi_comp.out -json | tee striVe_spi_lvs.log
