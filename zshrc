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
# and the zsh manual:
#          http://zsh.sourceforge.net/Doc/
# README:  This file is modularized in many functions which are called if
#          apropriate at the end and then unset at EOF.

# helper functions {{{1

function zshrc-helper-try-to-source-file () {
  if [[ -r $1 ]]; then
    source $1
    return 0
  else
    return 1
  fi
}

function zshrc-helper-at-exit-hook () {
  local f
  for f in $ZSHRC_SET_UP_AT_EXIT_FUNCTIONS; do
    $f
    unfunction $f
  done
}

function zshrc-helper-add-at-exit-hook () {
  ZSHRC_SET_UP_AT_EXIT_FUNCTIONS+=$1
}

# local variables {{{1
ZSHRC_SET_UP_UNAME=$(uname)
# Will expand to the nullstring if we are not on Mac OS X or brew is not
# installed.
ZSHRC_SET_UP_PREFIX=$(brew --prefix 2>/dev/null)
# an array of functions to be called at exit
ZSHRC_SET_UP_AT_EXIT_FUNCTIONS=()

# functions to set up basic zsh options {{{1

function zshrc-set-up-history-options () {
  HISTFILE=$ZDOTDIR/histfile
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

function zshrc-set-up-misc-options () {
  setopt extended_glob
  setopt no_no_match
  setopt prompt_subst
}

function zshrc-set-up-interesting-options () {
  setopt auto_cd
  setopt glob_dots
  #setopt print_exit_value
  setopt no_list_ambiguous
}

# functions to set up key bindings {{{1

function zshrc-set-up-keymap () {
  bindkey -v
}

function zshrc-set-up-keybindings-for-searching () {
  bindkey -M viins '\C-r' history-incremental-pattern-search-backward
  bindkey -M vicmd '\C-r' history-incremental-pattern-search-backward
  bindkey -M viins '\C-s' history-incremental-pattern-search-forward
  bindkey -M vicmd '\C-s' history-incremental-pattern-search-forward
}

function zshrc-set-up-keybinding-variables-with-mac-iterm-escapes () {
  HOME_KEY='\e[H'
  END_KEY='\e[F'
  SHIFT_RIGHT='\e[1;2C'
  SHIFT_LEFT='\e[1;2D'
}
function zshrc-set-up-keybinding-variables-with-rxvt-escapes () {
  HOME_KEY='\e[7~'
  END_KEY='\e[8~'
  SHIFT_RIGHT='\e[c'
  SHIFT_LEFT='\e[d'
}
function zshrc-set-up-keybinding-variables-with-linux-standard-escapes () {
  HOME_KEY='\eOH'
  END_KEY='\eOF'
}
function zshrc-set-up-keybindings-for-arrow-keys () {
  bindkey -M viins '\e[A' up-line-or-search
  bindkey -M vicmd '\e[A' up-line-or-search
  bindkey -M viins '\e[B' down-line-or-search
  bindkey -M vicmd '\e[B' down-line-or-search

  if [[ $ZSHRC_SET_UP_UNAME = Darwin ]]; then
    # FIXME: how can I communicate this through a ssh session?
    bindkey -M viins '\e[H' beginning-of-line
    bindkey -M vicmd '\e[H' beginning-of-line
    bindkey -M viins '\e[F' end-of-line
    bindkey -M vicmd '\e[F' end-of-line
    bindkey -M viins '\e[1;2C' vi-forward-word
    bindkey -M vicmd '\e[1;2C' vi-forward-word
    bindkey -M viins '\e[1;2D' vi-backward-word
    bindkey -M vicmd '\e[1;2D' vi-backward-word
  elif [[ $ZSHRC_SET_UP_UNAME = Linux ]]; then
    if [[ $TERM =~ rxvt ]]; then
      bindkey -M viins '\e[7~' beginning-of-line
      bindkey -M vicmd '\e[7~' beginning-of-line
      bindkey -M viins '\e[8~' end-of-line
      bindkey -M vicmd '\e[8~' end-of-line
      bindkey -M viins '\e[c' vi-forward-word
      bindkey -M vicmd '\e[c' vi-forward-word
      bindkey -M viins '\e[d' vi-backward-word
      bindkey -M vicmd '\e[d' vi-backward-word
    else
      bindkey -M viins '\eOH' beginning-of-line
      bindkey -M vicmd '\eOH' beginning-of-line
      bindkey -M viins '\eOF' end-of-line
      bindkey -M vicmd '\eOF' end-of-line
    fi
    if [[   -r /etc/arch-release && \
	  ! -z $SSH_CLIENT       && \
	  ! -z $SSH_CONNECTION   && \
	  ! -z $SSH_TTY             \
       ]]; then
      bindkey -M viins '\e[H' beginning-of-line
      bindkey -M vicmd '\e[H' beginning-of-line
      bindkey -M viins '\e[F' end-of-line
      bindkey -M vicmd '\e[F' end-of-line
      bindkey -M viins '\e[1;2C' vi-forward-word
      bindkey -M vicmd '\e[1;2C' vi-forward-word
      bindkey -M viins '\e[1;2D' vi-backward-word
      bindkey -M vicmd '\e[1;2D' vi-backward-word
    fi
  fi
}

# prompt related functions {{{1

function execution-time-helper-function () {
  (( _start = $SECONDS ))
  (( _threshold = _start + 10 ))
}

function zshrc-set-up-prompt-variables () {
  typeset -i _threshold
  typeset -i _start
}

function zshrc-set-up-zsh-hooks () {
  add-zsh-hook precmd vcs_info
  add-zsh-hook preexec execution-time-helper-function
}

# prompt versions {{{1

function full-colour-ps1 () {
  PS1='[ '                                              # frame
  PS1+='%(!.%F{red}.%F{green})'                         # user=green, root=red
  PS1+='%n%F{cyan}@%F{blue}%m%f'                        # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%F{cyan}%1~%f'                                  # working directory
  PS1+=' | '                                            # delimiter
  PS1+='${vcs_info_msg_0_:+$vcs_info_msg_0_ | }'        # VCS info with delim.
  PS1+='%D{%H:%M:%S}'                                   # current time
  PS1+=' ] '                                            # frame
}

function stand-alone-colour-ps1 () {
  PS1='[ '                                              # frame
  PS1+='%(!.%F{red}.%F{green})'                         # user=green, root=red
  PS1+='%n%F{cyan}@%F{blue}%m%f'                        # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%F{cyan}%1~%f'                                  # working directory
  PS1+=' | '                                            # delimiter
  PS1+='${vcs_info_msg_0_:+$vcs_info_msg_0_ | }'        # VCS info with delim.
  PS1+='%(?.%D{%H:%M:%S}.%F{red}Error %?%f)'            # curren time or error
  PS1+=' ] '                                            # frame
}

function stand-alone-monochrome-ps1 () {
  PS1='[ '                                              # frame
  PS1+='%n@%m'                                          # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%1~'                                            # working directory
  PS1+=' | '                                            # delimiter
  PS1+='%(?.%D{%H:%M:%S}.Error %?)'                     # curren time or error
  PS1+=' ] '                                            # frame
}

function full-colour-rps1 () {
  RPROMPT='%(?.'                                   # if $? = 0
  RPROMPT+='%(${_threshold}S.'                     #   if _threshold < SECONDS
  RPROMPT+='%F{yellow}'                            #     switch color
  RPROMPT+='Time: $((SECONDS-_start))%f'           #     duration of command
  RPROMPT+='.)'                                    #   else, fi
  if [[ $ZSHRC_SET_UP_UNAME = Darwin ]]; then                 #   if OS X
    RPROMPT+=' $(battery.sh -bce zsh)'             #     battery information
  fi                                               #   fi
  RPROMPT+='.'                                     # else
  RPROMPT+='%F{yellow}'                            #   switch color
  RPROMPT+='Time: $((SECONDS-_start)) '            #   duration of command
  RPROMPT+='%F{red}'                               #   switch color
  RPROMPT+='Error: %?'                             #   error message
  RPROMPT+=')'                                     # fi
}

# functions to set up zsh special variables {{{1

function zshrc-set-up-module-path () {
  module_path=($module_path /usr/local/lib/zpython)
}

function zshrc-set-up-fignore () {
  # file endings to ignore for completion
  fignore=($fignore '~' .o .bak '.sw?')
}

function zshrc-set-up-zle-highlighting () {
  # zle stuff
  zle_highlight=(region:bg=green special:bg=blue suffix:fg=red isearch:fg=yellow)
}

function zshrc-set-up-fpath () {
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
}

# functions to set up xxx {{{1

function zshrc-set-up-run-help () {
  HELPDIR=~/zsh_help
  bindkey -M viins '\C-h' run-help
  bindkey -M vicmd '\C-h' run-help
}

function zshrc-set-up-directory-has-table () {
  #hash -d i=~/Pictures
  #hash -d m=~/Music
  hash -d t=~/tmp
  hash -d u=~/uni
  hash -d v=/Volumes
  hash -d p=~/uni/philosophie
  hash -d y=~/.config/secure/yaml
}

function zshrc-set-up-autoloading () {
  autoload -Uz add-zsh-hook
  autoload -Uz colors && colors
  #autoload -Uz checkmail
  autoload -Uz run-help
  autoload -Uz vcs_info
  autoload -Uz compinit
  # autoloading user defined functions
  autoload -Uz $ZDOTDIR/functions/*(:t)
}

function zshrc-set-up-zmodload () {
  zmodload zsh/sched
  zmodload zsh/zprof
  #zmodload zsh/zpython
}

function zshrc-set-up-private-files-to-be-sourced () {
  local file
  for file in ~/.profile $ZDOTDIR/aliases; do
    zshrc-helper-try-to-source-file $file
  done
}

function zshrc-set-up-lesspipe () {
  ## make less more friendly for non-text input files, see lesspipe(1)
  if whence -p lesspipe &>/dev/null; then
    eval "$(lesspipe)"
  elif whence -p lesspipe.sh &>/dev/null; then
    eval "$(lesspipe.sh)"
  fi
}

function zshrc-set-up-autojump () {
  #export AUTOJUMP_KEEP_SYMLINKS=1
  zshrc-helper-try-to-source-file /usr/share/autojump/autojump.sh || \
    zshrc-helper-try-to-source-file $ZSHRC_SET_UP_PREFIX/etc/autojump.sh
}

function zshrc-set-up-rupa-z-as-j () {
  if [[ -r $ZSHRC_SET_UP_PREFIX/etc/profile.d/z.sh ]]; then
    # read man z
    export _Z_DATA=~/.cache/z
    _Z_CMD=j source $ZSHRC_SET_UP_PREFIX/etc/profile.d/z.sh
    add-zsh-hook chpwd _z_precmd
    unalias j
    function j () {
      _z $@ 2>&1 && echo ${fg[red]}`pwd`$reset_color
    }
    function j-completion-at-exit-function () {
      compctl -U -K _z_zsh_tab_completion j
    }
    zshrc-helper-add-at-exit-hook j-completion-at-exit-function
  fi
}

function zshrc-set-up-syntax-highlighting () {
  local -a locations
  local location
  case $ZSHRC_SET_UP_UNAME in
    Darwin)
      location=$ZSHRC_SET_UP_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ;;
    Linux)
      location=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      ;;
  esac
  zshrc-helper-try-to-source-file $location
}

function zshrc-set-up-homeshick () {
  # homesick for automatic dotfiles setup
  zshrc-helper-try-to-source-file ~/.homesick/repos/homeshick/homeshick.sh
}

# other {{{1

function zshrc-todo-from-bashrc () {
  # this and dircolors in general
  if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
  fi
}

# functions to set up the vsc_info plugin for the prompt {{{1

function zshrc-set-up-zstyle-vsc-info () {
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

# functions that can be used to change the defaults of the vcs-info code {{{2

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

function zshrc-set-up-vcs-info-hooks () {
  # register the functions with the correct hooks
  zstyle ':vcs_info:git+set-message:*' hooks \
    git-add-untracked-files                  \
    git-string                               \

  zstyle ':vcs_info:hg+set-message:*' hooks hg-string
}

# functions to set up completion {{{1

function zshrc-set-up-zstyle-layout () {
  zstyle ':completion:*' list-prompt \
    %SAt %p: Hit TAB for more, or the character to insert%s
  zstyle ':completion:*' auto-description 'specify: %d'
  zstyle ':completion:*' file-sort name
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*' menu select=long
  zstyle ':completion:*' select-prompt \
    %SScrolling active: current selection at %p%s
}

function zshrc-set-up-zstyle-performemce () {
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path $ZDOTDIR/cache
}

function zshrc-set-up-zstyle-other () {
  zstyle ':completion:*' completer _expand _complete _ignored
  zstyle ':completion:*' expand prefix suffix
  zstyle ':completion:*' special-dirs ..
  zstyle ':completion:*' ignore-parents parent pwd ..
  #TODO
  zstyle ':completion:*:cd:*' ignored-patterns .
  zstyle ':completion:*' list-suffixes true
  zstyle ':completion:*' matcher-list \
    '' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}'
  zstyle ':completion:*' original false
  zstyle ':completion:*' squeeze-slashes true
  zstyle ':completion:*' verbose true
  #zstyle ':completion:*' format 'Completing %d'
  #zstyle ':completion:*' insert-unambiguous true
  #zstyle :compinstall filename '/Users/lucas/.zshrc'
}

function zshrc-set-up-zstyle-what-do-these-do () {
  zstyle ':completion:*' muttrc ~/.mutt/muttrc
  zstyle ':completion:*' mail-directory ~/mail
  zstyle ':completion:*' mailboxes ~/mail
}

function zshrc-set-up-ssh-hosts () {
  # many thanks to http://www.sourceguru.net/ssh-host-completion-zsh-stylee
  # other ideas:
  #              sed -n '/\*/d;/^Host/s/^Host[=\t ]*//p' ~/.ssh/config
  #              awk '{print $1}' ~/.ssh/known_hosts | tr ',' '\n'
  #              sed -n '/^machine/s/^machine //p' ~/.netrc
  #
  # this looks for the files /etc/ssh_hosts /etc/ssh_hosts2 ~/.ssh/known_hosts
  # ~/.ssh/known_hosts2 ...
  hosts=(
    # is there already something saved in $hosts?
    $hosts
    # from http://serverfault.com/questions/170346
    ${${${(@M)${(f)"$(cat ~/.ssh/config(N) /dev/null)"}:#Host *}#Host }:#*[*?]*}
    ${=${${(f)"$(cat {/etc/ssh_,{~/.ssh/,/var/lib/misc/ssh_}known_}hosts(|2)(N) /dev/null)"}%%[# ]*}//,/ }
    ${${(@M)${(f)"$(cat ~/.netrc(N) /dev/null)"}:#machine *}#machine }
  )
  # remove entries which are just an ip address
  hosts=(${hosts//<->.<->.<->.<->/})

  if [[ $#hosts -gt 0 ]]; then
    zstyle ':completion:*:hosts' hosts $hosts
    # from http://serverfault.com/questions/170346
    #zstyle ':completion:*:ssh:*' hosts $hosts
    #zstyle ':completion:*:slogin:*' hosts $hosts
  fi
  zstyle ':completion:*(ssh|scp):*:users' ignored-patterns daemon _*

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
  #zstyle ':completion:*:(ssh|scp):*:users' ignored-patterns \
  #      adm bin daemon halt lp named shutdown sync
  #
  ## If you also want tab completion of the hosts listed in your
  ## ~/.ssh/known_hosts and /etc/hosts files, you can add:
  #zstyle -e ':completion:*:(ssh|scp):*' hosts 'reply=(
  #      ${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) \
  #                      /dev/null)"}%%[# ]*}//,/ }
  #      ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
  #      ${=${${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*\**}:#*\?*}}
  #      )'
}

function zshrc-set-up-starting-the-completion-system () {
  compinit
  compdef gpg2=gpg
  compdef colordiff=diff
}

# call the functions {{{1

# If we are in Conque Term inside Vim use a different prompt
if [[ $CONQUE -eq 1 ]]; then
  stand-alone-colour-ps1
  unset RPROMPT
elif [[ $TERM = dump ]]; then
  stand-alone-monochrome-ps1
  unset RPROMPT
else
  full-colour-ps1
  full-colour-rps1
fi

# call everything in the correct order {{{1
zshrc-set-up-history-options
zshrc-set-up-misc-options
zshrc-set-up-interesting-options
zshrc-set-up-keymap
zshrc-set-up-keybindings-for-searching
zshrc-set-up-keybindings-for-arrow-keys
zshrc-set-up-prompt-variables
zshrc-set-up-autoloading
zshrc-set-up-zsh-hooks
zshrc-set-up-module-path
zshrc-set-up-fignore
zshrc-set-up-zle-highlighting
zshrc-set-up-fpath
zshrc-set-up-run-help
zshrc-set-up-directory-has-table
zshrc-set-up-zmodload
zshrc-set-up-private-files-to-be-sourced
zshrc-set-up-lesspipe
zshrc-set-up-autojump
zshrc-set-up-rupa-z-as-j
zshrc-set-up-syntax-highlighting
zshrc-set-up-homeshick
zshrc-set-up-zstyle-vsc-info
zshrc-set-up-vcs-info-hooks
zshrc-set-up-zstyle-layout
zshrc-set-up-zstyle-performemce
zshrc-set-up-zstyle-other
zshrc-set-up-zstyle-what-do-these-do
zshrc-set-up-ssh-hosts
zshrc-set-up-starting-the-completion-system

# execute the at exit hooks {{{1
zshrc-helper-at-exit-hook

# unset all local functions and variables {{{1
unfunction $(functions | grep '^zshrc-set-up-' | cut -f 1 -d ' ')
unfunction $(functions | grep '^zshrc-helper-' | cut -f 1 -d ' ')
unset $(set | grep '^ZSHRC_SET_UP_' | cut -f 1 -d =)
