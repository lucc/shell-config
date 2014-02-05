# ~/.profile file by luc
# vim: spelllang=en filetype=sh
#
# This file contains code for many different systems.  As it should only be
# sourced once on login the size and complexity should not be a performance
# issue.
#
# This file MUST be interpreted by sh.  If you use zsh source it with
# $ emulate sh -c 'source ~/.profile'
#
# Many thanks to these people for helpful information:
# [1] http://www.novell.com/coolsolutions/feature/11251.html
# [2] http://crunchbanglinux.org/forums/topic/1093/post-your-bashrc/
# [3] http://bodhizazen.net/Tutorials/envrc
#
# TODO:  call the code in the correct order such that PATH is set correctly
# whenever needed.
# TODO:  parse command line to be able to call this script with arguments

# If not running interactively, don't do anything
for arg; do
  case "$arg" in
    --launchd|launchd)
      if [ `uname` = Darwin ]; then
	echo TODO >&2
      else
	echo Error: Exporting to launchd is only possible on OS X. >&2
	return 2 || exit 2
      fi
      ;;
  esac
done
if   [ `uname` = Darwin ] && [ "$1" = --launchd ]; then echo 'TODO!' >&2
elif [ -z "$PS1" ]; then return
fi

default_profile_on_mint_linux () {
  # ~/.profile: executed by the command interpreter for login shells.
  # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
  # exists.
  # see /usr/share/doc/bash/examples/startup-files for examples.
  # the files are located in the bash-doc package.

  # the default umask is set in /etc/profile; for setting the umask
  # for ssh logins, install and configure the libpam-umask package.
  #umask 022

  # if running bash
  if [ -n "$BASH_VERSION" ]; then
      # include .bashrc if it exists
      if [ -f "$HOME/.bashrc" ]; then
	  . "$HOME/.bashrc"
      fi
  fi

  # set PATH so it includes user's private bin if it exists
  if [ -d "$HOME/bin" ] ; then
      PATH="$HOME/bin:$PATH"
  fi
}
# We will now define several functions to set up the correct environment for
# different systems.
system_arch_linux () {
  :
}
system_mac_osx () {
  #for file in ~/.config/env/*; do set_var_from_file "${file##*/}" "$file"; done

  # do not work with ._* files
  export EDITOR='gvim.sh --editor'
  export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
  export BROWSER=browser # script installed with brew (uses "open")
  export LANG=en_US.UTF-8

  if [ -z "$GPG_AGENT_INFO" ] && which -a gpg-agent | grep -q MacGPG2; then
    #pid=`psgrep -n -o pid,args gpg-agent`
    #if [ "$ZSH_NAME" = zsh ]; then
    #  pid=`echo $=pid`
    #  pid=${pid%% *}
    #else
    #  pid=`echo $pid`
    #  pid=${pid% *}
    #fi
    #pid=`psgrep -n -o pid,args gpg-agent|grep -o '[0-9][0-9]\+'`
    pid="`launchctl list org.gpgtools.macgpg2.gpg-agent | \
      grep PID | grep --only-matching '[0-9]\+'`"
    if [ -S $HOME/.gnupg/S.gpg-agent ]; then
      export GPG_AGENT_INFO="$HOME/.gnupg/S.gpg-agent:$pid:1"
    fi
    unset pid
  fi
}
system_open_bsd () {
  PKG_PATH=ftp://ftp.spline.de/pub/OpenBSD/`uname -r`/packages/`machine -a`/
  export PKG_PATH
}
# setup for special hosts
host_math () {
  # remap capslock
  if [ -z "$SSH_CLIENT" -a -n "$DISPLAY" ]; then
    xmodmap -e "add control = Caps_Lock"
  fi

  if [ -n "$SSH_CLIENT" ]; then
    calendar
    exec zsh
  fi
}
host_ifi () {
  :
}
# helper function
sort_pathlike_string () {
  # remove duplicates from a colon seperated string supplied at $@
  local ret="`printf %s "$@" | \
    awk -v RS=: -v ORS=: '!path[$0]{path[$0]=1;print}'`"
  echo "${ret%:}"
}
set_var_from_file () {
  # The file should contain the values for the variable one per line. They
  # will be read in duplicates will be removed and the variable will be set
  # colon delimited.
  local var="$1" file="$2" item=
  # get the original value of the variable
  eval local tmp=\$"$var"
  cat "$file" | while read line; do
    # if line starts with # discard it
    if echo "$line" | grep '^[[:space:]]*#' >/dev/null ; then continue; fi
    if [ -z "$line" ]; then continue; fi
    # expand variable references in $line
    item="`eval echo $line`"
    # only add existing dirs
    if [ -d "$item" ]; then tmp="$item:$tmp"; fi
  done
  # remove all duplicates, export the result
  eval export "$var=`sort_pathlike_string $tmp`"
}
add_to_var () {
  local varname="$1"
  eval local tmp=\$$varname
  shift
  for dir; do
    if [ -d "$dir" ]; then
      tmp=$dir:$tmp
    fi
  done
  eval export $varname=`sort_pathlike_string "$tmp"`
}
export_to_launchd () {
  # FIXME this doesnt work
  for var in                           \
      PATH                             \
      MANPATH                          \
      INFOPATH                         \
      PYTHONSTARTUP                    \
      COPY_EXTENDED_ATTRIBUTES_DISABLE \
      LANG                             \
      ; do
    eval launchctl setenv $var \$$var
  done
}
shell_test_bash () {
  # test if this shell is bash
  [ "${BASH-no}" != no ] && [ -n "$BASH_VERSION" ]
}
shell_test_zsh () {
  # test if this shell is zsh
  [ "$ZSH_NAME" = zsh ]
}
source_rc_file () {
  shell_test_bash && [ -r ~/.bashrc ]         && source ~/.bashrc
  shell_test_zsh  && [ -r "$ZDOTDIR/.zshrc" ] && source "$ZDOTDIR/.zshrc"
}
# functions to set environment variables
export_PATH () {
  add_to_var PATH                                     \
    /Applications/LilyPond.app/Contents/Resources/bin \
    $HOME/.cabal/bin                                  \
    $HOME/bin                                         \
}
export_PAGER () {
  if which vimpager >/dev/null 2>&1; then
    export PAGER=vimpager
  else
    # TODO
    unset PAGER
    # default pager program should be "less"
    # FIXME this is bash syntax. zsh and sh seem to accept it as well.
    export LESS_TERMCAP_mb=$'\033[01;31m'      # begin blinking
    export LESS_TERMCAP_md=$'\033[01;31m'      # begin bold
    export LESS_TERMCAP_me=$'\033[0m'          # end mode
    export LESS_TERMCAP_se=$'\033[0m'          # end standout-mode
    export LESS_TERMCAP_so=$'\033[01;44m'      # begin standout-mode/info box
    export LESS_TERMCAP_ue=$'\033[0m'          # end underline
    export LESS_TERMCAP_us=$'\033[01;33m'      # begin underline
    LESS=
    LESS="$LESS --ignore-case"
    LESS="$LESS --LINE-NUMBERS"
    LESS="$LESS --hilite-unread"
    LESS="$LESS --window=-4"
    LESS="$LESS --hilite-search"
    LESS="$LESS --LONG-PROMPT"
    LESS="$LESS --no-init"
    LESS="$LESS --quit-if-one-screen"
    LESS="$LESS --RAW-CONTROL-CHARS"
    LESS="$LESS --prompt=%t?f%f"
    # FIXME: What is this for?
    LESS="$LESS \\"
    export LESS
  fi
}
export_DISPLAY () {
  if [ -z "$DISPLAY" ] && [ "$SSH_CLIENT" ]; then
    export DISPLAY="`echo $SSH_CLIENT | cut -f1 -d\ `:0.0"
  fi
}
export_GPG_AGENT_INFO () {
  # this should be system independent
  if [ -r "$HOME/.gpg-agent-info" ]; then
    . "$HOME/.gpg-agent-info"
    export GPG_AGENT_INFO
    #export SSH_AUTH_SOCK
    GPG_TTY="`tty`"
  fi
}
export_standard_env () {
  # set some widely used environment variables to default values which can be
  # overriden in the specialized functions
  export EDITOR=vim
  export HISTSIZE=2000
  export HTMLPAGER='elinks --dump'
  export PYTHONSTARTUP=~/.config/shell/pystartup
}
set_manpath () {
  # TODO old function from setenv.sh (osx)
  :
}
set_infopath () {
  # TODO old function from setenv.sh (osx)
  add_to_var INFOPATH                      \
    /usr/local/share/info                  \
    /usr/share/info                        \
    /usr/local/texlive/2012/texmf/doc/info \

}
# start setting up the environment
export_standard_env
export_PATH
export_PAGER
export_GPG_AGENT_INFO
export_DISPLAY

# select the correct functions for this system
case "`uname`" in
  LINUX|Linux|linux)
    # general functions first
    # detecting Linux distros: [1]
    if test -e /etc/arch-release; then
      #grep Arch < /etc/issue
      : Arch Linux
    elif test -e /etc/debian_version; then
      # Debian or derivate (Ubuntu)
      if grep Debian < /etc/issue; then
	: Debian GNU/Linux
      elif grep Ubuntu < /etc/issue; then
	: Ubuntu
      else
	: unknown Debian
      fi
    else
      : unknown Linux
    fi
    # set up the host specific environment
    case "`hostname --long`" in
      cip*.cipmath.loc)
	host_math
	;;
      *.cip.ifi.lmu.de)
	host_ifi
	;;
    esac
    # startx ??
    ;;
  Darwin) # MacOS X
    system_mac_osx
    if [ "$1" = --launchd ] || [ "$1" = launchd ]; then
      export_to_launchd
    fi
    ;;
  OpenBSD)
    system_open_bsd
    ;;
esac

# unset all functions again
# FIXME:
# This list can be automated with
#   unset -f `grep '^.* () {$' "$0" | cut -f 1 -d \(`
# with the only problem that $0 only works in executed scripts and there
# doesn't seem to be an equivalent for sourced scripts.
unset -f                        \
  add_to_var                    \
  default_profile_on_mint_linux \
  export_DISPLAY                \
  export_GPG_AGENT_INFO         \
  export_PAGER                  \
  export_PATH                   \
  export_standard_env           \
  export_to_launchd             \
  host_ifi                      \
  host_math                     \
  set_infopath                  \
  set_manpath                   \
  set_var_from_file             \
  shell_test_bash               \
  shell_test_zsh                \
  sort_pathlike_string          \
  source_rc_file                \
  system_arch_linux             \
  system_mac_osx                \
  system_open_bsd               \
