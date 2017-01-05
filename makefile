DEPS = \
       fzf                              \
       zsh-autosuggestions              \
       zsh-completions                  \
       zsh-doc                          \
       zsh-history-substring-search-git \
       zsh-lovers                       \
       zsh-syntax-highlighting          \

       # Should be pulled by the above.
       #zsh

install-deps:
	pacaur -S $(DEPS)
	$(MAKE) -C ../pam
