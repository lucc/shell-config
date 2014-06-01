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
# this and dircolors in general
#if [ "$TERM" != "dumb" ]; then eval "`dircolors -b`"; fi

# local variables (unset at eof) {{{1
typeset -A vars
case `uname` in
  Darwin)
    # This variable will expand to the nullstring if we are not on Mac OS X or
    # brew is not installed.
    vars[prefix]=`brew --prefix 2>/dev/null`
    vars[syn]=${vars[prefix]}/share/
    ;;
  Linux)
    vars[syn]=/usr/share/zsh/plugins/
    ;;
esac
vars[syn]+=zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# zsh arrays (fignore, fpath) {{{1

# file endings to ignore for completion
fignore=($fignore '~' .o .bak '.sw?')

# zle stuff
zle_highlight=(region:bg=green special:bg=blue suffix:fg=red isearch:fg=yellow)

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

# autoloading and modules {{{1
autoload -Uz add-zsh-hook
autoload -Uz colors && colors
#autoload -Uz checkmail
autoload -Uz run-help
autoload -Uz vcs_info
autoload -Uz compinit

# autoloading user defined functions
autoload -Uz $ZDOTDIR/functions/*(:t)

zmodload zsh/sched
zmodload zsh/zprof

# files to be sourced {{{1

for file in ~/.profile       \
	    $ZDOTDIR/aliases
do if [[ -r $file ]]; then source $file; fi; done

## make less more friendly for non-text input files, see lesspipe(1)
if whence -p lesspipe &>/dev/null; then
  eval "$(lesspipe)"
elif whence -p lesspipe.sh &>/dev/null; then
  eval "$(lesspipe.sh)"
fi

# autojump or similar {{{2
if [[ -r $vars[prefix]/etc/profile.d/z.sh ]]; then
  # read man z
  export _Z_DATA=~/.cache/z
  _Z_CMD=j source ${vars[prefix]}/etc/profile.d/z.sh
  add-zsh-hook chpwd _z_precmd
  unalias j
  function j () {
    _z $@ 2>&1 && echo ${fg[red]}`pwd`$reset_color
  }
elif [[ -r /usr/share/autojump/autojump.sh ]]; then
  #export AUTOJUMP_KEEP_SYMLINKS=1
  source /usr/share/autojump/autojump.sh
elif [[ -r ${vars[prefix]}/etc/autojump.sh ]]; then
  #export AUTOJUMP_KEEP_SYMLINKS=1
  source $vars[prefix]/etc/autojump.sh
fi

# syntax highlighting {{{2
if [[ -r ${vars[syn]} ]]; then
  source ${vars[syn]}
fi

# homesick for automatic dotfiles setup {{{2
source ~/.homesick/repos/homeshick/homeshick.sh

# VCS info stuff {{{1
zstyle ':vcs_info:*' actionformats '%F{cyan}%s%F{green}%c%u%b%F{blue}%a%f'
####TODO
zstyle ':vcs_info:*' formats       '%F{cyan}%s%F{green}%c%u%b%f'
zstyle ':vcs_info:(sv[nk]|bzr):*' branchformat '%b%F{1}:%F{3}%r'
zstyle ':vcs_info:*' enable git svn cvs hg
# change color if changes exist (with %c and %u)
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' stagedstr '%F{yellow}'
zstyle ':vcs_info:*' unstagedstr '%F{red}'

# functions that can be used to change the defaults of the vcs-info code {{{2
# turn the name 'git' into '±' {{{3
function +vi-git-string() {
  hook_com[vcs]='±'
}

function +vi-hg-string() {
  hook_com[vcs]='☿'
}

# Add information about untracked files to the branch information {{{3
# idea from http://briancarper.net/blog/570
function +vi-git-add-untracked-files () {
  if [[ -n $(git ls-files --other --exclude-standard 2> /dev/null) ]]; then
    hook_com[branch]+='%F{red}?%f'
  fi
}

# register the functions with the correct hooks
zstyle ':vcs_info:git+set-message:*' hooks \
  git-add-untracked-files                  \
  git-string                               \

zstyle ':vcs_info:hg+set-message:*' hooks hg-string

# prompt {{{1
function execution-time-helper-function () {
  (( _start = $SECONDS ))
  (( _threshold = _start + 10 ))
}
typeset -i _threshold
typeset -i _start

add-zsh-hook precmd vcs_info
add-zsh-hook preexec execution-time-helper-function

# PS1 prompt {{{2
PS1='[ '                                               # frame
PS1+='%(!.%F{red}.%F{green})'                          # user=green, root=red
PS1+='%n%F{cyan}@%F{blue}%m%f'                         # user and host info
PS1+=' | '                                             # delimiter
PS1+='%F{cyan}%1~%f'                                   # working directory
PS1+=' | '                                             # delimiter
PS1+='${vcs_info_msg_0_:+$vcs_info_msg_0_ | }'         # VCS info with delim.
PS1+='%D{%H:%M:%S}'                                    # current time
#PS1+='%D{%H:%M:%S} (BKK: $(TZ=Asia/Bangkok date +%R))' # current time+Bangkok
PS1+=' ] '                                             # frame

# RPS1 prompt {{{2
RPROMPT='%(?.'                                    # if $? = 0
RPROMPT+='%(${_threshold}S.'                      #   if _threshold < SECONDS
RPROMPT+='%F{yellow}'                             #     switch color
RPROMPT+='Time: $((SECONDS-_start))%f'            #     duration of command
RPROMPT+='.)'                                     #   else, fi
if [[ $(uname) = Darwin ]]; then                  #   if OS X
  RPROMPT+=' $(battery.sh -bce zsh)'              #     battery information
fi                                                #   fi
RPROMPT+='.'                                      # else
RPROMPT+='%F{yellow}'                             #   switch color
RPROMPT+='Time: $((SECONDS-_start)) '             #   duration of command
RPROMPT+='%F{red}'                                #   switch color
RPROMPT+='Error: %?'                              #   error message
RPROMPT+=')'                                      # fi

# If we are in Conque Term inside Vim use a different prompt {{{2
if [[ $CONQUE -eq 1 ]]; then
  PS1='[ %F{green}%n%F{cyan}@%F{blue}%m%f '       # user and host info
  PS1+='| %F{cyan}%1~%f '                         # working directory
  PS1+='| %(?.%D{%H:%M:%S}.%F{red}Error %?%f) ] ' # curren time or error
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

# starting the completion system {{{2
compinit
compdef gpg2=gpg
compdef colordiff=diff

# run-help and other stuff {{{1
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
hash -d p=~/uni/philosophie
hash -d x=~/.config/secure/xml

#  unset local variables and last steps {{{1
unset vars
