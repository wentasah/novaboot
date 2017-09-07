all: adduser-novaboot.8 novaboot-shell.1

adduser-novaboot.8: adduser-novaboot
	pod2man --section=8 --center="System Manager's Manual" $< $@

novaboot-shell.1: novaboot-shell
	pod2man --center="User commands" $< $@
