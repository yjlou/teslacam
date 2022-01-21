# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

export PS1='\e[47;30m[RPi]\e[0m\[\e[0;31m\][\[\e[1;34m\]\t\[\e[0;31m\]]\[\e[0;31m\]\u\[\e[0;33m\]@\[\e[0;32m\]\h:\[\e[0;33m\]\w \[\e[0m\]$ \[\e[0m\]'

alias tn='tmux new-session -t'
alias tl='tmux list-sessions'
alias ta='tmux attach -d -t'

set LC_ALL=en_US.utf-8
set LANG=en_US.utf-8
set LANGUAGE=en_US.utf-8
set LESSCHARSET=utf-8

# Set terminal title
set_term_title() {
    local t="$@"
    echo -n -e "\033]0;${t}\007"
}

# Disable terminal software flow contorl (ctrl+s and ctrl+q)
# But this could introduce warning message in ssh remote execution. Don't run it in that mode.
[[ $- == *i* ]] && stty -ixon -ixoff
