# # If we have a prompt, we have an interactive shell, and bash read profile already.
# [ "$PS1" ] && export PROFILEONCE=true
test -z "$PROFILEREAD" && test -z "$PROFILEONCE" &&
    { PROFILEONCE=true ; . /etc/profile ; }

test -e ~/.alias_all && . ~/.alias_all
test -e ~/.alias && . ~/.alias
test -e ~/.alias_shu && . ~/.alias_shu
# git is not needed - because using the system one
#test -e ~/.git-completion.bash && . ~/.git-completion.bash
test -e ~/.ct-completion.bash && . ~/.ct-completion.bash
test -e ~/.vboxmanage-completion.bash && . ~/.vboxmanage-completion.bash
test -e ~/.multibuild-completion.bash && . ~/.multibuild-completion.bash

export PATH=~/bin/:${PATH}

export CLEARCASE_CMNT_PN=~/.cc_comment_cache
#export CLEARCASE_AVOBS="/vobs/PIS /vobs/TcmsGenSw /vobs/tisc_pos"
export CLEARCASE_AVOBS="/vobs/PIS /vobs/TcmsGenSw /vobs/tisc_ccu-c /vobs/tisc_pcs"
#export VIMDIFF="xterm -geometry 300x61+0+0 -e vim -d"
export QMAKESPEC=linux-i586-g++
#export QMAKESPEC=linux-g++
export GREP_OPTIONS='--color=auto'
export GREP_COLOR='07;38;5;012'    # light blue invers

test -z "${LESS/*-R*/}" || export LESS="$LESS -R"
test -z "${LS_OPTIONS}" && export LS_OPTIONS='--color=auto'

# make bash's default behaviour interactive -> bashaliases can be used in vim
set shellcmdflag=-ic
#
## don't put duplicate lines in the history. See bash(1) for more options
## ... or force ignoredups and ignorespace
export HISTCONTROL=ignoredups:ignorespace
#
## append to the history file, don't overwrite it
shopt -s histappend
#
## for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
export HISTSIZE=10000
export HISTFILESIZE=20000
#
##export TZ=UTC
export LOCALE=UTF-8
export LC_ALL=en_US.UTF-8
#export LC_ALL=en_US.utf8


#echo ""
#echo "Executing user's: `whoami` bashrc... SHLVL: ${SHLVL}"
#echo ""
#

# toolchain path
#export PATH=/opt/bt/cross/i586-pc-linux-gnu/gcc-4.4.3/usr/bin:/opt/bt/cross/i586-pc-linux-gnu/Qt-4.7.3/bin:$PATH
#export PATH=/local/sdettmer/build/gcc/9-retest/inst/usr/bin:$PATH
#export PATH=/opt/local/cross/Qt-4.7.3/bin:$PATH
#export PATH=/local/palorenz/qt6/inst/usr/local/qt-4.7.3/bin:$PATH

# powerline
export POWERLINE_CONFIG_COMMAND=~/.vim/bundle/powerline/scripts/powerline-config
export PATH=~/.vim/bundle/powerline/scripts/:$PATH
#
set -o vi
## set -o emacs
#
#
#echo "DISPLAY set to $DISPLAY"
echo $DISPLAY > $HOME/.currentDisplay.txt


# see ~/.git-completion.bash
GIT_PS1_SHOWDIRTYSTATE=1            # "*" when dirty
GIT_PS1_SHOWSTASHSTATE=1            # "$" when stashed
#GIT_PS1_SHOWUNTRACKEDFILES=1       # "%" untracked files
GIT_PS1_SHOWUPSTREAM="auto verbose" # also: legacy, git, svn

# standard Prompt
test -z "$PS1_org" && export PS1_org="$PS1"
PS1_mono='\u@\h:\w$(__git_ps1 " (%s)") $ '
PS1=$PS1_mono

# color version. On older bash versions (3.x?) this fails with multi-line
# editing, so either should have \n after last escape sequence or simply
# don't use it. bash-4.1.5(1) works (bash-3.2.33(1) doesn't).
if [ "$(id -u)" != "0" ]; then
  PS1_color='\[\e]0;\w\a\]\[\e[32m\]\u@\h:\[\e[33m\]\w\[\e[32m\]$(__git_ps1 " (%s)")\[\e[0m\] $ '
  PS1_color_n='\[\e]0;\w\a\]\[\e[32m\]\u@\h:\[\e[33m\]\w\[\e[32m\]$(__git_ps1 " (%s)")\[\e[0m\]\n$ '
else
  PS1_color='\[\e]0;\w\a\]\[\e[31m\]\u@\h:\[\e[33m\]\w\[\e[32m\]$(__git_ps1 " (%s)")\[\e[0m\] $ '
  PS1_color_n='\[\e]0;\w\a\]\[\e[31m\]\u@\h:\[\e[33m\]\w\[\e[32m\]$(__git_ps1 " (%s)")\[\e[0m\]\n$ '
fi
# =~ is regex and excepts xterm-256color etc.
if [[ "$TERM" =~ "xterm" || "$TERM" =~ color || "$TERM" = "rxvt-cygwin-native" ]] ; then
    [ "${BASH_VERSINFO[0]}" -ge "4" ] && PS1=$PS1_color
    # comment out next line to get monochrome propmt on bash-3.
    [ "${BASH_VERSINFO[0]}" -le "3" ] && PS1=$PS1_color_n
fi

# Safety: when there is no GIT, don't use it in prompt
if [ ! -x "`type -p git`" ] ; then
    __git_ps1() { fmt=$1 || "%s" ; printf $fmt "no git"; }
fi

# fix $VIEW<tab> switches to \$VIEW instead of /home/...
shopt -s direxpand
shopt -s cdable_vars

## disable xon/xoff to prevent ctrl-s is stoping the session
##stty -ixon
#
##xrdb -load ~/.Xdefaults

#xmodmap ~/.remapcaps
