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
  local ret=$(printf %s "$@" | \
    awk -v RS=: -v ORS=: '!path[$0]{path[$0]=1;print}')
  echo "${ret%:}"
}
_profile_helper_add_to_var () {
  local varname=$1 dir
  eval local tmp=\$$varname
  shift
  for dir; do
    if [ -d "$dir" ]; then
      tmp=$dir:$tmp
    fi
  done
  eval export $varname=$(_profile_helper_sort_pathlike_string "$tmp")
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
_profile_test_ssh () {
  # test if the current shell is started from ssh
  [ -n "$SSH_CONNECTION" ]
}
# functions to set up terminal colors on the linux vconsole
_profile_colors_original_from_unix_se () {
  # taken from http://unix.stackexchange.com/questions/55423, many thanks
  # to mulllhausen
  echo -en "\e]P0000000" #black
  echo -en "\e]P1D75F5F" #darkred
  echo -en "\e]P287AF5F" #darkgreen
  echo -en "\e]P3D7AF87" #brown
  echo -en "\e]P48787AF" #darkblue
  echo -en "\e]P5BD53A5" #darkmagenta
  echo -en "\e]P65FAFAF" #darkcyan
  echo -en "\e]P7E5E5E5" #lightgrey
  echo -en "\e]P82B2B2B" #darkgrey
  echo -en "\e]P9E33636" #red
  echo -en "\e]PA98E34D" #green
  echo -en "\e]PBFFD75F" #yellow
  echo -en "\e]PC7373C9" #blue
  echo -en "\e]PDD633B2" #magenta
  echo -en "\e]PE44C9C9" #cyan
  echo -en "\e]PFFFFFFF" #white
}
_profile_colors_basic_solarized_dark () {
  # taken from http://unix.stackexchange.com/questions/55423, many thanks
  # to mulllhausen
  echo -en "\E]P0002b36" #black
  echo -en "\E]P1dc322f" #darkred
  echo -en "\E]P2859900" #darkgreen
  echo -en "\E]P3b58900" #brown
  echo -en "\E]P4268bd2" #darkblue
  echo -en "\E]P5d33682" #darkmagenta
  echo -en "\E]P62aa198" #darkcyan
  echo -en "\E]P7eee8d5" #lightgrey
  echo -en "\E]P8002b36" #darkgrey
  echo -en "\E]P9cb4b16" #red
  echo -en "\E]PA586e75" #green
  echo -en "\E]PB657b83" #yellow
  echo -en "\E]PC839496" #blue
  echo -en "\E]PD6c71c4" #magenta
  echo -en "\E]PE93a1a1" #cyan
  echo -en "\E]PFfdf6e3" #white
  clear
}
# We will now define several functions to set up the correct environment for
# different systems.
_profile_system_mac_osx () {
  # do not work with ._* files
  export EDITOR='gvim.sh --editor'
  export COPY_EXTENDED_ATTRIBUTES_DISABLE=true
  #export BROWSER=browser # script installed with brew (uses "open")
  export LANG=en_US.UTF-8
}
_profile_system_open_bsd () {
  PKG_PATH=ftp://ftp.spline.de/pub/OpenBSD/$(uname -r)/packages/$(machine -a)/
  export PKG_PATH
}
# setup for special hosts
_profile_start_gui () {
  # only for Linux systems
  if ! _profile_test_ssh; then
    # started by systemd
    export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/ssh-agent.socket
    if
      [ "$TTY" = /dev/tty1 ] && \
      [ ! -e "$XDG_RUNTIME_DIR/gui-login-done" ] && \
      grep -qv lucas=nogui /proc/cmdline
    then
      touch "$XDG_RUNTIME_DIR/gui-login-done"
      exec startx "$cdir/xinit/xinitrc"
      #exec "$cdir/sway/bin/start-sway.sh"
    fi
  fi
}
# functions to set environment variables
_profile_export_PATH () {
  _profile_helper_add_to_var PATH                     \
    $NPM_PACKAGES                                     \
    /Applications/LilyPond.app/Contents/Resources/bin \
    $HOME/.config/composer/vendor/bin                 \
    $HOME/.cabal/bin                                  \
    $HOME/.cargo/bin                                  \
    $HOME/.gem/ruby/*/bin(N[1])                       \
    $HOME/.luarocks/bin                               \
    $HOME/.local/bin                                  \
    $HOME/bin                                         \

}
_profile_export_PAGER () {
  export PAGER=nvimpager
}
_profile_export_DISPLAY () {
  if [ -z "$DISPLAY" ] && [ "$SSH_CLIENT" ]; then
    export DISPLAY=$(echo $SSH_CLIENT | cut -f1 -d\ ):0.0
  fi
}
_profile_export_standard_env () {
  # set some widely used environment variables to default values which can be
  # overriden in the specialized functions
  export EDITOR=nvim
  #export HISTSIZE=2000
  export HTMLPAGER='elinks --dump'
  export PYTHONSTARTUP=$cdir/python/init.py
}
_profile_export_special_env () {
  # force some programs to load their configuration from ~/.config
  export PASSWORD_STORE_DIR=$cdir/pass
  export PASSWORD_STORE_ENABLE_EXTENSIONS=true
  export GNUPGHOME=$cdir/gpg
  #export VIMPAGER_RC=$cdir/nvim/vimpagerrc
  export WINEPREFIX=$ddir/wine
  export ELINKS_CONFDIR=$cdir/elinks
  #export SCREENRC=$dir/screen/screenrc
  export NOTMUCH_CONFIG=$cdir/notmuch/config
  [ -r "$cdir/netrc" ] && export NETRC=$cdir/netrc
  export FZF_DEFAULT_OPTS="--inline-info --cycle"
  export RLWRAP_HOME=$ddir/rlwrap
}
_profile_export_less_env () {
  LESSKEY=$cdir/less/lesskey
  if [ -r "$LESSKEY" ]; then
    export LESSKEY
    make --quiet -C "$cdir/less" lesskey
  fi
  # FIXME this is bash syntax. zsh and sh seem to accept it as well.
  export LESS_TERMCAP_mb=$'\033[01;31m'    # begin blinking
  export LESS_TERMCAP_md=$'\033[01;31m'    # begin bold
  export LESS_TERMCAP_me=$'\033[0m'        # end mode
  export LESS_TERMCAP_se=$'\033[0m'        # end standout-mode
  export LESS_TERMCAP_so=$'\033[01;44m'    # begin standout-mode/info box
  export LESS_TERMCAP_ue=$'\033[0m'        # end underline
  export LESS_TERMCAP_us=$'\033[01;33m'    # begin underline
}
_profile_export_systemctl_env () {
  #export SYSTEMD_PAGER=less
  #_profile_export_less_env
  export SYSTEMD_PAGER=
}
_profile_main () {
  # Local variables for this script.
  local cdir=${XDG_CONFIG_HOME:-$HOME/.config}
  local ddir=${XDG_DATA_HOME:-$HOME/.local/share}

  # start setting up the environment
  _profile_export_standard_env
  # https://github.com/sindresorhus/guides/blob/master/npm-global-without-sudo.md
  if [ -d "$ddir/npm" ]; then
    export NPM_PACKAGES=$ddir/npm
  fi
  _profile_export_PATH
  _profile_export_DISPLAY
  _profile_export_special_env
  #_profile_export_systemctl_env

  # select the correct functions for this system
  case $(uname) in
    LINUX|Linux|linux)
      # set up the host specific environment
      case $(hostname) in
	tp*)
	  _profile_export_PAGER
	  export TASKRC=~/.config/taskwarrior/tp
	  _profile_start_gui;;
	yoga)
	  export TASKRC=~/.config/taskwarrior/yoga
	  [ "$TTY" = /dev/tty1 ] && exec startx "$cdir/xinit/xinitrc";;
      esac
      ;;
    Darwin) # MacOS X
      _profile_system_mac_osx
      if [ "$1" = --launchd ] || [ "$1" = launchd ]; then
	_profile_helper_export_to_launchd
      fi
      ;;
    OpenBSD) _profile_system_open_bsd;;
  esac
}

_profile_main "$@"
# unset all functions again
unset -f $(declare -f | grep -E '^_profile_[^ ]* \(\)' | cut -f 1 -d ' ')
