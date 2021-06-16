# folder to store compiled files
BIN_DIR = bin
# folder with fortran source
SRC_DIR = SRC/elmerlib
# compiled executables used in .sif files
EXEC    = $(BIN_DIR)/accumulation

all: $(EXEC)

# compile the *.F90 files with the `elmerf90` alias
$(BIN_DIR)/% : $(SRC_DIR)/%.F90 $(BIN_DIR)
	elmerf90 $< -o $@ > /dev/null

# make the compiled dir if does not exist
$(BIN_DIR) :
	test ! -d $(BIN_DIR) && mkdir $(BIN_DIR)

# remove all the compiled code
clean:
	rm -f $(EXEC)
