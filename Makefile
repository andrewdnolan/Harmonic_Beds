# Names of the compiled executables used in .sif files
EXEC = bin/accumulation

all: $(EXEC)

# Compile the *.F90 files with `elmerf90` alias
bin/% : SRC/elmerlib/%.F90
	elmerf90 $< -o $@

# remove all the compiled code
clean:
	rm -f $(EXEC)
