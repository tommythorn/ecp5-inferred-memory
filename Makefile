all: memory.config

%.json: memory.v
	yosys -p "synth_ecp5 -json $@" -Ddut=$(basename $@) memory.v 2>&1 | tee $(basename $@).sys.out

%.config: %.json
	nextpnr-ecp5 --json $< --lpf OrangeCrab.lpf --textcfg $@ --85k --package CSFBGA285 --speed 6 2>&1 | tee $(basename $@).pnr.out
	@printf "%-20s %s\n" $(basename $@) "`egrep -o ': [0-9\.]+ MHz' $(basename $@).pnr.out|tail -1`"
