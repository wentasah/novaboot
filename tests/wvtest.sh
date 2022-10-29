
WV_BASE_DIR="$PWD"
export NOVABOOT_TEST=1
export NOVABOOT_CONFIG_DIR=/dev/null # Do not read config from /etc/novaboot.d
export XDG_CONFIG_HOME=/dev/null # Do not read user config from ~/.config/novaboot

PATH=$(dirname $PWD):$PATH # Find our version of novaboot first

function create_script ()
{
    (echo "#!/usr/bin/env novaboot"; cat) > script
    chmod +x script
}

function create_dummy ()
{
    create_script <<EOF
load kernel
load file
EOF
    touch kernel
    touch file
}
