PREFIX=/usr

all: adduser-novaboot.8 novaboot-shell.1

adduser-novaboot.8: adduser-novaboot
	pod2man --section=8 --center="System Manager's Manual" $< $@

novaboot-shell.1: novaboot-shell
	pod2man --center="User commands" $< $@

install: all
	install -D -m 755 -t $(DESTDIR)$(PREFIX)/bin novaboot-shell
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man1 novaboot-shell.1
	install -D -m 755 -t $(DESTDIR)$(PREFIX)/sbin adduser-novaboot
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man8 adduser-novaboot.8
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/sysusers.d sysusers.d/novaboot-server.conf
	install -D -m 644 -t $(DESTDIR)/lib/systemd/system systemd/novaboot-target-off@.target
	install -D -m 644 -t $(DESTDIR)/lib/systemd/system systemd/novaboot-target-off@.timer
	install -D -m 644 -t $(DESTDIR)/lib/systemd/system systemd/novaboot-target-on@.service
	install -D -m 644 -t $(DESTDIR)/lib/systemd/system systemd/novaboot-server-session@.service
