all:
	./wvtestrun $(MAKE) run-all

run-all: novaboot.wv parser.wv expect.wv *.wv

.PHONY: $(wildcard *.wv)

*.wv:
	./$@
