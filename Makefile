DESTDIR=
PREFIX=/usr

all:

README.md: novaboot
	pod2markdown $< > $@

install:
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 novaboot $(DESTDIR)$(PREFIX)/bin
	install -d $(DESTDIR)$(PREFIX)/share/man/man1/
	pod2man novaboot $(DESTDIR)$(PREFIX)/share/man/man1/novaboot.1
	install -d $(DESTDIR)/etc/sudoers.d
	install -m 440 sudoers.novaboot $(DESTDIR)/etc/sudoers.d/novaboot

test:
	$(MAKE) -C tests
