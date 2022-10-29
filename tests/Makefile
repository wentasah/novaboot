TESTS := novaboot.wv parser.wv expect.wv server.wv server-ssh.bats
OTHER_TESTS := $(filter-out $(TESTS),$(wildcard *.wv))
TESTS += $(OTHER_TESTS)

all:
	bats $(TESTS:%=./%)
