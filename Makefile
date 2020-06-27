SPEEDGRADE=6 # My OC is -6. 8 is the fastest available (85G?)

all: memory.config # cache.config # 

%.json: memory.v
	yosys -p "synth_ecp5 -json $@" -Ddut=$(basename $@) memory.v 2>&1 | tee $(basename $@).sys.out

%.config: %.json Makefile OrangeCrab.lpf
	nextpnr-ecp5 --seed 9 --json $< --lpf OrangeCrab.lpf --textcfg $@ --85k --package CSFBGA285 --speed $(SPEEDGRADE) 2>&1 | tee $(basename $@).pnr.out
	@printf "%-20s %s\n" $(basename $@) "`egrep -o ': [0-9\.]+ MHz' $(basename $@).pnr.out|tail -1`"
