TESTS=$(shell find -name '*.wv')

all:
	./wvtestrun $(MAKE) run-all

run-all:
	$(foreach t,$(TESTS),$(t); )
