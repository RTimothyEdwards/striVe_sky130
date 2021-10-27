#!/bin/tcsh -f
#-------------------------------------------
# qflow exec script for project ~/gits/openstriVe/qflow/ring_osc2x13
#-------------------------------------------

/ef/efabless/share/qflow/scripts/yosys.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 ~/gits/openstriVe/qflow/ring_osc2x13/source/ring_osc2x13.v || exit 1
# /ef/efabless/share/qflow/scripts/graywolf.sh -d ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/vesta.sh  ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/qrouter.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/vesta.sh  -d ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/magic_db.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/magic_drc.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/netgen_lvs.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/magic_gds.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/cleanup.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/cleanup.sh -p ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
# /ef/efabless/share/qflow/scripts/magic_view.sh ~/gits/openstriVe/qflow/ring_osc2x13 ring_osc2x13 || exit 1
