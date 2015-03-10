# ~/.profile file by luc
# vim: spelllang=en filetype=sh
#
# This file contains code for many different systems.  As it should only be
# sourced once on login the size and complexity should not be a performance
# issue.  The code is modularized in functions which will be unset at EOF.
#
# Many thanks to these people for helpful information:
# [1] http://www.novell.com/coolsolutions/feature/11251.html
# [2] http://crunchbanglinux.org/forums/topic/1093/post-your-bashrc/
# [3] http://bodhizazen.net/Tutorials/envrc

# helper function
_profile_helper_sort_pathlike_string () {
  # remove duplicates from a colon seperated string supplied at $@
  local ret="`printf %s "$@" | \
    awk -v RS=: -v ORS=: '!path[$0]{path[$0]=1;print}'`"
  echo "${ret%:}"
}
_profile_helper_set_var_from_file () {
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
  eval export "$var=`_profile_helper_sort_pathlike_string $tmp`"
}
_profile_helper_add_to_var () {
  local varname="$1" dir
  eval local tmp=\$$varname
  shift
  for dir; do
    if [ -d "$dir" ]; then
      tmp=$dir:$tmp
    fi
  done
  eval export $varname=`_profile_helper_sort_pathlike_string "$tmp"`
}
_profile_helper_append_to_var () {
  local varname="$1" dir
  eval local tmp=\$$varname
  shift
  for dir; do
    if [ -d "$dir" ]; then
      tmp=$tmp:$dir
    fi
  done
  eval export $varname=`_profile_helper_sort_pathlike_string "$tmp"`
}
_profile_helper_export_to_launchd () {
  local var VARS
  VARS="$VARS PATH"
  VARS="$VARS MANPATH"
  VARS="$VARS INFOPATH"
  VARS="$VARS PYTHONSTARTUP"
  VARS="$VARS COPY_EXTENDED_ATTRIBUTES_DISABLE"
  VARS="$VARS LANG"
  for var in $VARS; do
    if eval "[ \"\$$var\" ]"; then
      eval launchctl setenv $var \"\$$var\"
    fi
  done
}
_profile_helper_ask_timeout () {
  # $1 the question
  # $2 the timeout (optional)
  # this function will set the variable "answer" for the caller
  local opts="-t ${2:-5}"
  echo -n "$1"
  if _profile_test_zsh; then
    read -k 1 ${=opts} answer
  elif _profile_test_bash; then
    read -n 1 $opts answer
  else
    echo ERROR >&2
    return 99
  fi
}
_profile_helper_ask_yes () {
  # $1 the question
  # $2 the timeout (optional)
  local answer=
  local question="\e[31m$1\e[m [Y|n] "
  _profile_helper_ask_timeout "$question" $2
  [ "$answer" = Y -o "$answer" = y -o "$answer" = $'\n' -o -z "$answer" ]
}
_profile_helper_ask_no () {
  # $1 the question
  # $2 the timeout (optional)
  local answer=
  local question="\e[31m$1\e[m [y|N] "
  _profile_helper_ask_timeout "$question" $2
  [ "$answer" = Y -o "$answer" = y ]
}
_profile_helper_logger () {
  logger -s -t .profile "$@"
}
_profile_helper_check_pid () {
  # check if the pid in $1 is an instance of the program given as $2
  # FIXME this is Linux specific
  [ -r /proc/$1/exe ] || return 1
  [ "`readlink /proc/$1/exe`" = "`which $2`" ]
}
_profile_test_bash () {
  # test if this shell is bash
  [ "${BASH-no}" != no ] && [ -n "$BASH_VERSION" ]
}
_profile_test_zsh () {
  # test if this shell is zsh
  [ "$ZSH_NAME" = zsh ]
}
_profile_test_ssh () {
  # test if the current shell is started from ssh
  [ -n "$SSH_CONNECTION" ]
}
_profile_shell_rc_file () {
  _profile_test_bash && _profile_source ~/.bashrc
  _profile_test_zsh  && _profile_source "$ZDOTDIR/.zshrc"
}
_profile_source () {
  if [ -r "$1" ]; then
    source "$1"
    return 0
  else
    return 1
  fi
}
_profile_export_var_from_file () {
  if _profile_source "$1"; then
    eval `cut -d = -f 1 < "$1" | xargs echo export`
    return 0
  else
    return 1
  fi
}

# functions to start programs
_profile_start_gpg_agent () {
  # This function looks for a running gpg-agent or starts one itself
  local file="${GNUPGHOME:-$HOME/.gnupg}/.gpg-agent-info"
  if [ -r "$file" ]; then
    #_profile_helper_logger Found gpg info file at "$file".
    if _profile_helper_check_pid `cut -f 2 -d : < "$file"` gpg-agent; then
      #_profile_helper_logger Found running gpg-agent.
      _profile_export_var_from_file "$file"
    else
      #_profile_helper_logger Removing lingering info file.
      rm "$file"
    fi
  fi
  if [ ! -f "$file" ]; then
    # starting the daemon
    #_profile_helper_logger Starting new gpg-agent.
    gpg-agent --daemon --write-env-file "$file"
    _profile_export_var_from_file "$file"
  fi
  # TODO is there any other way to find a daemon?
}
_profile_start_ssh_agent () {
  local file=$HOME/.ssh/.ssh-agent-info
  # first look for variables in the environment
  if [ "$SSH_AGENT_PID" -a "$SSH_AUTH_SOCK" ]; then
    #_profile_helper_logger Found lingering SSH_AGENT_PID.
    export SSH_AGENT_PID SSH_AUTH_SOCK
    if _profile_helper_check_pid $SSH_AGENT_PID ssh-agent; then
      #_profile_helper_logger Found running ssh-agent.
      return
    else
      #_profile_helper_logger Trying to kill ssh-agent.
      eval `ssh-agent -k`
    fi
  fi
  # look for a (custom) info file to source
  if [ -r "$file" ]; then
    #_profile_helper_logger Found info file at "$file".
    _profile_export_var_from_file "$file"
    if _profile_helper_check_pid $SSH_AGENT_PID ssh-agent; then
      #_profile_helper_logger Found running ssh-agent.
      return
    else
      #_profile_helper_logger Trying to kill ssh-agent.
      eval `ssh-agent -k`
    fi
  fi
  # really start ssh-agent
  #_profile_helper_logger Starting new ssh-agent.
  eval `ssh-agent`
  touch "$file"
  chmod 600 "$file"
  echo SSH_AGENT_PID=$SSH_AGENT_PID >  "$file"
  echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK >> "$file"
}
_profile_start_pop_daemon () {
  # if fetchmail is already runnng this will just awake it once and not do any
  # harm
  FETCHMAILHOME=${XDG_CONFIG_HOME:-$HOME/.config}/fetchmail \
    FETCHMAIL_INCLUDE_DEFAULT_X509_CA_CERTS=1 fetchmail
}
_profile_add_ssh_keys () {
  SSH_ASKPASS=$HOME/bin/pass-as-ssh-askpass.sh \
    ssh-add $HOME/.ssh/*id_rsa < /dev/null
}
_profile_default_profile_on_mint_linux () {
  # ~/.profile: executed by the command interpreter for login shells.
  # This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
  # exists.
  # see /usr/share/doc/bash/examples/startup-files for examples.
  # the files are located in the bash-doc package.

  # the default umask is set in /etc/profile; for setting the umask
  # for ssh logins, install and configure the libpam-umask package.
  #umask 022
  :
}
# We will now define several functions to set up the correct environment for
# different systems.
_profile_system_arch_linux () {
  :
}
_profile_system_mac_osx () {
  # do not work with ._* files
  export EDITOR='gvim.sh --editor'
  export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
  #export BROWSER=browser # script installed with brew (uses "open")
  export LANG=en_US.UTF-8
  _profile_system_mac_osx_fix_path_for_brew
  _profile_system_mac_osx_gpg_setup
}
_profile_system_mac_osx_gpg_setup () {
  local pid
  if [ -z "$GPG_AGENT_INFO" ] && which -a gpg-agent | grep -q MacGPG2; then
    pid="`launchctl list org.gpgtools.macgpg2.gpg-agent | \
      grep PID | grep --only-matching '[0-9]\+'`"
    if [ -S $HOME/.gnupg/S.gpg-agent ]; then
      export GPG_AGENT_INFO="$HOME/.gnupg/S.gpg-agent:$pid:1"
    fi
  fi
}
_profile_system_mac_osx_fix_path_for_brew () {
  # Fix PATH for OS X:  When using brew /usr/local/bin should be befor
  # /usr/bin in order for the brewed vim to override the system vim.
  if [ -x /usr/local/bin/brew ]; then
    _profile_helper_add_to_var PATH                     \
      /usr/local/bin                                    \
      /Applications/LilyPond.app/Contents/Resources/bin \
      $HOME/.cabal/bin                                  \
      $HOME/bin                                         \

    _profile_helper_append_to_var PATH /usr/local/opt/surfraw/lib/surfraw
  fi
}
_profile_system_mac_osx_env_from_file () {
  local file
  for file in ~/.config/env/*; do
    _profile_helper_set_var_from_file "${file##*/}" "$file"
  done
}
_profile_system_open_bsd () {
  PKG_PATH=ftp://ftp.spline.de/pub/OpenBSD/`uname -r`/packages/`machine -a`/
  export PKG_PATH
}
# setup for special hosts
_profile_host_math () {
  # remap capslock
  if [ -z "$SSH_CLIENT" -a -n "$DISPLAY" ]; then
    xmodmap -e "add control = Caps_Lock"
  fi

  if [ -n "$SSH_CLIENT" ]; then
    #calendar
    if ! _profile_test_zsh; then
      exec zsh
    fi
  fi
}
_profile_host_ifi () {
  :
}
_profile_host_mbp () {
  # only for Linux systems
  if ! _profile_test_ssh; then
    # moved to systemd
    #_profile_start_pop_daemon
    #_profile_start_gpg_agent
    # for mutt 1.5.23 (it will check if this variable exists)
    export GPG_AGENT_INFO='depricated since GPG 2.1'
    ###### _profile_start_ssh_agent
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" #started by systemd
    #export SSH_AUTH_SOCK=/run/user/1000/ssh-agent.socket
    if [ "$TTY" = /dev/tty1 ] && _profile_helper_ask_yes "Do you want a graphical environment?" 2; then
      #XINITRC=~/.config/xinit/xinitrc exec startx
      exec startx
    fi
  fi
}
# functions to set environment variables
_profile_export_PATH () {
  _profile_helper_add_to_var PATH                     \
    /Applications/LilyPond.app/Contents/Resources/bin \
    $HOME/.cabal/bin                                  \
    $HOME/.local/bin                                  \
    $HOME/bin                                         \

}
_profile_export_PAGER () {
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
_profile_export_DISPLAY () {
  if [ -z "$DISPLAY" ] && [ "$SSH_CLIENT" ]; then
    export DISPLAY="`echo $SSH_CLIENT | cut -f1 -d\ `:0.0"
  fi
}
_profile_export_GPG_AGENT_INFO () {
  local info="${GNUPGHOME:-$HOME}/.gpg-agent-info"
  local socket="${GNUPGHOME:-$HOME/.gnupg}/S.gpg-agent"
  # this should be system independent
  if _profile_export_var_from_file "$info"; then
    return 0
  elif [ -S "$socket" ]; then
    local pid
    pid=`pgrep gpg-agent`
    if [ `echo "$pid" | wc -l` -ne 1 ]; then
      return 1
    fi
    export GPG_AGENT_INFO="$socket:$pid:1"
    return 0
  else
    return 1
  fi
}
_profile_export_standard_env () {
  # set some widely used environment variables to default values which can be
  # overriden in the specialized functions
  export EDITOR=vim
  #export HISTSIZE=2000
  export HTMLPAGER='elinks --dump'
  #export PYTHONSTARTUP=~/.config/pystartup
}
_profile_export_special_env () {
  # force some programs to load their configuration from ~/.config
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}"
  export TIGRC_USER="$dir/tig/tigrc"
  export PASSWORD_STORE_DIR="$dir/pass"
  export GNUPGHOME="$dir/gpg"
  # see https://tlvince.com/vim-respect-xdg
  export VIMINIT='let $MYVIMRC = "'"$dir/vim/vimrc"'" | source $MYVIMRC'
  export VIMPAGER_RC="$dir/vim/vimpagerrc"
  #export GVIMINIT='let MYGVIMRC = "'"$dir/vim/gvimrc"'" | source $MYGVIMRC'
  export PENTADACTYL_INIT="source $dir/pentadactyl/pentadactylrc"
  export PENTADACTYL_RUNTIME="$dir/pentadactyl"
  export WINEPREFIX="$dir/wine"
  export RXVT_SOCKET="$dir/urxvt/urxvtd-`hostname`"
  export ELINKS_CONFDIR="$dir/elinks"
  export SCREENRC="$dir/screen/screenrc"
  export NOTMUCH_CONFIG="$dir/notmuch/config"
}
_profile_set_manpath () {
  # TODO old function from setenv.sh (osx)
  :
}
_profile_set_infopath () {
  # TODO old function from setenv.sh (osx)
  _profile_helper_add_to_var INFOPATH      \
    /usr/local/share/info                  \
    /usr/share/info                        \
    /usr/local/texlive/2012/texmf/doc/info \

}
# start setting up the environment
_profile_export_standard_env
_profile_export_PATH
_profile_export_PAGER
_profile_export_GPG_AGENT_INFO
_profile_export_DISPLAY
_profile_export_special_env

# select the correct functions for this system
case "`uname`" in
  LINUX|Linux|linux)
    # general functions first
    # detecting Linux distros: [1]
    if test -e /etc/arch-release; then
      #grep Arch < /etc/issue
      _profile_system_arch_linux
    elif test -e /etc/debian_version; then
      # Debian or derivate (Ubuntu)
      if grep -q Debian < /etc/issue; then
	: Debian GNU/Linux
      elif grep -q Ubuntu < /etc/issue; then
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
	_profile_host_math
	;;
      *.cip.ifi.lmu.de)
	_profile_host_ifi
	;;
      mbp*)
	_profile_host_mbp
	;;
    esac
    # startx ??
    ;;
  Darwin) # MacOS X
    _profile_system_mac_osx
    if [ "$1" = --launchd ] || [ "$1" = launchd ]; then
      _profile_helper_export_to_launchd
    fi
    ;;
  OpenBSD)
    _profile_system_open_bsd
    ;;
esac

# unset all functions again
unset -f $(declare -f | grep -E '^_profile_[^ ]* \(\)' | cut -f 1 -d ' ')
