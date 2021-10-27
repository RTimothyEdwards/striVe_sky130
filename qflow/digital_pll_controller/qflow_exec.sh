#!/bin/tcsh -f
#-------------------------------------------
# qflow exec script for project ~/projects/efabless/design/striVe/qflow/digital_pll_controller
#-------------------------------------------

# /usr/local/share/qflow/scripts/yosys.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller ~/projects/efabless/design/striVe/qflow/digital_pll_controller/source/digital_pll_controller.v || exit 1
# /usr/local/share/qflow/scripts/graywolf.sh -d ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/opensta.sh  ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
/usr/local/share/qflow/scripts/qrouter.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/opensta.sh  -d ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/magic_db.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/magic_drc.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/netgen_lvs.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/magic_gds.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/cleanup.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/cleanup.sh -p ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
# /usr/local/share/qflow/scripts/magic_view.sh ~/projects/efabless/design/striVe/qflow/digital_pll_controller digital_pll_controller || exit 1
