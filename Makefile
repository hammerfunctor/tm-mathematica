
###############################################################################
# MODULE    : Make file for a new mathematica plugin
# COPYRIGHT : (C) 2005  Andrey Grozin
# COPYRIGHT : (C) 2021 Hammer Hu
# LICENCE   : This software falls under the GNU general public license;
#             see the file 'LICENSE', which is provided with this package.
###############################################################################

# WSPATH needed, which is compilation additions of Wolfram system
CXXFLAGS = -lm -lrt -ldl -luuid -std=c++2a\
					 -I$(WSPATH) -L$(WSPATH) -Wl,-rpath,$(WSPATH)

ifeq ($(shell uname),Darwin)
	CXXFLAGS += -Wl,-dead-strip -lWSTPi4
else ifeq ($(shell uname),Linux)
	CXXFLAGS += -Wl,--gc-sections -lpthread -lWSTP64i4
endif

all: bin/tm_mma.bin

bin/tm_mma.bin: src/tm_mathematica_wstp.cxx | bin
	${CXX} -m64 -o $@ $< $(CXXFLAGS)

bin:
	mkdir -p bin

clean:
	rm bin/tm_mma.bin
