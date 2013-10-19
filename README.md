# NAME

novaboot - A tool for booting various operating systems on various hardware or in qemu

# SYNOPSIS

__novaboot__ \[ options \] \[--\] script...

__./script__ \[ options \]

__novaboot__ --help

# DESCRIPTION

This program makes it easier to boot NOVA or other operating system
(OS) in different environments. It reads a so called novaboot script
and uses it either to boot the OS in an emulator (e.g. in qemu) or to
generate the configuration for a specific bootloader and optionally to
copy the necessary binaries and other needed files to proper
locations, perhaps on a remote server. In case the system is actually
booted, its serial output is redirected to standard output if that is
possible.

A typical way of using novaboot is to make the novaboot script
executable and set its first line to _\#!/usr/bin/env novaboot_. Then,
booting a particular OS configuration becomes the same as executing a
local program - the novaboot script.

With `novaboot` you can:

1. Run an OS in Qemu. This is the default action when no other action is
specified by command line switches. Thus running `novaboot ./script`
(or `./script` as described above) will run Qemu and make it boot the
configuration specified in the _script_.
2. Create a bootloader configuration file (currently supported
bootloaders are GRUB, GRUB2 and Pulsar) and copy it with all other
files needed for booting to another, perhaps remote, location.

        ./script --server --iprelay

    This command copies files to a TFTP server specified in the
    configuration file and uses TCP/IP-controlled relay to reset the test
    box and receive its serial output.

3. Run DHCP and TFTP server on developer's machine to PXE-boot NOVA from
it. E.g.

        ./script --dhcp-tftp

    When a PXE-bootable machine is connected via Ethernet to developer's
    machine, it will boot the configuration described in _script_.

4. Create bootable ISO images. E.g.

        novaboot --iso -- script1 script2

    The created ISO image will have GRUB bootloader installed on it and
    the boot menu will allow selecting between _script1_ and _script2_
    configurations.

# PHASES AND OPTIONS

Novaboot perform its work in several phases. Each phase can be
influenced by several options, certain phases can be skipped. The list
of phases with the corresponding options follows.

## Command line processing phase

- \-c, --config=<filename>

    Use a different configuration file than the default one (i.e.
    `~/.novaboot`).

- \--dump-config

    Dumps current configuration to stdout end exits. Useful as an initial
    template for a configuration file.

- \-h, --help

    Print short (__\-h__) or long (__\--help__) help.

- \-I

    This is an alias (see `%custom_options` below) defined in the default
    configuration. When used, it causes novaboot to use Michal's remotely
    controllable test bed.

- \-J

    This is an alias (see `%custom_options` below) defined in the default
    configuration. When used, it causes novaboot to use another remotely
    controllable test bed.

## Script preprocessing phase

This phases allows to modify the parsed novaboot script before it is
used in the later phases.

- \-a, --append=<parameters>

    Appends a string to the first "filename" line in the novaboot script.
    This can be used to append parameters to the kernel's or root task's
    command line.

- \-b, --bender

    Use `bender` chainloader. Bender scans the PCI bus for PCI serial
    ports and stores the information about them in the BIOS data area for
    use by the kernel.

- \--dump

    Prints the content of the novaboot script after removing comments and
    evaluating all _\--scriptmod_ expressions. Exit after reading (and
    dumping) the script.

- \--scriptmod=_perl expression_

    When novaboot script is read, _perl expression_ is executed for every
    line (in $\_ variable). For example, `novaboot
    --scriptmod=s/sigma0/omega6/g` replaces every occurrence of _sigma0_
    in the script with _omega6_.

    When this option is present, it overrides _$script\_modifier_ variable
    from the configuration file, which has the same effect. If this option
    is given multiple times all expressions are evaluated in the command
    line order.

- \--strip-rom

    Strip _rom://_ prefix from command lines and generated config files.
    The _rom://_ prefix is used by NUL. For NRE, it has to be stripped.

## File generation phase

In this phase, files needed for booting are generated in a so called
_build directory_ (see TODO). In most cases configuration for a
bootloader is generated automatically by novaboot. It is also possible
to generate other files using _heredoc_ or _"<"_ syntax in novaboot
scripts. Finally, binaries can be generated in this phases by running
`scons` or `make`.

- \--build-dir=<directory>

    Overrides the default build directory location.

    The default build directory location is determined as follows:

    If there is a configuration file, the value specified in the
    _$builddir_ variable is used. Otherwise, if the current working
    directory is inside git work tree and there is `build` directory at
    the top of that tree, it is used. Otherwise, if directory
    `~/nul/build` exists, it is used. Otherwise, it is the directory that
    contains the first processed novaboot script.

- \-g, --grub\[=_filename_\]

    Generates grub bootloader menu file. If the _filename_ is not
    specified, `menu.lst` is used. The _filename_ is relative to the
    build directory (see __\--build-dir__).

- \--grub-prefix=_prefix_

    Specifies _prefix_ that is put before every file in GRUB's `menu.lst`.
    This overrides the value of _$server\_grub\_prefix_ from the
    configuration file.

- \--grub2\[=_filename_\]

    Generate GRUB2 menuentry in _filename_. If _filename_ is not
    specified `grub.cfg` is used. The content of the menuentry can be
    customized by _$grub2\_prolog_ and _$server\_grub\_prefix_
    configuration variables.

    In order to use the the generated menuentry on your development
    machine that uses GRUB2, append the following snippet to
    `/etc/grub.d/40\_custom` file and regenerate your grub configuration,
    i.e. run update-grub on Debian/Ubuntu.

        if [ -f /path/to/nul/build/grub.cfg ]; then
          source /path/to/nul/build/grub.cfg
        fi

- \--name=_string_

    Use the name _string_ instead of the name of the novaboot script.
    This name is used for things like a title of grub menu or for the
    server directory where the boot files are copied to.

- \--no-file-gen

    Do not generate files on the fly (i.e. "<" syntax) except for the
    files generated via "<<WORD" syntax.

- \-p, --pulsar\[=mac\]

    Generates pulsar bootloader configuration file whose name is based on
    the MAC address specified either on the command line or taken from
    _.novaboot_ configuration file.

## File deployment phase

In some setups, it is necessary to copy the files needed for booting
to a particular location, e.g. to a TFTP boot server or to the
`/boot` partition.

- \-d, --dhcp-tftp

    Turns your workstation into a DHCP and TFTP server so that NOVA
    can be booted via PXE BIOS on a test machine directly connected by
    a plain Ethernet cable to your workstation.

    The DHCP and TFTP servers require root privileges and `novaboot`
    uses `sudo` command to obtain those. You can put the following to
    _/etc/sudoers_ to allow running the necessary commands without
    asking for password.

        Cmnd_Alias NOVABOOT = /bin/ip a add 10.23.23.1/24 dev eth0, /bin/ip l set dev eth0 up, /usr/sbin/dhcpd -d -cf dhcpd.conf -lf dhcpd.leases -pf dhcpd.pid, /usr/sbin/in.tftpd --foreground --secure -v -v -v *, /usr/bin/touch dhcpd.leases
        your_login ALL=NOPASSWD: NOVABOOT

- \-i, --iso\[=filename\]

    Generates the ISO image that boots NOVA system via GRUB. If no filename
    is given, the image is stored under _NAME_.iso, where _NAME_ is the name
    of the novaboot script (see also __\--name__).

- \--server\[=\[\[user@\]server:\]path\]

    Copy all files needed for booting to another location (implies __\-g__
    unless __\--grub2__ is given). The files will be copied (by __rsync__
    tool) to the directory _path_. If the _path_ contains string $NAME,
    it will be replaced with the name of the novaboot script (see also
    __\--name__).

    Additionally, if $NAME is the last component of the _path_, a file
    named _path_/menu.lst (with $NAME removed from the _path_) will be
    created on the server by concatenating all _path_/\*/menu.lst (with
    $NAME removed from the _path_) files found on the server.

- \--rsync-flags=_flags_

    Specifies which _flags_ are appended to `rsync` command line when
    copying files as a result of _\--server_ option.

- \--scons\[=scons command\]

    Runs _scons_ to build files that are not generated by novaboot
    itself.

## Target power-on and reset phase

- \--iprelay\[=addr or cmd\]

    If no _cmd_ is given, use IP relay to reset the machine and to get
    the serial output. The IP address of the relay is given by _addr_
    parameter if specified or by $iprelay\_addr variable in the
    configuration file.

    If _cmd_ is one of "on" or "off", the IP relay is used to press power
    button for a short (in case of "on") or long (in case of "off") time.
    Then, novaboot exits.

    Note: This option is expected to work with HWG-ER02a IP relays.

- \--on, --off

    Synonym for --iprelay=on/off.

- \-Q, --qemu=_qemu-binary_

    The name of qemu binary to use. The default is 'qemu'.

- \--qemu-append=_flags_

    Append _flags_ to the default qemu flags (QEMU\_FLAGS variable or
    `-cpu coreduo -smp 2`).

- \-q, --qemu-flags=_flags_

    Replace the default qemu flags (QEMU\_FLAGS variable or `-cpu coreduo
    -smp 2`) with _flags_ specified here.

## Interaction with the bootloader on the target

See __\--serial__. There will be new options soon.

## Reception of target's output (e.g. console) on the host system

- \-s, --serial\[=device\]

Use serial line to control GRUB bootloader and to see the output
serial output of the machine. The default value is `/dev/ttyUSB0`.

## Termination phase

Daemons that were spwned (`dhcpd` and `tftpd`) are killed here.

# NOVABOOT SCRIPT SYNTAX

The syntax tries to mimic POSIX shell syntax. The syntax is defined with the following rules.

Lines starting with "\#" are ignored.

Lines that end with "\\" are concatenated with the following line after
removal of the final "\\" and leading whitespace of the following line.

Lines in the form _VARIABLE=..._ (i.e. matching '^\[A-Z\_\]+=' regular
expression) assign values to internal variables. See VARIABLES
section.

Otherwise, the first word on the line represents the filename
(relative to the build directory (see __\--build-dir__) of the module to
load and the remaining words are passed as the command line
parameters.

When the line ends with "<<WORD" then the subsequent lines until the
line containing only WORD are copied literally to the file named on
that line.

When the line ends with "< CMD" the command CMD is executed with
`/bin/sh` and its standard output is stored in the file named on that
line. The SRCDIR variable in CMD's environment is set to the absolute
path of the directory containing the interpreted novaboot script.

Example:
  \#!/usr/bin/env novaboot
  WVDESC=Example program
  bin/apps/sigma0.nul S0\_DEFAULT script\_start:1,1 \\
    verbose hostkeyb:0,0x60,1,12,2
  bin/apps/hello.nul
  hello.nulconfig <<EOF
  sigma0::mem:16 name::/s0/log name::/s0/timer name::/s0/fs/rom ||
  rom://bin/apps/hello.nul
  EOF

This example will load three modules: sigma0.nul, hello.nul and
hello.nulconfig. sigma0 gets some command line parameters and
hello.nulconfig file is generated on the fly from the lines between
<<EOF and EOF.

## VARIABLES

The following variables are interpreted in the novaboot script:

- WVDESC

    Description of the wvtest-compliant program.

- WVTEST\_TIMEOUT

    The timeout in seconds for WvTest harness. If no complete line appears
    in the test output within the time specified here, the test fails. It
    is necessary to specify this for long running tests that produce no
    intermediate output.

- QEMU

    Use a specific qemu binary (can be overriden with __\-Q__) and flags
    when booting this script under qemu. If QEMU\_FLAGS variable is also
    specified flags specified in QEMU variable are replaced by those in
    QEMU\_FLAGS.

- QEMU\_FLAGS

    Use specific qemu flags (can be overriden with __\-q__).

- HYPERVISOR\_PARAMS

    Parameters passed to hypervisor. The default value is "serial", unless
    overriden in configuration file.

- KERNEL

    The kernel to use instead of NOVA hypervisor specified in the
    configuration file. The value should contain the name of the kernel
    image as well as its command line parameters. If this variable is
    defined and non-empty, the variable HYPERVISOR\_PARAMS is not used.

# CONFIGURATION FILE

Novaboot can read its configuration from a file. Configuration file
was necessary in early days of novaboot. Nowadays, an attempt is made
to not use the configuration file because it makes certain novaboot
scripts unusable on systems without (or with different) configuration
file. The only recommended use of the configuration file is to specify
custom\_options (see bellow).

If you decide to use the configuration file, its default location is
~/.novaboot, other location can be specified with the __\-c__ switch or
with the NOVABOOT\_CONFIG environment variable. The configuration file
has perl syntax and should set values of certain Perl variables. The
current configuration can be dumped with the __\--dump-config__ switch.
Some configuration variables can be overriden by environment variables
(see below) or by command line switches.

Documentation of some configuration variables follows:

- @chainloaders

    Custom chainloaders to load before hypervisor and files specified in
    novaboot script. E.g. ('bin/boot/bender promisc', 'bin/boot/zapp').

- %custom\_options

    Defines custom command line options that can serve as aliases for
    other options. E.g. 'S' => '--server=boot:/tftproot
    \--serial=/dev/ttyUSB0'.

# ENVIRONMENT VARIABLES

Some options can be specified not only via config file or command line
but also through environment variables. Environment variables override
the values from configuration file and command line parameters
override the environment variables.

- NOVABOOT\_CONFIG

    A name of default novaboot configuration file.

- NOVABOOT\_BENDER

    Defining this variable has the same meaning as __\--bender__ option.

- NOVABOOT\_IPRELAY

    The IP address (and optionally the port) of the IP relay. This
    overrides $iprelay\_addr variable from the configuration file.

# AUTHORS

Michal Sojka <sojka@os.inf.tu-dresden.de>
