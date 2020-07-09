# .bashrc

#
# Source global definitions
#
test -f /etc/bashrc  && source /etc/bashrc
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi


#
# Setup conda, include local rc's
#
CONDA_ENV='base'
CONDA_ROOT=$HOME/.conda
activate_conda_env() { conda activate $1 ; }
# list_conda_envs() { conda info --envs --json | jq  -r '.envs[]' | xargs -n 1 basename | egrep -v '(anaconda|.conda)' | cat - <(echo "base"); }
list_conda_envs() { ls $HOME/.conda/envs | cat - <(echo "base");  }

test -f ~/.bashrc_local && source ~/.bashrc_local
test -f ~/.bashrc.`hostname` && source ~/.bashrc.`hostname`

. $CONDA_ROOT/etc/profile.d/conda.sh

#
# No pesky folders in ~
#
export SEABORN_DATA=$HOME/.cache/seaborn-data
export SCIKIT_LEARN_DATA=$HOME/.cache/scikit_learn_data


#
# Configure PATH
#
ensure_in_path() {
	tr ':' '\n' <<< $PATH | grep -q $1 || {
		export PATH=$1:$PATH
	}
}
ensure_in_path $HOME/.local/bin
ensure_in_path $HOME/scripts


# test -f ~/.bashfuncs && source ~/.bashfuncs


#
# Configure tmux
#
tmux_prompt::exit_status() {
	local status=$?

	[ $status -eq 0 ] && \
		echo -n "000" || \
		printf "%.3d" $status	
		# BROKEN: Some bug in bash 4.3 makes 'Home' unusable.
		# 		  The cursor jumps not to the line start but to 
		#         linestart + n chars, where n seems to equal to 
		#		  the color codes length.	
		# printf "\e[31m%.3d\e[0m" $status	
}

tmux_prompt() {
	export PS1='$(tmux_prompt::exit_status) $(jobs -l | wc -l) \\$ '
}

test -n "$TMUX" && {	

	this_env=$(tmux display-message -p '#S' | sed 's/\(.*\)\/.*/\1/' )
	
	list_conda_envs | grep -q $this_env && {		
		echo "Activating $this_env"
		activate_conda_env $this_env
 	} || {
 		echo "Did not found $this_env, activating $CONDA_ENV"
 		activate_conda_env $CONDA_ENV
 	} 	

 	tmux_prompt	
	
} || {
	activate_conda_env $CONDA_ENV
}

eval `dircolors -b ~/.LS_COLORS`

# Aliases
alias b='bash'
alias xclip="xclip -selection c"
alias ls='ls --color=auto'

alias dotgit='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'

# Allow coredumps
ulimit -c unlimited


#
# Eternal bash history.
#
# See: https://stackoverflow.com/a/19533853/3165667
#
export HISTFILESIZE=
export HISTSIZE=
export HISTTIMEFORMAT="[%F %T] "
export HISTFILE=~/.bash_eternal_history
PROMPT_COMMAND="history -a; $PROMPT_COMMAND"