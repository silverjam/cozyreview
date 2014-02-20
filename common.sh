[[ "$(uname)" == "Darwin" ]] && readlink=greadlink || readlink=readlink
D=$($readlink -f $(dirname $BASH_SOURCE))

# print message and exit the script
# usage: die <message>
function die () {
    cecho "${*}" $red
    exit -1
}

# perform a command quietly unless debugging is enabled.i
# usage: Q <anything>
function Q () {
        if [ "${VERBOSE}" == "1" ]; then
                "$@"
        else
                "$@" &> /dev/null
        fi
}

black=$'\E[1;30m'
red=$'\E[1;31m'
green=$'\E[1;32m'
yellow=$'\E[1;33m'
blue=$'\E[1;34m'
magenta=$'\E[1;35m'
cyan=$'\E[1;36m'
white=$'\E[1;37m'

function cecho ()            # Color-echo.
                             # Argument $1 = message
                             # Argument $2 = color
{
    local default_msg="No message passed."

    local message=${1:-$default_msg}
    local color=${2:-$black}

    echo -ne "$color"
    echo "$message"

    tput sgr0
}

function _pushd() {
    pushd $@ 2>&1 >/dev/null
}

function _popd() {
    popd $@ 2>&1 >/dev/null
}

function echo_eval() {
    echo "Running: $@"
    "$@"
}
