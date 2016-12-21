DEPS = \
       fzf                              \
       zsh                              \
       zsh-autosuggestions              \
       zsh-completions                  \
       zsh-doc                          \
       zsh-history-substring-search-git \
       zsh-lovers                       \
       zsh-syntax-highlighting          \

install-deps:
	pacaur -S $(DEPS)
