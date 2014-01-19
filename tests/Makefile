all:
	./wvtestrun $(MAKE) run-all

run-all: novaboot.wv *.wv

.PHONY: $(wildcard *.wv)

*.wv:
	./$@
