# ~/.bash_aliases: included by ~/.bashrc

export COLOR_OPTIONS='--color=auto'

alias dir='dir $COLOR_OPTIONS'
alias vdir='vdir $COLOR_OPTIONS'
alias grep='grep $COLOR_OPTIONS'
alias egrep='egrep $COLOR_OPTIONS'

export LS_OPTIONS="$COLOR_OPTIONS"
alias ls='ls $LS_OPTIONS'
alias l='ls $LS_OPTIONS -CF'
alias la='ls $LS_OPTIONS -A'
alias ll='ls $LS_OPTIONS -l'
alias cp='cp -i'
alias mv='mv -i'
alias rm='rm -i'
