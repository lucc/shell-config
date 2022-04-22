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
_profile_helper_add_to_PATH () {
  local dir
  for dir; do
    if [ -d "$dir" ]; then
      PATH=$dir:$PATH
    fi
  done
  # remove duplicates
  PATH=$(printf %s "$PATH" | awk -v RS=: -v ORS=: '!path[$0]{path[$0]=1;print}')
  PATH=${PATH%:}
}
_profile_main () {
  # Local variables for this script.
  local cdir=${XDG_CONFIG_HOME:-$HOME/.config}

  _profile_helper_add_to_PATH                         \
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
  [ -r "$cdir/netrc" ] && export NETRC=$cdir/netrc

  [ "$TTY" = /dev/tty1 ] && exec start-gui
}

_profile_main "$@"
# unset all functions again
unset -f _profile_main _profile_helper_add_to_PATH
