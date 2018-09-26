# git functions for the bash prompt -----------------------
function parse_git_branch() {
    #git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'

    # Declaring variables
    local BRANCH 
    #=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
    local special_state
	local upstream
	local is_branch
	local result
	local COMMITSTATUS
	local AHEAD
	local BEHIND

	if BRANCH=$(git rev-parse --abbrev-ref HEAD 2> /dev/null); then
		if [[ "$BRANCH" == "HEAD" ]]; then
			# Check for tag.
			BRANCH=$(git name-rev --tags --name-only $(git rev-parse HEAD))
			if ! [[ $branch == *"~"* || $branch == *" "* || $branch == undefined ]]; then
				branch="+${BRANCH}"
			else
				branch='<detached>'
				# Or show the short hash
				#branch='#'$(git rev-parse --short HEAD 2> /dev/null)
				# Or the long hash, with no leading '#'
				#branch=$(git rev-parse HEAD 2> /dev/null)
			fi
		else
			# This is a named branch.  (It might be local or remote.)
			upstream=$(git rev-parse '@{upstream}' 2> /dev/null)
			is_branch=true
		fi

		local git_dir="$(git rev-parse --show-toplevel)/.git"

		if [[ -d "$git_dir/rebase-merge" ]] || [[ -d "$git_dir/rebase-apply" ]]; then
			special_state=rebase
		elif [[ -f "$git_dir/MERGE_HEAD" ]]; then
			special_state=merge
		elif [[ -f "$git_dir/CHERRY_PICK_HEAD" ]]; then
			special_state=pick
		elif [[ -f "$git_dir/REVERT_HEAD" ]]; then
			special_state=revert
		elif [[ -f "$git_dir/BISECT_LOG" ]]; then
			special_state=bisect
		fi

		if [[ -n "$special_state" ]]; then
			result="{$BRANCH\\$special_state}"
		elif [[ -n "$is_branch" && -n "$upstream" ]]; then

			# Comparing commits w/ upstream
			local brinfo=$(git branch -v 2> /dev/null | grep "* $BRANCH")

		    if [[ $brinfo =~ (\[ahead ([0-9]*)) ]]; then
		        AHEAD="${BASH_REMATCH[2]}"
		    fi

		    if [[ $brinfo =~ (behind ([0-9]*)) ]]; then
		        BEHIND="${BASH_REMATCH[2]}"
		    fi

		    if [[ ! -z "$AHEAD" ]]; then
				COMMITSTATUS="$AHEAD"$'\u2197' #2198 for down
				if [[ ! -z "$BEHIND" ]]; then
					COMMITSTATUS="$COMMITSTATUS $BEHIND"$'\u2198' #2198 for down
				fi
			else
				if [[ ! -z "$BEHIND" ]]; then
					COMMITSTATUS="$BEHIND"$'\u2198' #2198 for down
				fi
			fi

			result="$BRANCH"

			if [[ ! -z "$COMMITSTATUS" ]]; then
				result="$result | $COMMITSTATUS"
			fi

			result="($result)"     # Branch has an upstream

		elif [[ -n "$is_branch" ]]; then
			result="[$BRANCH]"     # Branch has no upstream
		else
			result="<$BRANCH>"     # Detached
		fi

		result=" $result"
	else
		result=""
	fi    

	echo "$result"
}

PS1="\[\033[36m\]\u\[\033[m\]@\[\033[32m\]\h\[\033[m\]:\[\033[33;1m\]\W\[\033[36;1m\]\$(parse_git_branch)\[\033[m\] \$ "
export PS1
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad
