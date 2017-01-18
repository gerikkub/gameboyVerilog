

FILES = alu_mod alu reg_file pc_mod

TARGETS = $(addprefix bin/, $(addsuffix _sim, $(basename $(FILES))))

#SRCS = $(addprefix srcs/, $(addsuffix .v, $(basename $(FILES))))
#SIMS = $(addprefix sims/, $(addsuffix _sim.v, $(basename $(FILES))))

SIMS_DIR = sims

all : $(TARGETS)

bin/% : $(SIMS_DIR)/%.v
	iverilog -o $@ $<


