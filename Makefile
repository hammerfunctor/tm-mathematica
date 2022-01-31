
###############################################################################
# MODULE    : Make file for a new mathematica plugin
# COPYRIGHT : (C) 2005  Andrey Grozin
# COPYRIGHT : (C) 2021 Hammer Hu
# LICENCE   : This software falls under the GNU general public license;
#             see the file 'LICENSE', which is provided with this package.
###############################################################################

# WSPATH needed, which is compilation additions of Wolfram system
CXXFLAGS = -I$(WSPATH) -L$(WSPATH) -Wl,-rpath,$(WSPATH) -std=c++2a

ifeq ($(shell uname),Darwin)
	CXXFLAGS += -lWSTPi4 -lc++ -framework Foundation
else ifeq ($(shell uname),Linux)
	CXXFLAGS += -Wl,--gc-sections -lpthread -lWSTP64i4 -lrt -lm -ldl -luuid 
endif

all: bin/tm_mma.bin

bin/tm_mma.bin: src/tm_mathematica_wstp.cxx | bin
	${CXX} -m64 -o $@ $< $(CXXFLAGS)

bin:
	mkdir -p bin

clean:
	rm bin/tm_mma.bin
