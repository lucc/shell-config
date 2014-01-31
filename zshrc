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

# TODO: from bashrc {{{1
## make less more friendly for non-text input files, see lesspipe(1)
#if [[ -x /usr/bin/lesspipe ]]; then eval "$(lesspipe)"
#elif [[ -x $BREW/bin/lesspipe.sh ]]; then eval "$(lesspipe.sh)"
#fi
# TODO: from bashrc {{{1
#if [[ -r $BREW/etc/bash_completion ]]; then . $BREW/etc/bash_completion; fi
# TODO: from bashrc {{{1
#if [[ -r $BREW/etc/profile.d/z.sh ]]; then _Z_CMD=j . $BREW/etc/profile.d/z.sh; fi
# TODO: from bashrc {{{1
# this and dircolors in general
#if [ "$TERM" != "dumb" ]; then eval "`dircolors -b`"; fi

# local variables (unset at eof) {{{1
# This variable will expand to the nullstring if we are not on Mac OS X or
# brew is not installed.
BREW=`brew --prefix 2>/dev/null`

# zsh arrays (fignore, fpath) {{{1

# file endings to ignore for completion
fignore=($fignore '~' .o .bak '.sw?')

# zle stuff
zle_highlight=(region:bg=green special:bg=blue suffix:fg=red isearch:fg=yellow)

# functions for completion
for trypath in                       \
    /usr/local/share/zsh-completions \
    $ZDOTDIR/functions               \
  ; do
  if [[ -d $trypath ]]; then
    fpath=($trypath $fpath)
  fi
done

# files to be sourced (and similar) {{{1
for file in                                                         \
    $ZDOTDIR/aliases                                                \
    $ZDOTDIR/private                                                \
    $BREW/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  ; do
  if [[ -r $file ]]; then source $file; fi
done

# tempfix, wrong place
autoload add-zsh-hook

if [[ -r $BREW/etc/profile.d/z.sh ]]; then
  # read man z
  _Z_CMD=j source $BREW/etc/profile.d/z.sh
  autoload add-zsh-hook
  add-zsh-hook chpwd _z_precmd
  unalias j
  autoload colors && colors
  function j () {
    _z "$@" 2>&1 && echo $fg[red]`pwd`$reset_color
  }
elif [[ -r /usr/share/autojump/autojump.sh ]]; then
  #export AUTOJUMP_KEEP_SYMLINKS=1
  source /usr/share/autojump/autojump.sh
elif [[ -r $BREW/etc/autojump.sh ]]; then
  #export AUTOJUMP_KEEP_SYMLINKS=1
  source $BREW/etc/autojump.sh
fi

# prompt {{{1
# functions for the prompt {{{2

# functions to dispay info in the prompts
function right-prompt-function () {
  if [[ `uname` = Darwin ]]; then
    echo "${vcs_info_msg_0_} `battery.sh -bce zsh`"
  else
    echo "$vcs_info_msg_0_"
  fi
}

#function chpwd () { _z --add "$(pwd -P)"; }
#function precmd () { _z --add "$(pwd -P)"; }
add-zsh-hook precmd vcs_info
#precmd () { vcs_info }

# main prompt {{{2

# PS1 prompt
PS1="[ %(!.%F{red}.%F{green})%n%F{cyan}@%F{blue}%m%f | %F{cyan}%1~%f | %D{%H:%M:%S} ] "

# RPS1 prompt
RPROMPT='%(?.$(right-prompt-function).%F{red}Error: %?)'

# If we are in Conque Term inside Vim use a different prompt
if [[ "$CONQUE" -eq 1 ]]; then
  PS1="[ %F{green}%n%F{cyan}@%F{blue}%m%f | %F{cyan}%1~%f | %(?.%D{%H:%M:%S}.%F{red}Error %?%f) ] "
  unset RPROMPT
fi

# options {{{1

# contolling the history
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

# options
setopt extended_glob
setopt no_no_match
setopt prompt_subst

# interesting options:
setopt auto_cd
setopt glob_dots
#setopt print_exit_value
setopt no_list_ambiguous

# keybindings {{{1
bindkey -v

# searching {{{2
bindkey -M viins '\C-r' history-incremental-pattern-search-backward
bindkey -M vicmd '\C-r' history-incremental-pattern-search-backward
bindkey -M viins '\C-s' history-incremental-pattern-search-forward
bindkey -M vicmd '\C-s' history-incremental-pattern-search-forward

# arrow keys {{{2
bindkey -M viins '\e[A' up-line-or-search
bindkey -M vicmd '\e[A' up-line-or-search
bindkey -M viins '\e[B' down-line-or-search
bindkey -M vicmd '\e[B' down-line-or-search

if [[ `uname` = Darwin ]]; then
  # FIXME: how can I communicate this through a ssh session?
  bindkey -M viins '\e[H' beginning-of-line
  bindkey -M vicmd '\e[H' beginning-of-line
  bindkey -M viins '\e[F' end-of-line
  bindkey -M vicmd '\e[F' end-of-line
  bindkey -M viins '\e[1;2C' vi-forward-word
  bindkey -M vicmd '\e[1;2C' vi-forward-word
  bindkey -M viins '\e[1;2D' vi-backward-word
  bindkey -M vicmd '\e[1;2D' vi-backward-word
elif [[ `uname` = Linux ]]; then
  if [[ "$TERM" =~ rxvt ]]; then
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
  if [[ -r /etc/arch-release ]] && [[ ! -z "$SSH_CLIENT" && ! -z "$SSH_CONNECTION" && ! -z "$SSH_TTY" ]]; then
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

# completion {{{1

# layout {{{2

zstyle ':completion:*' list-prompt \
  %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' file-sort name
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt \
  %SScrolling active: current selection at %p%s

# performemce {{{2

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path $ZDOTDIR/cache

# other {{{2

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

# what do these do?
zstyle ':completion:*' muttrc ~/.mutt/muttrc
zstyle ':completion:*' mail-directory ~/mail
zstyle ':completion:*' mailboxes ~/mail


# ssh hosts {{{2
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

# TODO {{{3
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

# VCS stuff {{{2
autoload -Uz vcs_info
zstyle ':vcs_info:*' actionformats '%F{cyan}%s%F{green}%c%u%b%F{blue}%a%f'
####TODO
zstyle ':vcs_info:*' formats       '%F{cyan}%s%F{green}%c%u%b%f'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git svn cvs hg
# change color if changes exist (with %c and %u)
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{yellow}'
zstyle ':vcs_info:*' unstagedstr '%F{red}'

# turn the name 'git' into '±' {{{3
#zstyle ':vcs_info:git+set-message:*' hooks fixgitstring
function +vi-fixgitstring() {
  hook_com[vcs]='±'
}

# Add information about untracked files to the branch information {{{3
# idea from http://briancarper.net/blog/570
zstyle ':vcs_info:git+set-message:*' hooks git-add-untracked-files
function +vi-git-add-untracked-files () {
  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    hook_com[branch]+='%F{red}!%f'
  fi
}

# starting the completion system {{{2
autoload -Uz compinit
compinit
compdef gpg2=gpg
compdef colordiff=diff

# aoutoloading stuff {{{1
autoload colors
#autoload checkmail
unalias run-help
autoload run-help
HELPDIR=~/zsh_help
bindkey -M viins '\C-h' run-help
bindkey -M vicmd '\C-h' run-help

# directory hash table
######################
#hash -d i=~/Pictures
#hash -d m=~/Music
hash -d t=~/tmp
hash -d u=~/uni
hash -d v=/Volumes

# load zsh modules {{{1
zmodload zsh/sched
zmodload zsh/zprof

#  unset local variables and last steps {{{1
unset BREW
