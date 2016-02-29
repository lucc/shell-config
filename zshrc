# file:    zshrc                                                          {{{1
# author:  luc
# vim:     foldmethod=marker
# credits: many thanks to the people from
#          http://aperiodic.net/phil/prompt
#          http://briancarper.net/blog/570
#          http://crunchbang.org/forums/viewtopic.php?id=4062
#          http://serverfault.com/questions/170346
#          http://stevelosh.com/blog/2010/02/my-extravagant-zsh-prompt
#          http://www.sourceguru.net/ssh-host-completion-zsh-stylee
#          https://maze.io/2008/08/03/remote-tabcompletion-using-openssh-and-zsh
#          http://grml.org/zsh-pony
# and the zsh manual:
#          http://zsh.sourceforge.net/Doc/
# README:  This file is modularized in many functions which are called if
#          apropriate at the end and then unset at EOF.
# TODO:    use random variable for function names:
#          fun_prefix=$(hexdump -xn16 /dev/random | head -n 1 | sed 's/ /-/g')
# TODO:    autoload -U throw catch

# helper functions {{{1

function zrc-test-osx () { # {{{2
  [[ $ZRC_UNAME == Darwin ]]
}

function zrc-test-linux () { # {{{2
  [[ $ZRC_UNAME == (#i)linux ]]
}

function zrc-source () { # {{{2
  if [[ -r $1 ]]; then
    source $1
    return 0
  else
    return 1
  fi
}

function zrc-run-exit-hooks () { # {{{2
  local f
  for f in $ZRC_AT_EXIT_FUNCTIONS; do
    $f
    unfunction $f
  done
}

function zrc-has-color () { # {{{2
  # return true if the terminal can handle colors
  if [[ $TERM == dump ]]; then
    return 1
  else
    return 0
  fi
}

function zrc-add-exit-hook () { # {{{2
  ZRC_AT_EXIT_FUNCTIONS+=$1
}

function zrc-vi-bindkey () { # {{{2
  # bind the given key to the given function in the viins and vicmd maps
  bindkey -M viins $1 $2
  bindkey -M vicmd $1 $2
}

function zrc-filter-existing () { # {{{2
  # print all the arguments that exist (test -e)
  for arg; do
    if [[ -e $arg ]]; then
      printf %s $arg
    fi
  done
  print
}

# local variables {{{1

ZRC_UNAME=$(uname)
# Will expand to the nullstring if we are not on Mac OS X or brew is not
# installed.
ZRC_PREFIX=$(brew --prefix 2>/dev/null)
# an array of functions to be called at exit
typeset -a ZRC_AT_EXIT_FUNCTIONS

# functions to set up basic zsh options {{{1

function zrc-history-options () { # {{{2
  HISTFILE=${XDG_CACHE_HOME:-~/.cache}/zsh/history
  HISTSIZE=15000
  SAVEHIST=10000
  setopt hist_ignore_all_dups
  setopt hist_expire_dups_first
  setopt hist_find_no_dups
  setopt hist_reduce_blanks
  setopt hist_save_no_dups
  setopt hist_ignore_space
  #setopt hist_verify
  setopt share_history
  setopt extended_history
}

function zrc-misc-options () { # {{{2
  setopt extended_glob
  setopt no_no_match
  setopt prompt_subst
}

function zrc-interesting-options () { # {{{2
  setopt auto_cd
  setopt glob_dots
  #setopt print_exit_value
  setopt no_list_ambiguous
  #setopt correct_all
}

# functions to set up key bindings {{{1

function zrc-keymap () { # {{{2
  bindkey -v
  typeset -g -A key
  zrc-keys-terminfo
  zrc-keys-manual-corrections
  zrc-bind-basic-keys
  zrc-history-substring-search-keys
  zrc-keys-edit-command-line
  zrc-search-keys
  zrc-push-zle-buffer-keys
}

function zrc-keys-terminfo () { # {{{2
  zmodload zsh/terminfo
  # plain arrows
  key[Up]=$terminfo[kcuu1]
  key[Down]=$terminfo[kcud1]
  key[Left]=$terminfo[kcub1]
  key[Right]=$terminfo[kcuf1]
  # shifted arrows
  key[ShiftUp]=$terminfo[kPRV]   # TODO not right in urxvt
  key[ShiftDown]=$terminfo[kNXT] # TODO not right in urxvt
  key[ShiftLeft]=$terminfo[kLFT]
  key[ShiftRight]=$terminfo[kRIT]
  # fn-arrows
  key[PageUp]=$terminfo[kpp]
  key[PageDown]=$terminfo[knp]
  key[Home]=$terminfo[khome]
  key[End]=$terminfo[kend]
  # shifted fn-arrows
  key[ShiftPageUp]=  # Not possible?
  key[ShiftPageDown]=  # Not possible?
  key[ShiftHome]=$terminfo[kHOME]
  key[ShiftEnd]=$terminfo[kEND]
  # delete and such
  key[Backspace]=$terminfo[kbs]
  key[Delete]=$terminfo[kdch1]
  key[ShiftBackspace]= # TODO
  key[ShiftDelete]=$terminfo[kDC] # TODO
}

function zrc-keys-manual-corrections () { # {{{2
  # Collection of conditions and corrections for errors with terminfo
  if zrc-test-linux; then
    if [[ -n $MYVIMRC && $VIM = *nvim* && $VIMRUNTIME = *nvim* ]]; then
      zrc-keys-manual-corrections-nvim
    elif [[ $TERM == urxvt || $TERM == rxvt-unicode-256color ]]; then
      key[ShiftUp]='\e[a'
      key[ShiftDown]='\e[b'
    elif [[ -n $TMUX ]]; then
      zrc-keys-manual-corrections-tmux
    elif [[ $TERM == xterm ]]; then
      zrc-keys-manual-corrections-xterm
    fi
  elif zrc-test-osx; then
    zrc-keys-manual-corrections-xterm
  else
    echo Unknown system: $ZRC_UNAME >&2
    return
  fi
}

function zrc-keys-manual-corrections-tmux () { # {{{2
  key[Up]='\e[A'
  key[Down]='\e[B'
  # this needs the tmux option "xterm-keys" set to "on"
  key[ShiftUp]='\e[1;2A'
  key[ShiftDown]='\e[1;2B'
  key[ShiftLeft]='\e[1;2D'
  key[ShiftRight]='\e[1;2C'
}

function zrc-keys-manual-corrections-xterm () { # {{{2
  key[Up]='\e[A'
  key[Down]='\e[B'
  key[Home]='\e[H'
  key[End]='\e[F'
  key[ShiftUp]='\e[1;2A'
  key[ShiftDown]='\e[1;2B'
}

function zrc-keys-manual-corrections-nvim () { # {{{2
  # function keys
  key[F1]='\U7fffce95'
  key[F2]='\U7fffcd95'
  key[F3]='\U7fffcc95'
  key[F4]='\U7fffcb95'
  key[F5]='\U7fffca95'
  key[F6]='\U7fffc995'
  key[F7]='\U7fffc895'
  key[F8]='\U7fffc795'
  key[F9]='\U7fffc695'
  key[F10]='\U7fffc495'
  key[F11]='\U7fffceba'
  key[F12]='\U7fffcdba'
  # plain arrows
  key[Up]='\e[A'
  key[Down]='\e[B'
  # shifted arrows
  #key[ShiftUp]=   # not possible?
  #key[ShiftDown]= # not possible?
  key[ShiftLeft]='\U7fffcbdd'  # problematic?
  key[ShiftRight]='\U7fff96db' # problematic?
  # fn-arrows
  key[Home]='\e[H'
  key[End]='\e[F'
  # shifted fn-arrows
  key[ShiftPageUp]=    # Not possible? (used by the terminal)
  key[ShiftPageDown]=  # Not possible?
  key[ShiftHome]='\U7fffcddd'
  key[ShiftEnd]='\U7fffc8d6'
  # delete and such
  key[Delete]='\e[3~'
  key[ShiftBackspace]= # TODO
  key[ShiftDelete]='\U7fffcbd6'
}

function zrc-keys-ssh () { # {{{2
  key[Home]='\e[H'
  key[End]='\e[F'
  key[ShiftRight]='\e[1;2C'
  key[ShiftLeft]='\e[1;2D'
}

function zrc-bind-basic-keys () { # {{{2
  zrc-vi-bindkey $key[Up]         up-line-or-search
  zrc-vi-bindkey $key[Down]       down-line-or-search
  zrc-vi-bindkey $key[Home]       beginning-of-line
  zrc-vi-bindkey $key[End]        end-of-line
  zrc-vi-bindkey $key[ShiftLeft]  vi-backward-word
  zrc-vi-bindkey $key[ShiftRight] vi-forward-word
}

function zrc-history-substring-search-keys () { # {{{2
  zrc-source /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh || \
    zrc-source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh || \
    return
  zrc-vi-bindkey $key[ShiftUp]   history-substring-search-up
  zrc-vi-bindkey $key[ShiftDown] history-substring-search-down
}

function zrc-search-keys () { # {{{2
  zrc-vi-bindkey '\C-r' history-incremental-pattern-search-backward
  zrc-vi-bindkey '\C-s' history-incremental-pattern-search-forward
}

function zrc-keys-edit-command-line () { # {{{2
  autoload edit-command-line
  zle -N edit-command-line
  bindkey '\ee' edit-command-line
}

function zrc-push-zle-buffer-keys () { # {{{2
  zrc-vi-bindkey '\C-p' push-input
  zrc-vi-bindkey '\C-o' push-line
}

# prompt related functions {{{1

function zrc-execution-timer () { # {{{2
  autoload -Uz add-zsh-hook
  # define the needed variables
  typeset -ig _threshold=10
  typeset -ig _start=0
  # define the needed function
  function execution-time-helper-function () {
    (( _start = $SECONDS ))
    (( _threshold = _start + 10 ))
  }
  # add the function to a hook
  add-zsh-hook preexec execution-time-helper-function
}

# functions to set up the vsc_info plugin for the prompt {{{1

function zrc-vcs-info-zstyle () { # {{{2
  zstyle ':vcs_info:*' actionformats '%F{cyan}%s%F{green}%c%u%b%F{blue}%a%f'
  ####TODO
  zstyle ':vcs_info:*' formats       '%F{cyan}%s%F{green}%c%u%b%f'
  zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
  zstyle ':vcs_info:*' enable git svn cvs hg
  # change color if changes exist (with %c and %u)
  zstyle ':vcs_info:*' check-for-changes true
  zstyle ':vcs_info:*' stagedstr '%F{yellow}'
  zstyle ':vcs_info:*' unstagedstr '%F{red}'
}

function zrc-vcs-info-setup () { # {{{2
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  add-zsh-hook precmd vcs_info
}

function zrc-vcs-info-hooks () { # {{{2
  function +vi-git-string() {
    # turn the name 'git' into '±'
    hook_com[vcs]='±'
  }
  function +vi-hg-string() {
    hook_com[vcs]='☿'
  }
  function +vi-git-add-untracked-files () {
    # Add information about untracked files to the branch information
    # idea from http://briancarper.net/blog/570
    if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
      hook_com[branch]+='%F{red}?%f'
    fi
  }
  # register the functions with the correct hooks
  zstyle ':vcs_info:git+set-message:*' hooks \
    git-add-untracked-files                  \
    git-string                               \

  zstyle ':vcs_info:hg+set-message:*' hooks hg-string
}

# prompt versions {{{1

function zrc-full-colour-ps1 () { # {{{2
  PS1='[ '                                              # frame
  PS1+='%(!.%F{red}.%F{green})'                         # user=green, root=red
  PS1+='%n%F{cyan}@%F{blue}%m%f'                        # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%F{cyan}%1~%f'                                  # working directory
  PS1+=' | '                                            # delimiter
  PS1+='${vcs_info_msg_0_:+$vcs_info_msg_0_ | }'        # VCS info with delim.
  PS1+='%D{%H:%M:%S}'                                   # current time
  PS1+=' ] '                                            # frame
  zrc-vcs-info-zstyle
  zrc-vcs-info-hooks
  zrc-vcs-info-setup
}

function zrc-stand-alone-colour-ps1 () { # {{{2
  PS1='[ '                                              # frame
  PS1+='%(!.%F{red}.%F{green})'                         # user=green, root=red
  PS1+='%n%F{cyan}@%F{blue}%m%f'                        # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%F{cyan}%1~%f'                                  # working directory
  PS1+=' | '                                            # delimiter
  PS1+='${vcs_info_msg_0_:+$vcs_info_msg_0_ | }'        # VCS info with delim.
  PS1+='%(?.%D{%H:%M:%S}.%F{red}Error %?%f)'            # curren time or error
  PS1+=' ] '                                            # frame
  zrc-vcs-info-zstyle
  zrc-vcs-info-hooks
  zrc-vcs-info-setup
}

function zrc-stand-alone-monochrome-ps1 () { # {{{2
  PS1='[ '                                              # frame
  PS1+='%n@%m'                                          # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%1~'                                            # working directory
  PS1+=' | '                                            # delimiter
  PS1+='%(?.%D{%H:%M:%S}.Error %?)'                     # curren time or error
  PS1+=' ] '                                            # frame
}

function zrc-full-colour-rps1 () { # {{{2
  RPROMPT='%(?.'                                   # if $? == 0
  RPROMPT+='%(${_threshold}S.'                     #   if _threshold < SECONDS
  RPROMPT+='%F{yellow}'                            #     switch color
  RPROMPT+='Time: $((SECONDS-_start))%f'           #     duration of command
  RPROMPT+='.)'                                    #   else, fi
  if zrc-test-osx; then                            #   if OS X
    RPROMPT+=' $(battery.sh -bce zsh)'             #     battery information
  fi                                               #   fi
  RPROMPT+='.'                                     # else
  RPROMPT+='%F{yellow}'                            #   switch color
  RPROMPT+='Time: $((SECONDS-_start)) '            #   duration of command
  RPROMPT+='%F{red}'                               #   switch color
  RPROMPT+='Error: %?'                             #   error message
  RPROMPT+=')'                                     # fi
  zrc-execution-timer
}

function zrc-condensed-color-ps1 () { # {{{2
  PS1=
  if [[ -n $SSH_CONNECTION ]]; then
    PS1+='%(!.%F{red}.%F{green})'                         # user=green, root=red
    PS1+='%n%F{cyan}@%F{blue}%m%f:'                       # user and host info
  else
    PS1+='%(!.%F{red}%n%F{cyan}@%F{blue}%m%f:.)'          # user=green, root=red
  fi
  PS1+='%F{cyan}%1~%f'                                  # working directory
  PS1+='${vcs_info_msg_0_:+($vcs_info_msg_0_)}'        # VCS info with delim.
  PS1+='%# '
  zrc-vcs-info-zstyle
  zrc-vcs-info-hooks
  zrc-vcs-info-setup
}

# functions to set up zsh special variables {{{1

function zrc-module-path () { # {{{2
  module_path=($module_path /usr/local/lib/zpython)
}

function zrc-fignore () { # {{{2
  # file endings to ignore for completion
  fignore=($fignore '~' .o .bak '.sw?')
}

function zrc-zle-highlighting () { # {{{2
  # zle stuff
  zle_highlight=(region:bg=green special:bg=blue suffix:fg=red isearch:fg=yellow)
}

function zrc-fpath () { # {{{2
  local trypath
  # functions for completion and user defined functions
  for trypath in                              \
      /usr/local/share/zsh-completions        \
      ~/.homesick/repos/homeshick/completions \
      $ZDOTDIR/functions                      \
    ; do
    if [[ -d $trypath ]]; then
      fpath=($trypath $fpath)
    fi
  done
  #fpath=($(zrc-filter-existing $fpath))
}

# functions to set up the run-help function {{{1

function zrc-install-run-help () { # {{{2
  mkdir $HELPDIR
  perl ~/vcs/zsh-code/Util/helpfiles zshall $HELPDIR
}

function zrc-compile-run-help-sed-helper () { # {{{2
  sed -e \
    '$ {
       s/^.*See the section `\(.*\). in zsh\([a-z]*\)(1)\.$/manpage=zsh\2 regexp="\1"/
       s/\\/\\\\/g
       s/\//\\\//g
     }'
}

function zrc-compile-run-help-perl-helper () { # {{{2
  perl -n \
    -e 'if ( /^'$1'/i ) {
          $on=1
	  print
	  next
	}
	if ($on) {
	  last if /^[A-Z]/
	  print
	}'
}

function zrc-compile-run-help () { # {{{2
  local file manpage regexp
  grep -l 'See the section .* in zsh[a-z]*([0-9])\.' $HELPDIR/* | \
    while read file; do
      eval $(zrc-compile-run-help-sed-helper $file)
      man $manpage | colcrt - | \
	zrc-compile-run-help-perl-helper $regexp > ${file#./}.tmp
  done

  for file in $HELPDIR/*.tmp; do
    echo >> ${file%.tmp}
    cat $file >> ${file%.tmp}
  done
  rm $HELPDIR/*.tmp
}

function zrc-run-help () { # {{{2
  autoload -Uz run-help
  unalias run-help
  HELPDIR=${XDG_DATA_HOME:-~/.local/share}/zsh/help
  bindkey -M viins '\C-xh' run-help
  bindkey -M vicmd '\C-xh' run-help
  # install the files when needed
  if [[ ! -d $HELPDIR ]]; then
    ( zrc-install-run-help && \
        zrc-compile-run-help ) &
  fi
  # further helper functions
  autoload run-help-git
  autoload run-help-openssl
  autoload run-help-sudo
  function run-help-ssh () {
    emulate -LR zsh
    local -a args
    # Delete the "-l username" option
    zparseopts -D -E -a args l:
    # Delete other options, leaving: host command
    args=(${@:#-*})
    if [[ ${#args} -lt 2 ]]; then
      man ssh
    else
      run-help $args[2]
    fi
  }
}

# functions to set xxx {{{1

function zrc-directory-hash-table () { # {{{2
  #hash -d i=~/Pictures
  #hash -d m=~/Music
  hash -d t=~/tmp
  hash -d u=~/uni
  hash -d v=/Volumes
  hash -d p=~/uni/philosophie
  hash -d y=~/.homesick/repos/secure/yaml
}

function zrc-autoloading () { # {{{2
  autoload -Uz colors && colors
  #autoload -Uz checkmail
  # autoloading user defined functions
  autoload -Uz $ZDOTDIR/functions/*(:t)
}

function zrc-zmodload () { # {{{2
  zmodload zsh/sched
  zmodload zsh/zprof
  #zmodload zsh/zpython
}

function zrc-source-files () { # {{{2
  local file
  for file in $ZDOTDIR/aliases; do
    zrc-source $file
  done
}

function zrc-lesspipe () { # {{{2
  ## make less more friendly for non-text input files, see lesspipe(1)
  if whence -p lesspipe &>/dev/null; then
    eval "$(lesspipe)"
  elif whence -p lesspipe.sh &>/dev/null; then
    eval "$(lesspipe.sh)"
  fi
}

function zrc-autojump () { # {{{2
  #export AUTOJUMP_KEEP_SYMLINKS=1
  zrc-source /usr/share/autojump/autojump.zsh  || \
    zrc-source /usr/share/autojump/autojump.sh || \
    zrc-source $ZRC_PREFIX/etc/autojump.sh     || \
    zrc-source /etc/profile.d/autojump.zsh
}

function zrc-rupa-z () { # {{{2
  if [[ -r $ZRC_PREFIX/etc/profile.d/z.sh ]]; then
    autoload -Uz add-zsh-hook
    # read man z
    export _Z_DATA=~/.cache/z
    _Z_CMD=j source $ZRC_PREFIX/etc/profile.d/z.sh
    add-zsh-hook chpwd _z_precmd
    unalias j
    function j () {
      _z $@ 2>&1 && echo ${fg[red]}`pwd`$reset_color
    }
    function j-completion-at-exit-function () {
      compctl -U -K _z_zsh_tab_completion j
    }
    zrc-add-exit-hook j-completion-at-exit-function
  fi
}

function zrc-autojump-decision () { # {{{2
  if which autojump >/dev/null 2>&1; then
    zrc-autojump
  # TODO How to find rupa's z?
  elif which hans; then
    zrc-rupa-z
  fi
}

function zrc-syntax-highlighting () { # {{{2
  local -a locations
  local location
  case $ZRC_UNAME in
    Darwin)
      location=$ZRC_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ;;
    Linux)
      location=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ;;
  esac
  zrc-source $location
}

function zrc-homeshick () { # {{{2
  # homesick for automatic dotfiles setup
  zrc-source ~/.homesick/repos/homeshick/homeshick.sh
}

function zrc-gpg-setup () { # {{{2
  export GPG_TTY=$(tty)
}

function zrc-zsh-mime-handling-setup () { # {{{2
  autoload zsh-mime-setup
  zsh-mime-setup
}

# other {{{1

function zrc-calcurse-notifications () { # {{{2
  calcurse                                \
    --todo                                \
    --range=3                             \
    --format-{recur-,}apt='%S  %m\n'      \
    --format-{recur-,}event='*****  %m\n'
}

function zrc-khal-notifications () { # {{{2
  #make --quiet -C ~/.config/khal
  [[ -x =khal ]] && khal
}

function zrc-print-todo-items-from-notmuch () { # {{{2
  notmuch search --format=json tag:todo | jq --raw-output '.[].subject'
}

function zrc-todo-from-bashrc () { # {{{2
  # this and dircolors in general
  if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
  fi
}

# functions to set up completion {{{1

function zrc-zstyle-layout () { # {{{2
  zstyle ':completion:*' list-prompt \
    %SAt %p: Hit TAB for more, or the character to insert%s
  zstyle ':completion:*' auto-description 'specify: %d'
  zstyle ':completion:*' file-sort name
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*' menu select=long
  zstyle ':completion:*' select-prompt \
    %SScrolling active: current selection at %p%s
}

function zrc-zstyle-performemce () { # {{{2
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-~/.cache}/zsh/completion
}

function zrc-zstyle-other () { # {{{2
  zstyle ':completion:*' completer _expand _complete _ignored
  zstyle ':completion:*' expand prefix suffix
  zstyle ':completion:*' special-dirs ..
  zstyle ':completion:*' ignore-parents parent pwd ..
  #TODO
  #zstyle ':completion:*:cd:*' ignored-patterns .
  zstyle ':completion:*' list-suffixes true
  zstyle ':completion:*' matcher-list \
    '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
  zstyle ':completion:*' original false
  zstyle ':completion:*' squeeze-slashes true
  zstyle ':completion:*' verbose true
  #zstyle ':completion:*' format 'Completing %d'
  #zstyle ':completion:*' insert-unambiguous true
  #zstyle :compinstall filename '/Users/lucas/.zshrc'
  zstyle ':completion:*:descriptions' format '%B%d%b'
  zstyle ':completion:*:messages' format '%d'

  zstyle ':completion:*:warnings' format 'No matches for: %d'
}

function zrc-zstyle-todo () { # {{{2
  zstyle ':completion:*' muttrc ~/.mutt/muttrc
  zstyle ':completion:*' mail-directory ~/mail
  zstyle ':completion:*' mailboxes ~/mail
  # Copied from the _git completion file.  This enables completion of custom
  # git subcommands (git-* files in $PATH).
  zstyle ':completion:*:*:git:*' user-commands \
    ${${(M)${(k)commands}:#git-*}/git-/}
}

function zrc-zstyle-hosts () { # new {{{2
  local -a hosts netrc known_hosts ssh_config
  zrc-parse-ssh-config
  zrc-parse-known-hosts
  zrc-parse-netrc
  hosts=($ssh_config $known_hosts $netrc)
  hosts=(${hosts//<->.<->.<->.<->/})
  if [[ $#hosts -gt 0 ]]; then
    zstyle ':completion:*:hosts' hosts $hosts
    # from http://serverfault.com/questions/170346
    #zstyle ':completion:*:ssh:*' hosts $hosts
    #zstyle ':completion:*:slogin:*' hosts $hosts
  fi
  zrc-zstyle-hosts-patterns
}

function zrc-zstyle-hosts-patterns () { # {{{2
  # TODO
  # from
  # https://maze.io/2008/08/03/remote-tabcompletion-using-openssh-and-zsh
  ## ssh, scp, ping, host
  #zstyle ':completion:*:scp:*' tag-order \
  #      'hosts:-host hosts:-domain:domain hosts:-ipaddr:IP\ address *'
  #zstyle ':completion:*:scp:*' group-order \
  #      users files all-files hosts-domain hosts-host hosts-ipaddr
  #zstyle ':completion:*:ssh:*' tag-order \
  #      users 'hosts:-host hosts:-domain:domain hosts:-ipaddr:IP\ address *'
  #zstyle ':completion:*:ssh:*' group-order \
  #      hosts-domain hosts-host users hosts-ipaddr
  #
  zstyle ':completion:*:(ssh|scp):*:hosts-host' ignored-patterns \
	'*.*' loopback localhost
  zstyle ':completion:*:(ssh|scp):*:hosts-domain' ignored-patterns \
	'<->.<->.<->.<->' '^*.*' '*@*'
  zstyle ':completion:*:(ssh|scp):*:hosts-ipaddr' ignored-patterns \
	'^<->.<->.<->.<->' '127.0.0.<->'
  #zstyle -e ':completion:*:(ssh|scp):*' hosts 'reply=( some hosts )'
  #zstyle ':completion:*:(ssh|scp):*:users' ignored-patterns \
  #      adm bin daemon halt lp named shutdown sync
  zstyle ':completion:*(ssh|scp):*:users' ignored-patterns daemon _*
}

function zrc-parse-netrc () { # {{{2
  netrc=(${${(@M)${(f)"$(cat ${NETRC:-~/.netrc(N)} /dev/null)"}:#machine *}#machine })
  # sed -n '/^machine/s/^machine //p' ~/.netrc
}

function zrc-parse-known-hosts () { # {{{2
  # many thanks to http://www.sourceguru.net/ssh-host-completion-zsh-stylee
  known_hosts=(${=${${(f)"$(cat {/etc/ssh_,{~/.ssh/,/var/lib/misc/ssh_}known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ })
  known_hosts=(
  $(
    awk '
      !/^#/ &&
      !/([12]?[0-9]?[0-9]\.){3}[12]?[0-9]?[0-9]/ &&
      !/([0-9a-f]{0,4}:){7}[0-9a-f]{0,4}/ {
        gsub(","," ",$1)
        gsub("[][]","",$1)
        print $1
      }' {/etc/ssh_,{~/.ssh/,/var/lib/misc/ssh_}known_}hosts(|2)(N) /dev/null
  )
  )
  # TODO ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
}

function zrc-parse-ssh-config () { # {{{2
  # from http://serverfault.com/questions/170346
  ssh_config=(${${${(@M)${(f)"$(cat ~/.ssh/config(N) /dev/null)"}:#Host *}#Host }:#*[*?]*})
  # ${=${${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*\**}:#*\?*}}
  # sed -n '/\*/d;/^Host/s/^Host[=\t ]*//p' ~/.ssh/config
}

function zrc-compinit () { # {{{2
  zrc-zstyle-layout
  zrc-zstyle-performemce
  zrc-zstyle-other
  zrc-zstyle-todo
  zrc-zstyle-hosts
  autoload -Uz compinit
  compinit
  compdef colordiff=diff
  compdef gpg2=gpg
  #compdef pip2=pip
  compdef vi=vim
  compdef _gnu_generic afew
}

# set up antigen {{{1
function zrc-antigen () { # {{{2
  local p
  for p in ~/vcs/antigen; do
    zrc-source $p/antigen.zsh
  done
}

# set up fzf keybindings {{{1
function zrc-fzf-setup () { # {{{2
  zrc-source /etc/profile.d/fzf.zsh
}

# high level functions for some decisions {{{1

function zrc-meta-prompt () { # {{{2
  if [[ $TERM == dump ]]; then
    # possibly :sh from within macvim
    zrc-stand-alone-monochrome-ps1
    unset RPROMPT
  elif [[ $CONQUE -eq 1 ]]; then
    # vim Conque term plugin
    zrc-stand-alone-colour-ps1
    unset RPROMPT
  elif [[ $VIMSHELL -eq 1 ]]; then
    # vim "vimshell" plugin
    zrc-stand-alone-colour-ps1
    unset RPROMPT
  else
    # hopefully a color terminal
    zrc-condensed-color-ps1
    zrc-full-colour-rps1
  fi
}

# call the functions {{{1

zrc-source-files
zrc-antigen

zrc-meta-prompt

zrc-history-options
zrc-misc-options
zrc-interesting-options

zrc-autoloading
zrc-module-path
zrc-fignore
zrc-zle-highlighting
zrc-fpath

zrc-syntax-highlighting
zrc-keymap
zrc-run-help

zrc-zmodload
zrc-lesspipe
zrc-autojump-decision
zrc-homeshick
zrc-gpg-setup
zrc-fzf-setup
zrc-zsh-mime-handling-setup

zrc-compinit

zrc-khal-notifications

# execute the at exit hooks {{{1
zrc-run-exit-hooks

# unset all local functions and variables {{{1

unfunction -m 'zrc-*'
unset -m 'ZRC_*'
