PREFIX=/usr

all: adduser-novaboot.8 novaboot-shell.1

adduser-novaboot.8: adduser-novaboot.pod
	pod2man --section=8 --center="System Manager's Manual" $< $@

novaboot-shell.1: novaboot-shell.pod
	pod2man --center="User commands" $< $@

install: all
	install -D -m 755 -t $(DESTDIR)$(PREFIX)/bin novaboot-shell
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man1 novaboot-shell.1
	install -D -m 755 -t $(DESTDIR)$(PREFIX)/sbin adduser-novaboot
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/share/man/man8 adduser-novaboot.8
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/sysusers.d sysusers.d/novaboot-server.conf
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/systemd/system systemd/novaboot-power-off@.service
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/systemd/system systemd/novaboot-power-off@.timer
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/systemd/system systemd/novaboot-power@.service
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/systemd/user systemd/novaboot-delayed-power-off.service
	install -D -m 644 -t $(DESTDIR)$(PREFIX)/lib/systemd/user systemd/novaboot-delayed-power-off.target
	install -D -m 440 systemd/sudoers.novaboot-server $(DESTDIR)/etc/sudoers.d/novaboot-server
	install -D -m 755 -t $(DESTDIR)$(PREFIX)/sbin systemd/novaboot-power
