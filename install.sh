#!/bin/bash

[[ "$(uname)" == "Darwin" ]] && readlink=greadlink || readlink=readlink
D=$($readlink -f $(dirname $0))

source $D/common.sh || exit 1

function usage() {
	cat << EOF
usage: $0 [<OPTIONS>]

Install and setup code review tools

OPTIONS:
   -h/--help          Show this message
   -j                 Install extra RSSI reducing aliases
   -f                 Force, accepts defaults for all questions
EOF
}

force=

while getopts "fjh" options; do
    case $options in
        f ) force=1;;
        j ) yay_rssi=1;;
        h ) usage
            exit 0;;
        * ) echo unkown option: ${option}
            usage
            exit 1;;
    esac
done

cecho "Setting organization name..." $green
echo
echo  "[The organization name is used to issue pull requests, to change the org"
echo  "name manually modify the 'org' alias in your .gitconfig (run: git config"
echo  "--global --edit) -- This can also be a github username like: defunkt]."
echo
cecho "Your 'org' name? [default: cozybit] " $yellow

[[ -z $force ]] && read -p '> ' org_name
[[ -z $org_name ]] && org_name=cozybit

cecho "Installing review tools..." $green
echo_eval sudo install git-review  "/usr/local/bin/git-review" || die "git-review install failed"
echo_eval sudo install git-pullreq "/usr/local/bin/git-pullreq" || die "git-pullreq install failed"
echo_eval sudo install git-update-pr "/usr/local/bin/git-update-pr" || die "git-update-pr install failed"

## Internal aliases not worth mentioning
echo_eval git config --global alias.add-pull-request-remote "config --add remote.origin.fetch +refs/pull/*/head:refs/remotes/origin/pull-request/*"
echo_eval git config --global alias.cbr "rev-parse --abbrev-ref HEAD"
echo_eval git config --global alias.org "!echo $org_name"

cecho "Adding 'pr' / 'pull-request' alias to build a pull-request based on 'origin/master'..." $green
echo_eval git config --global alias.pr "!git prb master"
echo_eval git config --global alias.pull-request "!git pr"

cecho "Adding 'upr' / 'update-pull-request' alias to update a pull-request based on 'origin/master'..." $green
echo_eval git config --global alias.upr "!git-update-pr"
echo_eval git config --global alias.update-pull-request "!git upr"

cecho "Adding 'prb' / 'branch-pull-request' alias to build a pull-request based on an arbitrary branch in 'origin' master..." $green
echo_eval git config --global alias.prb '!git-pullreq $1'
echo_eval git config --global alias.branch-pull-request '!git prb'

cecho "Adding 'review' alias which walks through commits and diffs each change..." $green
echo_eval git config --global alias.review "!git-review"

cecho "Adding 'rup' / 'remote-update-prune' alias which updates the remotes, and removes stale branches..." $green
echo_eval git config --global alias.rup "remote update --prune"
echo_eval git config --global alias.remote-update-prune "remote update --prune"

if [[ -n $yay_rssi ]]; then
    cecho "Adding 'wipe' which ruthlessly murders anything that's not in the git repo (DANGEROUS)..." $green
    echo_eval git config --global alias.wipe "!git reset --hard;git clean -fdx"

    cecho "Adding 'co' alias for 'git checkout'..." $green
    echo_eval git config --global alias.co "checkout"

    cecho "Adding 'cob' / 'checkout-branch' alias for 'git checkout -b'..." $green
    echo_eval git config --global alias.cob "checkout -b"
    echo_eval git config --global alias.checkout-branch "!git cob"

    cecho "Adding 'com' / 'checkout-master' alias for 'git checkout master'..." $green
    echo_eval git config --global alias.com "checkout master"
    echo_eval git config --global alias.checkout-master "!git com"

    cecho "Adding 'st' alias for 'git status'..." $green
    echo_eval git config --global alias.st "status"

    cecho "Adding 'ci' alias for 'git checkin'..." $green
    echo_eval git config --global alias.ci "commit --verbose"

    cecho "Adding 'cia' / 'commit-add' alias which automatically adds all files, diffs and opens a commit..." $green
    echo_eval git config --global alias.cia "commit -a --verbose"
    echo_eval git config --global alias.commit-add "!git cia"

    cecho "Adding 'mff' / 'merge-ff' alias which does a fast-foward merge..." $green
    echo_eval git config --global alias.mff "merge --ff-only"
    echo_eval git config --global alias.commit-add "!git mff"

    cecho "Adding 'pom' / 'push-origin-master' alias which does a 'push origin master'..." $green
    echo_eval git config --global alias.pom "push origin master"
    echo_eval git config --global alias.push-origin-master "!git pom"

    cecho "Adding 'mffpom' alias which does a fast-foward merge, then pushes to origin 'master'..." $green
    echo_eval git config --global alias.mffpom "!git mff $1 && git pom" 

fi

hub_url=https://github.com/github/hub

install_ruby=
install_hub=

if ! Q which ruby; then
    cecho "Looks like Ruby is missing, this is required for the 'hub' tool..." $yellow
    install_ruby=y
fi

if ! Q which hub; then
    cecho "Looks like the 'hub' tool is missing ($hub_url)..." $yellow
    install_hub=y
fi

if [[ -z $install_hub ]]; then
    cecho "Install new 'hub' tool? [y/N] " $yellow
    [[ -z $force ]] && read -p '> ' install_hub
    [[ ! $install_hub =~ [Yy] ]] && install_hub=
fi

if [[ -n $install_ruby && -n $install_hub ]]; then
    cecho "Installing Ruby for the 'hub' tool..." $green
    echo_eval sudo apt-get install ruby || die "ruby install failed"
fi

if [[ $install_hub =~ [Yy] ]]; then

    install_dir=`mktemp -d`

    _pushd $install_dir

        echo_eval git clone $hub_url || die "cloning hub repo failed"

        cd hub

        cecho "Installing the 'hub' tool..." $green
        echo_eval sudo rake install prefix=/usr/local || die "hub install failed"
        
    _popd
    rm -rf $install_dir
fi

if ! Q which pip; then
    cecho "Looks like the 'pip' Python library install tool is missing, installing..." $yellow
    echo_eval sudo apt-get install python-pip
fi

pygithub_url=https://github.com/jacquev6/PyGithub

if ! Q python -c 'import github'; then
    cecho "Looks like the 'github' Python library is missing ($pygithub_url)..." $yellow
    echo_eval sudo pip install PyGithub
fi

pygit_url=https://github.com/gitpython-developers/GitPython

if ! Q python -c 'import git'; then
    cecho "Looks like the 'git' Python library is missing ($pygit_url)..." $yellow
    echo_eval sudo pip install GitPython
fi
