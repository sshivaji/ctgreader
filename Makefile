PREFIX = /usr
BINDIR = $(PREFIX)/bin
EXE = ctg_reader

GCCFLAGS = --std=c99
CC = gcc $(GCCFLAGS)

ARCHFLAGS = -m32
COMMONFLAGS = -Wall -Wextra -Wno-unused-function $(ARCHFLAGS) -Igtb
LDFLAGS = $(ARCHFLAGS) -ldl  -lpthread
DEBUGFLAGS = $(COMMONFLAGS) -g -O0 -DEXPENSIVE_CHECKS -DASSERT2
ANALYZEFLAGS = $(COMMONFLAGS) $(GCCFLAGS) -g -O0
DEFAULTFLAGS = $(COMMONFLAGS) -g -O2
OPTFLAGS = $(COMMONFLAGS) -O3 -DNDEBUG
PGO1FLAGS = $(OPTFLAGS) -fprofile-generate
PGO2FLAGS = $(OPTFLAGS) -fprofile-use
CFLAGS = $(DEFAULTFLAGS)

DBGCOMPILESTR = -DCOMPILE_COMMAND=\"\\\"`basename $(CC)` $(DEBUGFLAGS)\\\"\"
OPTCOMPILESTR = -DCOMPILE_COMMAND=\"\\\"`basename $(CC)` $(OPTFLAGS)\\\"\"
PGOCOMPILESTR = -DCOMPILE_COMMAND=\"\\\"`basename $(CC)` $(PGO2FLAGS)\\\"\"
DFTCOMPILESTR = -DCOMPILE_COMMAND=\"\\\"`basename $(CC)` $(DEFAULTFLAGS)\\\"\"

GITFLAGS = -DGIT_VERSION=\"\\\"`git rev-parse --short HEAD`\\\"\"

SRCFILES := $(wildcard *.c)
HEADERS  := $(wildcard *.h)
OBJFILES := $(SRCFILES:.c=.o)
PROFFILES := $(SRCFILES:.c=.gcno) $(SRCFILES:.c=.gcda)

.PHONY: all clean gtb tags debug opt pgo-start pgo-finish pgo-clean
.DEFAULT_GOAL := default

debug:
	$(MAKE) $(EXE) \
	    CFLAGS="$(DEBUGFLAGS) $(GITFLAGS) $(DBGCOMPILESTR)"

default:
	$(MAKE) $(EXE) \
	    CFLAGS="$(DEFAULTFLAGS) $(GITFLAGS) $(DFTCOMPILESTR)"

opt:
	$(MAKE) $(EXE) \
	    CFLAGS="$(OPTFLAGS) $(GITFLAGS) $(OPTCOMPILESTR)"

pgo-start:
	$(MAKE) $(EXE) \
	    CFLAGS="$(PGO1FLAGS) $(GITFLAGS) $(OPTCOMPILESTR)" \
	    LDFLAGS='$(LDFLAGS) -fprofile-generate'

pgo-finish:
	$(MAKE) $(EXE) \
	    CFLAGS="$(PGO2FLAGS) $(GITFLAGS) $(PGOCOMPILESTR)"

all: default


install: all
	-mkdir -p -m 755 $(BINDIR)
	-cp $(EXE) $(BINDIR)
	-strip $(BINDIR)/$(EXE)

uninstall:
	$(RM) $(BINDIR)/$(EXE)

ctg_reader: gtb $(OBJFILES)
	$(CC) $(OBJFILES) $(LDFLAGS) -o ctg_reader

clean:
	rm -rf .depend $(EXE) tags $(OBJFILES)

pgo-clean:
	rm -f $(PROFFILES)

.depend:
	$(CC) -MM $(DEFAULTFLAGS) $(SRCFILES) > $@

include .depend


