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

function zrc-test-osx () {
  [[ $(uname) = Darwin ]]
}

function zrc-test-linux () {
  :
}

function zrc-source () {
  if [[ -r $1 ]]; then
    source $1
    return 0
  else
    return 1
  fi
}

function zrc-run-exit-hooks () {
  local f
  for f in $ZRC_AT_EXIT_FUNCTIONS; do
    $f
    unfunction $f
  done
}

function zrc-has-color () {
  # return true if the terminal can handle colors
  if [[ $TERM = dump ]]; then
    return 1
  else
    return 0
  fi
}

function zrc-add-exit-hook () {
  ZRC_AT_EXIT_FUNCTIONS+=$1
}

# local variables {{{1
ZRC_UNAME=$(uname)
# Will expand to the nullstring if we are not on Mac OS X or brew is not
# installed.
ZRC_PREFIX=$(brew --prefix 2>/dev/null)
# an array of functions to be called at exit
ZRC_AT_EXIT_FUNCTIONS=()

# functions to set up basic zsh options {{{1

function zrc-history-options () {
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

function zrc-misc-options () {
  setopt extended_glob
  setopt no_no_match
  setopt prompt_subst
}

function zrc-interesting-options () {
  setopt auto_cd
  setopt glob_dots
  #setopt print_exit_value
  setopt no_list_ambiguous
}

# functions to set up key bindings {{{1

function zrc-keymap () {
  bindkey -v
  zrc-search-keys
  zrc-keys-terminfo
  case $ZRC_UNAME in
    Darwin) zrc-keys-iterm-arrows;;
    Linux)
      if [[   -r /etc/arch-release && \
	    ! -z $SSH_CLIENT       && \
	    ! -z $SSH_CONNECTION   && \
	    ! -z $SSH_TTY             \
          ]]; then
        zrc-keys-ssh
      fi
      ;;
  esac
  zrc-keys-history-substring
  zrc-keys-edit-command-line
}

function zrc-search-keys () {
  bindkey -M viins '\C-r' history-incremental-pattern-search-backward
  bindkey -M vicmd '\C-r' history-incremental-pattern-search-backward
  bindkey -M viins '\C-s' history-incremental-pattern-search-forward
  bindkey -M vicmd '\C-s' history-incremental-pattern-search-forward
}

function zrc-keys-terminfo () {
  zmodload zsh/terminfo
  bindkey -M viins $terminfo[kcuu1] up-line-or-search
  bindkey -M vicmd $terminfo[kcuu1] up-line-or-search
  bindkey -M viins $terminfo[kcud1] down-line-or-search
  bindkey -M vicmd $terminfo[kcud1] down-line-or-search
  bindkey -M viins $terminfo[khome] beginning-of-line
  bindkey -M vicmd $terminfo[khome] beginning-of-line
  bindkey -M viins $terminfo[kend]  end-of-line
  bindkey -M vicmd $terminfo[kend]  end-of-line
  bindkey -M viins $terminfo[kRIT]  vi-forward-word
  bindkey -M vicmd $terminfo[kRIT]  vi-forward-word
  bindkey -M viins $terminfo[kLFT]  vi-backward-word
  bindkey -M vicmd $terminfo[kLFT]  vi-backward-word
}

function zrc-keys-history-substring () {
  zrc-source /usr/local/opt/zsh-history-substring-search/zsh-history-substring-search.zsh || return
  if [[ $ZRC_UNAME = Darwin ]]; then
    bindkey -M viins '\e[1;2A' history-substring-search-up
    bindkey -M vicmd '\e[1;2A' history-substring-search-up
    bindkey -M viins '\e[1;2B' history-substring-search-down
    bindkey -M vicmd '\e[1;2B' history-substring-search-down
  fi
}

function zrc-keys-history-substring-iterm () {
  bindkey -M viins '\e[A' history-substring-search-up
  bindkey -M vicmd '\e[A' history-substring-search-up
  bindkey -M viins '\e[B' history-substring-search-down
  bindkey -M vicmd '\e[B' history-substring-search-down
}

function zrc-keys-iterm-arrows () {
  # all the codes that are not conforming with the terminfo version
  bindkey -M viins '\e[A' up-line-or-search
  bindkey -M vicmd '\e[A' up-line-or-search
  bindkey -M viins '\e[B' down-line-or-search
  bindkey -M vicmd '\e[B' down-line-or-search
  bindkey -M viins '\e[H' beginning-of-line
  bindkey -M vicmd '\e[H' beginning-of-line
  bindkey -M viins '\e[F' end-of-line
  bindkey -M vicmd '\e[F' end-of-line
  function zrc-keyvars-iterm () {
    HOME_KEY='\e[H'
    END_KEY='\e[F'
  }
}

function zrc-keys-ssh () {
  bindkey -M viins '\e[H' beginning-of-line
  bindkey -M vicmd '\e[H' beginning-of-line
  bindkey -M viins '\e[F' end-of-line
  bindkey -M vicmd '\e[F' end-of-line
  bindkey -M viins '\e[1;2C' vi-forward-word
  bindkey -M vicmd '\e[1;2C' vi-forward-word
  bindkey -M viins '\e[1;2D' vi-backward-word
  bindkey -M vicmd '\e[1;2D' vi-backward-word
}

function zrc-keys-edit-command-line () {
  autoload edit-command-line
  zle -N edit-command-line
  bindkey '\ee' edit-command-line
}

# prompt related functions {{{1

function zrc-execution-timer () {
  autoload -Uz add-zsh-hook
  # define the needed variables
  typeset -i _threshold
  typeset -i _start
  # define the needed function
  function execution-time-helper-function () {
    (( _start = $SECONDS ))
    (( _threshold = _start + 10 ))
  }
  # add the function to a hook
  add-zsh-hook preexec execution-time-helper-function
}

# functions to set up the vsc_info plugin for the prompt {{{1

function zrc-vcs-info-zstyle () {
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

function zrc-vcs-info-setup () {
  autoload -Uz add-zsh-hook
  autoload -Uz vcs_info
  add-zsh-hook precmd vcs_info
}

function zrc-vcs-info-hooks () {
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

function zrc-full-colour-ps1 () {
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

function zrc-stand-alone-colour-ps1 () {
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

function zrc-stand-alone-monochrome-ps1 () {
  PS1='[ '                                              # frame
  PS1+='%n@%m'                                          # user and host info
  PS1+=' | '                                            # delimiter
  PS1+='%1~'                                            # working directory
  PS1+=' | '                                            # delimiter
  PS1+='%(?.%D{%H:%M:%S}.Error %?)'                     # curren time or error
  PS1+=' ] '                                            # frame
}

function zrc-full-colour-rps1 () {
  RPROMPT='%(?.'                                   # if $? = 0
  RPROMPT+='%(${_threshold}S.'                     #   if _threshold < SECONDS
  RPROMPT+='%F{yellow}'                            #     switch color
  RPROMPT+='Time: $((SECONDS-_start))%f'           #     duration of command
  RPROMPT+='.)'                                    #   else, fi
  if [[ $ZRC_UNAME = Darwin ]]; then                 #   if OS X
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

# functions to set up zsh special variables {{{1

function zrc-module-path () {
  module_path=($module_path /usr/local/lib/zpython)
}

function zrc-fignore () {
  # file endings to ignore for completion
  fignore=($fignore '~' .o .bak '.sw?')
}

function zrc-zle-highlighting () {
  # zle stuff
  zle_highlight=(region:bg=green special:bg=blue suffix:fg=red isearch:fg=yellow)
}

function zrc-fpath () {
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

# functions to set up the run-help function {{{1

function zrc-install-run-help () {
  mkdir $HELPDIR
  perl ~/vcs/zsh-code/Util/helpfiles zshall $HELPDIR
}

function zrc-compile-run-help-sed-helper () {
  sed -e \
    '$ {
       s/^.*See the section `\(.*\). in zsh\([a-z]*\)(1)\.$/manpage=zsh\2 regexp="\1"/
       s/\\/\\\\/g
       s/\//\\\//g
     }'
}

function zrc-compile-run-help-perl-helper () {
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

function zrc-compile-run-help () {
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

function zrc-run-help () {
  autoload -Uz run-help
  unalias run-help
  HELPDIR=$ZDOTDIR/help
  bindkey -M viins '\C-h' run-help
  bindkey -M vicmd '\C-h' run-help
  # install the files when needed
  if [[ ! -d $HELPDIR ]]; then
    ( zrc-install-run-help && \
        zrc-compile-run-help ) &
  fi
}

# functions to set xxx {{{1

function zrc-directory-hash-table () {
  #hash -d i=~/Pictures
  #hash -d m=~/Music
  hash -d t=~/tmp
  hash -d u=~/uni
  hash -d v=/Volumes
  hash -d p=~/uni/philosophie
  hash -d y=~/.homesick/repos/secure/yaml
}

function zrc-autoloading () {
  autoload -Uz colors && colors
  #autoload -Uz checkmail
  # autoloading user defined functions
  autoload -Uz $ZDOTDIR/functions/*(:t)
}

function zrc-zmodload () {
  zmodload zsh/sched
  zmodload zsh/zprof
  #zmodload zsh/zpython
}

function zrc-source-files () {
  local file
  for file in ~/.profile $ZDOTDIR/aliases; do
    zrc-source $file
  done
}

function zrc-lesspipe () {
  ## make less more friendly for non-text input files, see lesspipe(1)
  if whence -p lesspipe &>/dev/null; then
    eval "$(lesspipe)"
  elif whence -p lesspipe.sh &>/dev/null; then
    eval "$(lesspipe.sh)"
  fi
}

function zrc-autojump () {
  #export AUTOJUMP_KEEP_SYMLINKS=1
  zrc-source /usr/share/autojump/autojump.sh || \
    zrc-source $ZRC_PREFIX/etc/autojump.sh
}

function zrc-rupa-z () {
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

function zrc-syntax-highlighting () {
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

function zrc-homeshick () {
  # homesick for automatic dotfiles setup
  zrc-source ~/.homesick/repos/homeshick/homeshick.sh
}

# other {{{1

function zrc-todo-from-bashrc () {
  # this and dircolors in general
  if [ "$TERM" != "dumb" ]; then
    eval "`dircolors -b`"
  fi
}

# functions to set up completion {{{1

function zrc-zstyle-layout () {
  zstyle ':completion:*' list-prompt \
    %SAt %p: Hit TAB for more, or the character to insert%s
  zstyle ':completion:*' auto-description 'specify: %d'
  zstyle ':completion:*' file-sort name
  zstyle ':completion:*' list-colors ''
  zstyle ':completion:*' menu select=long
  zstyle ':completion:*' select-prompt \
    %SScrolling active: current selection at %p%s
}

function zrc-zstyle-performemce () {
  zstyle ':completion:*' use-cache on
  zstyle ':completion:*' cache-path $ZDOTDIR/cache
}

function zrc-zstyle-other () {
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
  zstyle ':completion:*:descriptions' format '%B%d%b'
  zstyle ':completion:*:messages' format '%d'

  zstyle ':completion:*:warnings' format 'No matches for: %d'
}

function zrc-zstyle-todo () {
  zstyle ':completion:*' muttrc ~/.mutt/muttrc
  zstyle ':completion:*' mail-directory ~/mail
  zstyle ':completion:*' mailboxes ~/mail
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

function zrc-zstyle-hosts-patterns () {
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

function zrc-parse-netrc () {
  netrc=(${${(@M)${(f)"$(cat ~/.netrc(N) /dev/null)"}:#machine *}#machine })
  # sed -n '/^machine/s/^machine //p' ~/.netrc
}

function zrc-parse-known-hosts () {
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

function zrc-parse-ssh-config () {
  # from http://serverfault.com/questions/170346
  ssh_config=(${${${(@M)${(f)"$(cat ~/.ssh/config(N) /dev/null)"}:#Host *}#Host }:#*[*?]*})
  # ${=${${${${(@M)${(f)"$(<~/.ssh/config)"}:#Host *}#Host }:#*\**}:#*\?*}}
  # sed -n '/\*/d;/^Host/s/^Host[=\t ]*//p' ~/.ssh/config
}

function zrc-compinit () {
  zrc-zstyle-layout
  zrc-zstyle-performemce
  zrc-zstyle-other
  zrc-zstyle-todo
  zrc-zstyle-hosts
  autoload -Uz compinit
  compinit
  compdef gpg2=gpg
  compdef colordiff=diff
}

# high level functions for some decisions {{{1

function zrc-meta-prompt () {
  if [[ $TERM = dump ]]; then
    # possibly :sh from within macvim
    zrc-stand-alone-monochrome-ps1
    unset RPROMPT
  elif [[ $CONQUE -eq 1 ]]; then
    # vim Conque term plugin
    zrc-stand-alone-colour-ps1
    unset RPROMPT
  else
    # hopefully a color terminal
    zrc-full-colour-ps1
    zrc-full-colour-rps1
  fi
}

# call the functions {{{1

zrc-source-files

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

zrc-directory-hash-table
zrc-zmodload
zrc-lesspipe
zrc-rupa-z
zrc-homeshick

zrc-compinit

# execute the at exit hooks {{{1
zrc-run-exit-hooks

# unset all local functions and variables {{{1

unfunction $(functions|grep -E '^zrc-'|cut -f 1 -d ' ')
unset $(set | grep '^ZRC_' | cut -f 1 -d =)
