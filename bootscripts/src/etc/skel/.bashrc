# ~/.bashrc: executed by bash(1) for non-login shells.

# non-interactive shell
[ -z "$PS1" ] && return

# control history list, colon separated
# valid values: ignoredups, ignorespace, erasedups, ignoreboth
HISTCONTROL=ignoreboth

# enbale history append
shopt -s histappend

# enable window size check after each command executes.
shopt -s checkwinsize

# PS1
#PS1=\
# '\[\e[1;34m\]\u\[\e[0;31m\]@\[\e[1;35m\]\h\
# \[\e[0;39m\]:\[\e[0;32m\]\w\$ \[\e[0;39m\]'

# dircolors -- color setup for ls
eval "$(dircolors -b)"

if [ -f "$HOME/.bash_aliases" ]; then
	. "$HOME/.bash_aliases"
fi

if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
	. /etc/bash_completion
fi
