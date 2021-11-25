
###############################################################################
# MODULE    : Make file for a new mathematica plugin
# COPYRIGHT : (C) 2005  Andrey Grozin
# COPYRIGHT : (C) 2021 Hammer Hu
# LICENCE   : This software falls under the GNU general public license;
#             see the file 'LICENSE', which is provided with this package.
###############################################################################

WSTP_PATH := /usr/local/Wolfram/Mathematica/12.3/SystemFiles/Links/WSTP/DeveloperKit/Linux-x86-64/CompilerAdditions

CXXFLAGS := -I$(WSTP_PATH) -L$(WSTP_PATH) -Wl,-rpath,$(WSTP_PATH) -lWSTP64i4 -lm -lrt -ldl -luuid -std=c++2a

ifeq ($(shell uname),Darwin)
	CXXFLAGS += -Wl,-dead-strip
else ifeq ($(shell uname),Linux)
	CXXFLAGS += -Wl,--gc-sections -lpthread
endif

all: bin/tm_mma.bin

bin/tm_mma.bin: src/tm_mathematica_wstp.cxx | bin
	${CXX} -m64 -o $@ $< $(CXXFLAGS)

bin:
	mkdir -p bin

clean:
	rm bin/tm_mma.bin
