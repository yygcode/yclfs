# * -- ~/.profile: executed by bash(1) for login shells.

if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
fi

if [ -d ~/bin ]; then
	PATH="$HOME/bin:$PATH"
fi

