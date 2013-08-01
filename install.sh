#!/bin/bash

D=$(readlink -f $(dirname $0))
source $D/common.sh

cecho "Setting organization name..." $green
echo
echo  "[The organization name is used to issue pull requests, to change the org"
echo  "name manually modify the 'org' alias in your .gitconfig (run: git config"
echo  "--global --edit) -- This can also be a github username like: defunkt]."
echo
cecho "Your 'org' name? [default: cozybit] " $yellow

read -p '> ' org_name
[ -z "$org_name" ] && org_name=cozybit

cecho "Installing review tools..." $green
echo_eval sudo install git-review /usr/local/bin/git-review || die "git-review install failed"
echo_eval sudo install git-pullreq /usr/local/bin/git-pullreq || die "git-pullreq install failed"

cecho "Adding 'apr' alias to setup 'pull-request' as a remote key..." $green
echo_eval git config --global alias.apr "config --add remote.origin.fetch +refs/pull/*/head:refs/remotes/origin/pull-request/*"

cecho "Adding 'cbr' alias..." $green
echo_eval git config --global alias.cbr "rev-parse --abbrev-ref HEAD"

cecho "Adding 'org' alias..." $green
echo_eval git config --global alias.org "!echo $org_name"

cecho "Adding 'pr' alias to build a pull-request based on 'origin/master'..." $green
echo_eval git config --global alias.pr "!git prb master"                                          

cecho "Adding 'prb' alias to build a pull-request based on an arbitrary branch on 'origin'..." $green
echo_eval git config --global alias.prb "!git-pullreq $1"                                                    

cecho "Adding 'review' alias which walks through commits and diffs each change..." $green
echo_eval git config --global alias.review "!git-review"                                                 

cecho "Adding 'rup' alias which updates the remotes, and removes stale branches..." $green
echo_eval git config --global alias.rup "remote update --prune"

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
    read -p '> ' install_hub
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
