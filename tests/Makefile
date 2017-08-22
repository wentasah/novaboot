TESTS := novaboot.wv parser.wv expect.wv server.wv
OTHER_TESTS := $(filter-out $(TESTS),$(wildcard *.wv))
TESTS += $(OTHER_TESTS)

all:
	./wvtool runall $(TESTS:%=./%)
