# Structure

- input
	- block1
		- config.tcl
		- interactive.tcl
- runs
	- block1

Under inputs each block(i.e. digital_pll) has it own folder. Inside each folder there is a config file and interactive script to run that block

Openlane runs are placed in runs folder. By default the run is name after the block itself

# Make


First, define `OPENLANE_ROOT` enviornmet variable (or set it in the beginning of the makefile). In your shell enter:

```
export OPENLANE_ROOT=<your openlane installation root directory>
```

## Targets

- `make all`
	- runs all the blocks inside the `input` folder (making sure that the chip, striVe, is the last one)
- `make <block>`
	- runs a single block
- `make clean_all`
	- remove folders inside runs directory and any lefs or gds produced for it
- `make clean-<block>`
	- remove a design run folder and any lefs or gds produced for it
