

FILES = alu_mod alu reg_file pc_mod sp_mod microcode_mod memory_rom

TARGETS = $(addprefix bin/, $(addsuffix _sim, $(basename $(FILES))))

#SRCS = $(addprefix srcs/, $(addsuffix .v, $(basename $(FILES))))
#SIMS = $(addprefix sims/, $(addsuffix _sim.v, $(basename $(FILES))))

SIMS_DIR = sims

all : $(TARGETS)

bin/% : $(SIMS_DIR)/%.v
	mkdir -p bin
	iverilog -o $@ $<

clean:
	rm -r bin


