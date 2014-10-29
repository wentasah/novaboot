# NAME

novaboot - Boots a locally compiled operating system on a remote
target or in qemu

# SYNOPSIS

**novaboot** --help

**novaboot** \[option\]... \[--\] script...

**./script** \[option\]...

# DESCRIPTION

This program makes booting of a locally compiled operating system (OS)
(e.g. NOVA or Linux) on remote targets as simple as running a program
locally. It automates things like copying OS images to a TFTP server,
generation of bootloader configuration files, resetting of target
hardware or redirection of target's serial line to stdin/out. Novaboot
is highly configurable and it makes it easy to boot a single image on
different targets or different images on a single target.

Novaboot operation is controlled by command line options and by a so
called novaboot script, which can be thought as a generalization of
bootloader configuration files (see ["NOVABOOT SCRIPT SYNTAX"](#novaboot-script-syntax)).
Typical way of using novaboot is to make the novaboot script
executable and set its first line to _#!/usr/bin/env novaboot_. Then,
booting a particular OS configuration becomes the same as executing a
local program - the novaboot script.

Novaboot uses configuration files to, among other things, define
command line options needed for different targets. Users typically use
only the **-t**/**--target** command line option to select the target.
Internally, this option expands to the pre-configured options.
Configuration files are searched at multiple places, which allows to
have per-system, per-user or per-project configurations. Configuration
file syntax is described in section ["CONFIGURATION FILE"](#configuration-file).

Simple examples of using `novaboot`:

1. Run an OS in Qemu. This is the default action when no other action is
specified by command line switches. Thus running `novaboot myos` (or
`./myos` as described above) will run Qemu and make it boot the
configuration specified in the `myos` script.
2. Create a bootloader configuration file (currently supported
bootloaders are GRUB, GRUB2, ISOLINUX, Pulsar and U-Boot) and copy it
with all other files needed for booting to a remote boot server. Then
use a TCP/IP-controlled relay/serial-to-TCP converter to reset the
target and receive its serial output.

        ./myos --grub2 --server=192.168.1.1:/tftp --iprelay=192.168.1.2

3. Run DHCP and TFTP server on developer's machine to boot the target
from it.

        ./myos --dhcp-tftp

    This is useful when no network infrastructure is in place and
    the target is connected directly to developer's box.

4. Create bootable ISO image.

        novaboot --iso -- script1 script2

    The created ISO image will have ISOLINUX bootloader installed on it
    and the boot menu will allow selecting between _script1_ and
    _script2_ configurations.

# PHASES AND OPTIONS

Novaboot performs its work in several phases. Each phase can be
influenced by several command line options, certain phases can be
skipped. The list of phases (in the execution order) and the
corresponding options follows.

## Configuration reading phase

After starting, novaboot reads configuration files. Their content is
described in section ["CONFIGURATION FILE"](#configuration-file). By default,
configuration is read from two locations. First from the configuration
directory and second from `.novaboot` files along the path to the
current directory. The latter read files override settings from the
former ones.

Configuration directory is determined by the content of
NOVABOOT\_CONFIG\_DIR environment variable and defaults to
`/etc/novaboot.d`. Files in this directory with names consisting
solely of English letters, numbers, dashes '-' and underscores '\_'
(note that dot '.' is not included) are read in alphabetical order.

Then novaboot searches for files named `.novaboot` starting from the
directory of the novaboot script (or working directory, see bellow)
and continuing upwards up to the root directory. The found
configuration files are then read in the opposite order (i.e. from the
root directory downwards). This allows to have, for example, user
specific configuration in `~/.novaboot` and project specific one in
`~/project/.novaboot`.

In certain cases, the location of the novaboot script cannot be
determined in this early phase. This happens either when the script is
read from the standard input or when novaboot is invoked explicitly as
in the example ["4."](#4) above. In this case the current working
directory is used as a starting point for configuration file search
instead of the novaboot script directory.

- -c, --config=_filename_

    Use the specified configuration file instead of the default one(s).

## Command line processing phase

- --dump-config

    Dump the current configuration to stdout end exit. Useful as an
    initial template for a configuration file.

- -h, --help

    Print short (**-h**) or long (**--help**) help.

- -t, --target=_target_

    This option serves as a user configurable shortcut for other novaboot
    options. The effect of this option is the same as the options stored
    in the `%targets` configuration variable under key _target_. See
    also ["CONFIGURATION FILE"](#configuration-file).

## Script preprocessing phase

This phases allows to modify the parsed novaboot script before it is
used in the later phases.

- -a, --append=_parameters_

    Append a string to the first `load` line in the novaboot script. This
    can be used to append parameters to the kernel's or root task's
    command line. This option can appear multiple times.

- -b, --bender

    Use `bender` chainloader. Bender scans the PCI bus for PCI serial
    ports and stores the information about them in the BIOS data area for
    use by the kernel.

- --chainloader=_chainloader_

    Specifies a chainloader that is loaded before the kernel and other
    files specified in the novaboot script. E.g. 'bin/boot/bender
    promisc'.

- --dump

    Print the modules to boot and their parameters after this phase
    finishes. Then exit. This is useful for seeing the effect of other
    options in this section.

- -k, --kernel=`file`

    Replace the first word on the first `load` line in the novaboot
    script with `file`.

- --scriptmod=_perl expression_

    When novaboot script is read, _perl expression_ is executed for every
    line (in $\_ variable). For example, `novaboot
    \--scriptmod=s/sigma0/omega6/g` replaces every occurrence of _sigma0_
    in the script with _omega6_.

    When this option is present, it overrides _$script\_modifier_ variable
    from the configuration file, which has the same effect. If this option
    is given multiple times all expressions are evaluated in the command
    line order.

## File generation phase

In this phase, files needed for booting are generated in a so called
_build directory_ (see ["--build-dir"](#build-dir)). In most cases configuration
for a bootloader is generated automatically by novaboot. It is also
possible to generate other files using _heredoc_ or _"<"_ syntax in
novaboot scripts. Finally, binaries can be generated in this phases by
running `scons` or `make`.

- --build-dir=_directory_

    Overrides the default build directory location.

    The default build directory location is determined as follows: If the
    configuration file defines the `$builddir` variable, its value is
    used. Otherwise, it is the directory that contains the first processed
    novaboot script.

    See also ["BUILDDIR"](#builddir) variable.

- -g, --grub\[=_filename_\]

    Generates grub bootloader menu file. If the _filename_ is not
    specified, `menu.lst` is used. The _filename_ is relative to the
    build directory (see **--build-dir**).

- --grub-preamble=_prefix_

    Specifies the _preable_ that is at the beginning of the generated
    GRUB or GRUB2 config files. This is useful for specifying GRUB's
    timeout.

- --prefix=_prefix_

    Specifies _prefix_ (e.g. `/srv/tftp`) that is put in front of every
    file name in generated bootloader configuration files (or in U-Boot
    commands).

    If the _prefix_ contains string $NAME, it will be replaced with the
    name of the novaboot script (see also **--name**).

    If the _prefix_ contains string $BUILDDIR, it will be replaced with
    the build directory (see also **--build-dir**).

- --grub-prefix

    Alias for **--prefix**.

- --grub2\[=_filename_\]

    Generate GRUB2 menu entry in _filename_. If _filename_ is not
    specified `grub.cfg` is used. The content of the menu entry can be
    customized with **--grub-preamble**, **--grub2-prolog** or
    **--grub\_prefix** options.

    In order to use the the generated menu entry on your development
    machine that uses GRUB2, append the following snippet to
    `/etc/grub.d/40_custom` file and regenerate your grub configuration,
    i.e. run update-grub on Debian/Ubuntu.

        if [ -f /path/to/nul/build/grub.cfg ]; then
          source /path/to/nul/build/grub.cfg
        fi

- --grub2-prolog=_prolog_

    Specifies text that is put at the beginning of the GRUB2 menu entry.

- -m, --make\[=make command\]

    Runs `make` to build files that are not generated by novaboot itself.

- --name=_string_

    Use the name _string_ instead of the name of the novaboot script.
    This name is used for things like a title of grub menu or for the
    server directory where the boot files are copied to.

- --no-file-gen

    Do not run external commands to generate files (i.e. "<" syntax and
    `run` keyword). This switch does not influence generation of files
    specified with "<<WORD" syntax.

- -p, --pulsar\[=mac\]

    Generates pulsar bootloader configuration file named `config-_mac_`
    The _mac_ string is typically a MAC address and defaults to
    _novaboot_.

- --scons\[=scons command\]

    Runs `scons` to build files that are not generated by novaboot
    itself.

- --strip-rom

    Strip _rom://_ prefix from command lines and generated config files.
    The _rom://_ prefix is used by NUL. For NRE, it has to be stripped.

- --gen-only

    Exit novaboot after file generation phase.

## Target connection check

If supported by the target, the connection to it is made and it is
checked whether the target is not occupied by another novaboot
user/instance.

- --amt=_"\[user\[:password\]@\]host\[:port\]_

    Use Intel AMT technology to control the target machine. WS management
    is used to powercycle it and Serial-Over-Lan (SOL) for input/output.
    The hostname or (IP address) is given by the _host_ parameter. If
    _password_ is not specified, environment variable AMT\_PASSWORD is
    used. The _port_ specifies a TCP port for SOL. If not specified, the
    default is 16992. Default _user_ is admin.

- --iprelay=_addr\[:port\]_

    Use TCP/IP relay and serial port to access the target's serial port
    and powercycle it. The IP address of the relay is given by _addr_
    parameter. If _port_ is not specified, it default to 23.

    Note: This option is supposed to work with HWG-ER02a IP relays.

- -s, --serial\[=device\]

    Target's serial line is connected to host's serial line (device). The
    default value for device is `/dev/ttyUSB0`.

    The value of this option is exported in NB\_NOVABOOT environment
    variable to all subprocesses run by `novaboot`.

- --stty=_settings_

    Specifies settings passed to `stty` invoked on the serial line
    specified with **--serial** option. If this option is not given,
    `stty` is called with `raw -crtscts -onlcr 115200` settings.

- --remote-cmd=_cmd_

    Command that mediates connection to the target's serial line. For
    example `ssh server 'cu -l /dev/ttyS0'`.

- --remote-expect=_string_

    Wait for reception of _string_ after establishing the the remote
    connection before continuing.

## File deployment phase

In some setups, it is necessary to copy the files needed for booting
to a particular location, e.g. to a TFTP boot server or to the
`/boot` partition.

- -d, --dhcp-tftp

    Turns your workstation into a DHCP and TFTP server so that the OS can
    be booted via PXE BIOS (or similar mechanism) on the test machine
    directly connected by a plain Ethernet cable to your workstation.

    The DHCP and TFTP servers requires root privileges and `novaboot`
    uses `sudo` command to obtain those. You can put the following to
    _/etc/sudoers_ to allow running the necessary commands without asking
    for password.

        Cmnd_Alias NOVABOOT = /bin/ip a add 10.23.23.1/24 dev eth0, /bin/ip l set dev eth0 up, /usr/sbin/dhcpd -d -cf dhcpd.conf -lf dhcpd.leases -pf dhcpd.pid, /usr/sbin/in.tftpd --listen --secure -v -v -v --pidfile tftpd.pid *, /usr/bin/touch dhcpd.leases, /usr/bin/pkill --pidfile=dhcpd.pid, /usr/bin/pkill --pidfile=tftpd.pid
        your_login ALL=NOPASSWD: NOVABOOT

- --tftp

    Starts a TFTP server on your workstation. This is similar to
    **--dhcp-tftp** except that DHCP server is not started.

    The TFTP server require root privileges and `novaboot` uses `sudo`
    command to obtain those. You can put the following to _/etc/sudoers_
    to allow running the necessary commands without asking for password.

        Cmnd_Alias NOVABOOT =  /usr/sbin/in.tftpd --listen --secure -v -v -v --pidfile tftpd.pid *, /usr/bin/pkill --pidfile=tftpd.pid
        your_login ALL=NOPASSWD: NOVABOOT

- --tftp-port=_port_

    Port to run the TFTP server on. Implies **--tftp**.

- --iso\[=filename\]

    Generates the ISO image that boots NOVA system via GRUB. If no filename
    is given, the image is stored under _NAME_.iso, where _NAME_ is the name
    of the novaboot script (see also **--name**).

- --server\[=\[\[user@\]server:\]path\]

    Copy all files needed for booting to another location. The files will
    be copied (by **rsync** tool) to the directory _path_. If the _path_
    contains string $NAME, it will be replaced with the name of the
    novaboot script (see also **--name**).

- --rsync-flags=_flags_

    Specifies which _flags_ are appended to `rsync` command line when
    copying files as a result of _--server_ option.

- --concat

    If **--server** is used and its value ends with $NAME, then after
    copying the files, a new bootloader configuration file (e.g. menu.lst)
    is created at _path-wo-name_, i.e. the path specified by **--server**
    with $NAME part removed. The content of the file is created by
    concatenating all files of the same name from all subdirectories of
    _path-wo-name_ found on the "server".

- --ider

    Use Intel AMT technology for IDE redirection. This allows the target
    machine to boot from novaboot created ISO image. Implies **--iso**.

    The experimental `amtider` utility needed by this option can be
    obtained from https://github.com/wentasah/amtterm.

## Target power-on and reset phase

At this point, the target is reset (or switched on/off). There is
several ways how this can be accomplished. Resetting a physical target
can currently be accomplished by the following options: **--amt**,
**--iprelay**, **--reset-cmd**.

- --on, --off

    Switch on/off the target machine and exit. The script (if any) is
    completely ignored. Currently it works only with **--iprelay** or
    **--amt**.

- -Q, --qemu\[=_qemu-binary_\]

    Boot the configuration in qemu. Optionally, the name of qemu binary
    can be specified as a parameter.

- --qemu-append=_flags_

    Append _flags_ to the default qemu flags (QEMU\_FLAGS variable or
    `-cpu coreduo -smp 2`).

- -q, --qemu-flags=_flags_

    Replace the default qemu flags (QEMU\_FLAGS variable or `-cpu coreduo
    \-smp 2`) with _flags_ specified here.

- --reset-cmd=_cmd_

    Command that resets the target.

- --no-reset, --reset

    Disable/enable reseting of the target.

## Interaction with the bootloader on the target

- --uboot\[=_prompt_\]

    Interact with U-Boot bootloader to boot the thing described in the
    novaboot script. _prompt_ specifies the U-Boot's prompt (default is
    "=> ", other common prompts are "U-Boot> " or "U-Boot# ").
    Implementation of this option is currently tied to a particular board
    that we use. It may be subject to changes in the future!

- --uboot-init

    Command(s) to send the U-Boot bootloader before loading the images and
    booting them. This option can be given multiple times. After sending
    commands from each option novaboot waits for U-Boot _prompt_.

    If the command contains string _$NB\_MYIP_ then this string is
    replaced by IPv4 address of eth0 interface. Similarly _$NB\_PREFIX_ is
    replaced with prefix given by **--prefix**.

    See also `uboot` keyword in ["NOVABOOT SCRIPT SYNTAX"](#novaboot-script-syntax)).

- --uboot-addr _name_=_address_

    Load address of U-Boot's `tftpboot` command for loading _name_,
    where name is one of _kernel_, _ramdisk_ or _fdt_ (flattened device
    tree).

- --uboot-cmd=_command_

    Specifies U-Boot command used to execute the OS. If the command
    contains strings `$kernel_addr`, `$ramdisk_addr`, `$fdt_addr`,
    these are replaced with the addresses configured with **--uboot-addr**.

    The default value is

        bootm $kernel_addr $ramdisk_addr $fdt_addr

    or the `UBOOT_CMD` variable if defined in the novaboot script.

## Target interaction phase

In this phase, target's serial output is redirected to stdout and if
stdin is a TTY, it is redirected to the target's serial input allowing
interactive work with the target.

- --exiton=_string_

    When _string_ is sent by the target, novaboot exits. This option can
    be specified multiple times, in which case novaboot exits whenever
    either of the specified strings is sent.

    If _string_ is `-re`, then the next **--exiton**'s _string_ is
    treated as regular expression. For example:

        --exiton -re --exiton 'error:.*failed'

- --exiton-re=_regex_

    The same as --exiton -re --exiton _regex_.

- --exiton-timeout=_seconds_

    By default **--exiton** waits for the string match forever. When this
    option is specified, "exiton" timeouts after the specifies number of
    seconds and novaboot returns non-zero exit code.

- -i, --interactive

    Setup things for interactive use of target. Your terminal will be
    switched to raw mode. In raw mode, your system does not process input
    in any way (no echoing of entered characters, no interpretation
    special characters). This, among others, means that Ctrl-C is passed
    to the target and does no longer interrupt novaboot. Use "~~."
    sequence to exit novaboot.

- --expect=_string_

    When _string_ is received from the target, send the string specified
    with the subsequent **--send\*** option to the target.

- --expect-re=_regex_

    When target's output matches regular expression _regex_, send the
    string specified with the subsequent **--send\*** option to the target.

- --expect-raw=_perl-code_

    Provides direct control over Perl's Expect module.

- --send=_string_

    Send _string_ to the target after the previously specified
    **--expect\*** was matched in the target's output. The _string_ may
    contain escape sequences such as "\\n".

    Note that _string_ is actually interpreted by Perl, so it can contain
    much more that escape sequences. This behavior may change in the
    future.

    Example: `--expect='login: ' --send='root\n'`

- --sendcont=_string_

    Similar to **--send** but continue expecting more input.

    Example: `--expect='Continue?' --sendcont='yes\n'`

# NOVABOOT SCRIPT SYNTAX

The syntax tries to mimic POSIX shell syntax. The syntax is defined
with the following rules.

Lines starting with "#" and empty lines are ignored.

Lines that end with "\\" are concatenated with the following line after
removal of the final "\\" and leading whitespace of the following line.

Lines of the form _VARIABLE=..._ (i.e. matching '^\[A-Z\_\]+=' regular
expression) assign values to internal variables. See ["VARIABLES"](#variables)
section.

Lines starting with `load` keyword represent modules to boot. The
word after `load` is a file name (relative to the build directory
(see **--build-dir**) of the module to load and the remaining words are
passed to it as the command line parameters.

When the `load` line ends with "<<WORD" then the subsequent lines
until the line containing solely WORD are copied literally to the file
named on that line. This is similar to shell's heredoc feature.

When the `load` line ends with "< CMD" then command CMD is executed
with `/bin/sh` and its standard output is stored in the file named on
that line. The SRCDIR variable in CMD's environment is set to the
absolute path of the directory containing the interpreted novaboot
script.

Lines starting with `run` keyword contain shell commands that are run
during file generation phase. This is the same as the "< CMD" syntax
for `load` keyboard except that the command's output is not
redirected to a file. The ordering of commands is the same as they
appear in the novaboot script.

Lines starting with `uboot` represent U-Boot commands that are sent
to the target if **--uboot** option is given. Having a U-Boot line in
the novaboot script is the same as passing an equivalent
**--uboot-init** option to novaboot. The `uboot` keyword can be
suffixed with timeout specification. The syntax is `uboot:Ns`, where
`N` is the whole number of seconds. If the U-Boot command prompt does
not appear before the timeout, novaboot fails. The default timeout is
10 seconds.

Example (Linux):

    #!/usr/bin/env novaboot
    load bzImage console=ttyS0,115200
    run  make -C buildroot
    load rootfs.cpio < gen_cpio buildroot/images/rootfs.cpio "myapp->/etc/init.d/S99myapp"

Example (NOVA User Land - NUL):

    #!/usr/bin/env novaboot
    WVDESC=Example program
    load bin/apps/sigma0.nul S0_DEFAULT script_start:1,1 \
                             verbose hostkeyb:0,0x60,1,12,2
    load bin/apps/hello.nul
    load hello.nulconfig <<EOF
    sigma0::mem:16 name::/s0/log name::/s0/timer name::/s0/fs/rom ||
    rom://bin/apps/hello.nul
    EOF

This example will load three modules: `sigma0.nul`, `hello.nul` and
`hello.nulconfig`. sigma0 receives some command line parameters and
`hello.nulconfig` file is generated on the fly from the lines between
`<<EOF` and `EOF`.

## VARIABLES

The following variables are interpreted in the novaboot script:

- BUILDDIR

    Novaboot chdir()s to this directory before file generation phase. The
    directory name specified here is relative to the build directory
    specified by other means (see ["--build-dir"](#build-dir)).

- EXITON

    Assigning this variable has the same effect as specifying ["--exiton"](#exiton)
    option.

- HYPERVISOR\_PARAMS

    Parameters passed to hypervisor. The default value is "serial", unless
    overridden in configuration file.

- KERNEL

    The kernel to use instead of the hypervisor specified in the
    configuration file with the `$hypervisor` variable. The value should
    contain the name of the kernel image as well as its command line
    parameters. If this variable is defined and non-empty, the variable
    HYPERVISOR\_PARAMS is not used.

- NO\_BOOT

    If this variable is 1, the system is not booted. This is currently
    only implemented for U-Boot bootloader where it is useful for
    interacting with the bootloader without booting the system - e.g. for
    flashing.

- QEMU

    Use a specific qemu binary (can be overridden with **-Q**) and flags
    when booting this script under qemu. If QEMU\_FLAGS variable is also
    specified flags specified in QEMU variable are replaced by those in
    QEMU\_FLAGS.

- QEMU\_FLAGS

    Use specific qemu flags (can be overridden with **-q**).

- UBOOT\_CMD

    See ["--uboot-cmd"](#uboot-cmd).

- WVDESC

    Description of the WvTest-compliant program.

- WVTEST\_TIMEOUT

    The timeout in seconds for WvTest harness. If no complete line appears
    in the test output within the time specified here, the test fails. It
    is necessary to specify this for long running tests that produce no
    intermediate output.

# CONFIGURATION FILE

Novaboot can read its configuration from one or more files. By
default, novaboot looks for files in `/etc/novaboot.d` and files
named `.novaboot` as described in ["Configuration reading phase"](#configuration-reading-phase).
Alternatively, configuration file location can be specified with the
**-c** switch or with the NOVABOOT\_CONFIG environment variable. The
configuration file has Perl syntax (i.e. it is better to put `1;` as
a last line) and should set values of certain Perl variables. The
current configuration can be dumped with the **--dump-config** switch.
Some configuration variables can be overridden by environment
variables (see below) or by command line switches.

Supported configuration variables include:

- $builddir

    Build directory location relative to the location of the configuration
    file.

- $default\_target

    Default target (see below) to use when no target is explicitly
    specified on command line with the **--target** option.

- %targets

    Hash of target definitions to be used with the **--target** option. The
    key is the identifier of the target, the value is the string with
    command line options. For instance, if the configuration file contains:

        $targets{'mybox'} = '--server=boot:/tftproot --serial=/dev/ttyUSB0 --grub',

    then the following two commands are equivalent:

        ./myos --server=boot:/tftproot --serial=/dev/ttyUSB0 --grub
        ./myos -t mybox

# ENVIRONMENT VARIABLES

Some options can be specified not only via config file or command line
but also through environment variables. Environment variables override
the values from configuration file and command line parameters
override the environment variables.

- NOVABOOT\_CONFIG

    Name of the novaboot configuration file to use instead of the default
    one(s).

- NOVABOOT\_CONFIG\_DIR

    Name of the novaboot configuration directory. When not specified
    `/etc/novaboot.d` is used.

- NOVABOOT\_BENDER

    Defining this variable has the same meaning as **--bender** option.

# AUTHORS

Michal Sojka <sojka@os.inf.tu-dresden.de>
