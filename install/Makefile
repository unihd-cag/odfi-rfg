
## Config
SHELL=/bin/bash
MODULES = integration-mbuild tcl-integration dev-tcl dev-tcl-scenegraph dev-hw rfg dev-hw

## Main Target
all: odfi-manager/setup.linux.bash modules



## Load ODFI in environment
load_odfi:
	@echo "Loading ODFI"
	@. odfi-manager/setup.linux.bash

modules: load_odfi
	@$(foreach m,$(MODULES),. odfi-manager/setup.linux.bash ; echo "Installing $m"; odfi --install local.$m ;)



odfi-manager/setup.linux.bash:
	@echo "Installing ODFI manager"
	@git clone https://github.com/richnou/odfi-manager.git

## mrproper : Destroy everything (all folders apart from this Makefile)
mrproper:
	@echo "Cleaning folder completely (only makefile remains)"
	rm --preserve-root -Rf `ls --hide="Makefile"`

## modules
###################

