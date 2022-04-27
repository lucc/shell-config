# file:    zshrc
# author:  luc
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
# TODO:    autoload -U throw catch

# profiling ##################################################################
# Setup for startup profiling and the execution timer in the right prompt.

# Get the current time for startup profiling
_start=${(%):-%D{%s.%.}}
_diff=
function execution-time-formatter () {
  local now=%D{%s.%.}
  _diff=$(printf '%.2f' $(( ${(%)now} - $_start )))
}
function zrc-profile () {
  execution-time-formatter
  printf 'startup %5s: %s\n' $_diff "${*:-...}"
}

# helper functions
function zrc-test-osx () {
  [[ $ZRC_UNAME == Darwin ]]
}
function zrc-test-linux () {
  [[ $ZRC_UNAME == (#i)linux ]]
}
function zrc-is-virtual-machine () {
  systemd-detect-virt --quiet
}
function zrc-source () {
  if [[ -r $1 ]]; then
    source $1
    return 0
  else
    return 1
  fi
}
function zrc-vi-bindkey () {
  if [[ -z $1 || -z $2 ]]; then
    bindkey_error=1
    return
  fi
  # bind the given key to the given function in the viins and vicmd maps
  bindkey -M viins $1 $2
  bindkey -M vicmd $1 $2
}

# functions to set up key bindings
function zrc-keymap () {
  bindkey -v
  typeset -g -A key
  local bindkey_error=0
  zrc-keys-terminfo
  zrc-keys-manual-corrections
  zrc-bind-basic-keys
  zrc-keys-edit-command-line
  zrc-push-zle-buffer-keys
  unset key
  if ((bindkey_error)); then
    print 'There were errors when binding keys.' >&2
  fi
}
function zrc-keys-terminfo () {
  zmodload zsh/terminfo
  # plain arrows
  key[Up]=$terminfo[kcuu1]
  key[Down]=$terminfo[kcud1]
  key[Left]=$terminfo[kcub1]
  key[Right]=$terminfo[kcuf1]
  # shifted arrows
  key[ShiftUp]=$terminfo[kPRV]
  key[ShiftDown]=$terminfo[kNXT]
  key[ShiftLeft]=$terminfo[kLFT]
  key[ShiftRight]=$terminfo[kRIT]
  # fn-arrows
  key[PageUp]=$terminfo[kpp]
  key[PageDown]=$terminfo[knp]
  key[Home]=$terminfo[khome]
  key[End]=$terminfo[kend]
  # shifted fn-arrows
  key[ShiftHome]=$terminfo[kHOME]
  key[ShiftEnd]=$terminfo[kEND]
  # delete and such
  key[Backspace]=$terminfo[kbs]
  key[Delete]=$terminfo[kdch1]
  key[ShiftDelete]=$terminfo[kDC]
}
function zrc-keys-manual-corrections () {
  # Collection of conditions and corrections for errors with terminfo
  if zrc-test-linux; then
    if [[ $TERM == alacritty ]]; then
      key[Up]='\e[A'
      key[Down]='\e[B'
      key[Left]='\e[D'
      key[Right]='\e[C'
      key[Home]='\e[H'
      key[End]='\e[F'
      key[ShiftUp]='\e[1;2A'
      key[ShiftDown]='\e[1;2B'
    elif [[ -n $MYVIMRC && $VIM = *nvim* && $VIMRUNTIME = *nvim* ]]; then
      zrc-keys-manual-corrections-nvim
    elif [[ $TERM == urxvt || $TERM == rxvt-unicode-256color ]]; then
      key[ShiftUp]='\e[a'
      key[ShiftDown]='\e[b'
    elif [[ -n $TMUX ]]; then
      zrc-keys-manual-corrections-tmux
    elif [[ -n $KONSOLE_DBUS_SERVICE ]]; then
      key[ShiftUp]='\e[1;5A'
      key[ShiftDown]='\e[1;5B'
    elif [[ $TERM == xterm && -z $KONSOLE_PROFILE_NAME ]]; then
      zrc-keys-manual-corrections-xterm
    elif [[ $TERM == xterm-256color ]]; then
      zrc-keys-manual-corrections-xterm
    elif [[ $TERM == xterm-termite ]]; then
      zrc-keys-manual-corrections-xterm
    fi
  elif zrc-test-osx; then
    zrc-keys-manual-corrections-xterm
  else
    print Unknown system: $ZRC_UNAME >&2
    return
  fi
}
function zrc-keys-manual-corrections-tmux () {
  key[Up]='\e[A'
  key[Down]='\e[B'
  # this needs the tmux option "xterm-keys" set to "on"
  key[ShiftUp]='\e[1;2A'
  key[ShiftDown]='\e[1;2B'
  key[ShiftLeft]='\e[1;2D'
  key[ShiftRight]='\e[1;2C'
}
function zrc-keys-manual-corrections-xterm () {
  key[Up]='\e[A'
  key[Down]='\e[B'
  key[Home]='\e[H'
  key[End]='\e[F'
  key[ShiftUp]='\e[1;2A'
  key[ShiftDown]='\e[1;2B'
}
function zrc-keys-manual-corrections-nvim () {
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
  key[ShiftDelete]='\U7fffcbd6'
}
function zrc-bind-basic-keys () {
  zrc-vi-bindkey $key[Up]         up-line-or-search
  zrc-vi-bindkey $key[Down]       down-line-or-search
  zrc-vi-bindkey $key[Home]       beginning-of-line
  zrc-vi-bindkey $key[End]        end-of-line
  zrc-vi-bindkey $key[ShiftLeft]  vi-backward-word
  zrc-vi-bindkey $key[ShiftRight] vi-forward-word
  zrc-vi-bindkey $key[Delete]     vi-delete-char
}
function zrc-keys-edit-command-line () {
  autoload edit-command-line
  zle -N edit-command-line
  bindkey '\Ce' edit-command-line
}
function zrc-push-zle-buffer-keys () {
  zrc-vi-bindkey '\C-p' push-input
  zrc-vi-bindkey '\C-o' push-line
}

# prompt related functions
# functions to set up the vcs_info plugin for the prompt
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
      hook_com[branch]+='%F{red}⁇%f'
    fi
  }
  # register the functions with the correct hooks
  zstyle ':vcs_info:git+set-message:*' hooks \
    git-add-untracked-files                  \
    git-string                               \

  zstyle ':vcs_info:hg+set-message:*' hooks hg-string
}
# prompt versions
function zrc-full-colour-rps1 () {
  local time_segment='%F{yellow}⌛$_diff'
  typeset -gA _keymap_prompt_strings
  _keymap_prompt_strings=(
    main       ''
    vicmd      '%F{yellow}CMD%f '
    visual     '%F{blue}VIS%f '
    viopp      '%F{red}OPP%f '
    listscroll '%F{red}LIST%f '
    command    '%F{red}CMD?%f '
    .safe      '%F{red}SAFE%f '
    menuselect '%F{red}SEL%f '
    isearch    '%F{red}I/%f '
    viins      '%F{red}INS%f '
    emacs      '%F{red}EMACS%f '
  )
  KEYTIMEOUT=1
  RPROMPT='$_keymap_prompt_strings[$KEYMAP]'       # INSERT|CMD|...
  RPROMPT+='%(?|'                                  # if $? == 0
  RPROMPT+='%(${_threshold}S|'                     #   if _threshold < SECONDS
  RPROMPT+=$time_segment                           #     duration of command
  RPROMPT+='|)'                                    #   else, fi
  if zrc-test-osx || [[ ${(L)TERM} = linux ]]; then #   if OS X or console
    RPROMPT+=' $(battery.sh -bce zsh)'             #     battery information
  fi                                               #   fi
  RPROMPT+='|'                                     # else
  RPROMPT+='%(127?.'                               #   if $? == 127
  RPROMPT+='%F{red}'                               #     switch color
  RPROMPT+='∄'                                     #     command not found
  RPROMPT+='.'                                     #   else
  RPROMPT+="$time_segment "                        #     duration of command
  RPROMPT+='%F{red}'                               #     switch color
  RPROMPT+='✘%?'                                   #     error message
  RPROMPT+=')'                                     #   fi
  RPROMPT+=')'                                     # fi

  # Finally we prepare the dependencies for these prompt segments
  autoload -Uz add-zsh-hook
  # define the needed variables
  typeset -ig _threshold
  typeset -g _start
  typeset -g _diff
  # define the needed functions
  function execution-time-helper-function () {
    local now=%D{%s.%.}
    _start=${(%)now}
    (( _threshold = SECONDS + 4 ))
  }
  function zle-keymap-select zle-line-init {
    zle reset-prompt
  }
  zle -N zle-keymap-select
  zle -N zle-line-init
  _threshold=0
  # add the function to a hook
  add-zsh-hook preexec execution-time-helper-function
  add-zsh-hook precmd execution-time-formatter
}
function zrc-condensed-color-ps1 () {
  PS1=
  if [[ -n $SSH_CONNECTION ]] || zrc-is-virtual-machine; then
    PS1+='%(!.%F{red}.%F{green})'                   # user=green, root=red
    PS1+='%n%F{cyan}@%F{blue}%m%f:'                 # user and host info
  else
    PS1+='%(!.%F{red}%n%F{cyan}@%F{blue}%m%f:.)'    # user=green, root=red
  fi
  PS1+='%F{cyan}%1~%f'                              # working directory
  PS1+='${vcs_info_msg_0_:+($vcs_info_msg_0_)}'     # VCS info with delim.
  PS1+='%# '
  zrc-vcs-info-zstyle
  zrc-vcs-info-hooks
  zrc-vcs-info-setup
}
# main prompt decision function
function zrc-meta-prompt () {
  zrc-condensed-color-ps1
  zrc-full-colour-rps1
}

function zrc-set-up-window-title () {
  add-zsh-hook preexec set-window-title-preexec
  add-zsh-hook precmd set-window-title-precmd
}

# functions to set up zsh special variables
function zrc-module-path () {
  module_path=($module_path /usr/local/lib/zpython)
}
function zrc-fignore () {
  # file endings to ignore for completion
  fignore=($fignore '~' .o .bak '.sw?')
}
function zrc-fpath () {
  local trypath
  # functions for completion and user defined functions
  for trypath in                              \
      /usr/local/share/zsh-completions        \
      $ZDOTDIR/functions
  do
    if [[ -d $trypath && -z $fpath[(r)$trypath] ]]; then
      fpath=($trypath $fpath)
    fi
  done
}

# functions to set up the run-help function
function zrc-install-run-help () {
  local src=${ZSH_SOURCE_DIR:-~/vcs/zsh}/Util/helpfiles
  if [[ -r $src ]]; then
    mkdir -p $HELPDIR
    perl $src zshall $HELPDIR
  else
    return 1
  fi
  perl -e '
    use strict;
    use warnings;
    foreach my $filename (@ARGV) {
      open FILE, "<", $filename or die $!;
      while (<FILE>) {
	if ( m/^.*See the section `(.*). in (zsh[a-z]*)\(1\)\.$/ ) {
	  my $manpage = $2;
	  my $regex = $1;
	  close FILE;
	  open PROC, "-|", "man $manpage | colcrt -" or die $!;
	  open OUTFILE, ">", $filename or die $!;
	  my $on = 0;
	  while (<PROC>) {
	    # TODO
	    if ( /^$regex/i ) {
	      $on = 1;
	      print OUTFILE;
	      next;
	    }
	    if ($on) {
	      last if /^[A-Z]/;
	      print OUTFILE;
	    }

	  }
	  close PROC;
	  close OUTFILE;
	  last; # out, back to the foreach loop
	}
      }
    }
    ' $HELPDIR/*(.)
}
function zrc-run-help () {
  autoload -Uz run-help
  unalias run-help
  zrc-vi-bindkey '^H' run-help
  HELPDIR=${XDG_DATA_HOME:-~/.local/share}/zsh/help
  # install the files when needed
  if [[ ! -d $HELPDIR ]]; then
    zrc-install-run-help
  fi
  # further helper functions
  autoload run-help-git
  autoload run-help-openssl
  autoload run-help-sudo
  function run-help-ssh () {
    emulate -LR zsh
    local -a args
    # Delete some ssh options that are known to accept arguments
    zparseopts -D -E -a args \
      b: c: D: E: e: F: I: i: J: L: l: m: O: o: p: Q: R: S: W: w:
    # Delete other options, leaving: host command
    args=(${@:#-*})
    if [[ ${#args} -lt 2 ]]; then
      man ssh
    else
      run-help $args[2,-1]
    fi
  }
}

# functions to set xxx
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
function zrc-zsh-mime-handling-setup () {
  autoload zsh-mime-setup
  zsh-mime-setup
}
function zrc-setup-history-statistics () {
  # Collect data about executed commands.
  #HISTORY_STATISTICS_FILE=~/.cache/zsh/history-statistics
  function save-history-statistics () {
    local timestamp=%D{%s}
    print "${(%)timestamp}:$1" >> ~/.cache/zsh/history-statistics
  }
  autoload add-zsh-hook
  add-zsh-hook preexec save-history-statistics
}
function zrc-set-up-mail-warning-variables () {
  if [[ "$TTY" = /dev/tty* ]]; then
    mailpath=(~/.cache/notmuch/new-mail-marker ~/mail/inbox)
    set -U
  fi
}
function zrc-set-up-autosuggest-plugin () {
  zrc-source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE=fg=10
}
function zrc-set-up-reporttime-and-reportmem () {
  REPORTTIME=5
  #REPORTMEMORY=50
}

# start up notifications
function zrc-khal-notifications () {
  # only continue if khal is installed
  [[ -x =khal ]] || return
  local marker1=~/.cache/zsh/startup-calendar-timestamp-1
  local marker2=~/.cache/zsh/startup-calendar-timestamp-2
  # prompt expand sequence for the current time in seconds since EPOCH
  local epoch=%D{%s}
  #make --quiet -C ~/.config/khal
  zmodload -F zsh/stat b:zstat
  # marker1 is used every 12 hours
  if (( ${(%)epoch} > $(zstat +mtime $marker1) + 43200 )); then
    khal --color calendar --days=7 | tee $marker1
  # marker 2 is used every hour
  elif (( ${(%)epoch} > $(zstat +mtime $marker2) + 3600 )); then
    khal --color calendar --days=2 | tee $marker2
  fi
}
function zrc-khal-notifications-2 () {
  # only continue if khal is installed
  [[ -x =khal ]] || return
  local marker=~/.cache/zsh/startup-calendar-timestamp
  local image=~/.cache/khal/ascii-dump.txt
  # prompt expand sequence for the current time in seconds since EPOCH
  local epoch=%D{%s}
  zmodload -F zsh/stat b:zstat
  # Display the image if it is newer than the marker (last time it was viewed)
  # or if it was not displayed for some time.
  if [[ $image -nt $marker ]] || (( ${(%)epoch} > $(zstat +mtime $marker) + 3600 )); then
    cat $image
    touch $marker
  fi
}

# functions to set up completion
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
  zstyle ':completion:*' cache-path ${XDG_CACHE_HOME:-~/.cache}/zsh/completion
}
function zrc-zstyle-other () {
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
  # ignore some files when completion files for my editor
  zstyle ':completion:*:*:nvim:*:*files' ignored-patterns '*.pdf' '*.lock'
  zstyle ':completion:*:*:v:*:*files' ignored-patterns '*.pdf' '*.lock'
}
function zrc-zstyle-todo () {
  zstyle ':completion:*' muttrc ~/.mutt/muttrc
  zstyle ':completion:*' mail-directory ~/mail
  zstyle ':completion:*' mailboxes ~/mail
  # Copied from the _git completion file.  This enables completion of custom
  # git subcommands (git-* files in $PATH).
  zstyle ':completion:*:*:git:*' user-commands \
    ${${(M)${(k)commands}:#git-*}/git-/}
}
function zrc-zstyle-hosts () { # new
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
  netrc=(${${(@M)${(f)"$(cat ${NETRC:-~/.netrc(N)} /dev/null)"}:#machine *}#machine })
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
  ssh_config=(${=${${${(@M)${(f)"$(cat ~/.ssh/config(N) /dev/null)"}:#Host *}#Host }:#*[*?]*}})
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
  compdef colordiff=diff
  #compdef pip2=pip
  compdef _gnu_generic afew
}

# main functions
zrc-main () {
  # local variables
  local ZRC_UNAME=$(uname)

  source $ZDOTDIR/aliases

  zrc-meta-prompt

  zrc-autoloading
  zrc-module-path
  zrc-fignore
  zrc-fpath

  zrc-keymap
  zrc-run-help

  zrc-zmodload
  zrc-set-up-window-title
  zrc-setup-history-statistics
  zrc-set-up-mail-warning-variables
  zrc-set-up-autosuggest-plugin
  zrc-set-up-reporttime-and-reportmem

  zrc-compinit

  zrc-khal-notifications-2
}

# call main
zrc-main

# unset all local functions
unfunction -m 'zrc-*'
