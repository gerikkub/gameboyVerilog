

TARGETS = alu_mod_sim alu_sim reg_file_sim



FILES = $(addprefix sims/, $(addsuffix .v, $(basename $(SOURCES))))

SIMS_DIR = sims

all : $(TARGETS)

% : $(SIMS_DIR)/%.v
	iverilog -o $@ $<


