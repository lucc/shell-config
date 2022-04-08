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
_profile_test_ssh () {
  # test if the current shell is started from ssh
  [ -n "$SSH_CONNECTION" ]
}
_profile_main () {
  # Local variables for this script.
  local cdir=${XDG_CONFIG_HOME:-$HOME/.config}
  local ddir=${XDG_DATA_HOME:-$HOME/.local/share}

  # start setting up the environment
  # https://github.com/sindresorhus/guides/blob/master/npm-global-without-sudo.md
  if [ -d "$ddir/npm" ]; then
    export NPM_PACKAGES=$ddir/npm
  fi

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

  if [ -z "$DISPLAY" ] && [ "$SSH_CLIENT" ]; then
    export DISPLAY=$(echo $SSH_CLIENT | cut -f1 -d\ ):0.0
  fi

  # force some programs to load their configuration from ~/.config
  export WINEPREFIX=$ddir/wine
  [ -r "$cdir/netrc" ] && export NETRC=$cdir/netrc

  # set up the host specific environment
  case $(hostname) in
    tp*)
      _profile_export_PAGER
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
    yoga)
      [ "$TTY" = /dev/tty1 ] && exec startx "$cdir/xinit/xinitrc";;
  esac
}

_profile_main "$@"
# unset all functions again
unset -f $(declare -f | grep -E '^_profile_[^ ]* \(\)' | cut -f 1 -d ' ')
