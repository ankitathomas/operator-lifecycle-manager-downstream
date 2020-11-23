#!/bin/bash

set -eu

source "$(dirname $0)/utils.sh"

case "$*" in
	*" -h"*|"-h"|*" --help"*|"--help"|"")
	echo "Add a new upstream repository to track in the $staging_dir directory"
	echo "usage: $0 <git remote url>"
	exit 0
	;;
esac

# check if remote is valid
git ls-remote $1 

remote_url=$1

remote_name=$(echo $remote_url | sed 's!.*/\([^\/]*\)!\1!' | sed 's/.git$//')
remote_dir="$staging_dir/$remote_name"
update_tracked=false
add_subtree=false

if [ "|$remote_name|" == "||" ]; then
	exit_on_error "cannot get repository name from $remote_url"
fi

if [ $(grep "$remote_name " $repo_list | sed 's/.* \(.*\)/\1/' | wc -c) -gt 0 ]; then
	tracked_url=$(grep "$remote_name " $repo_list | sed 's/.* \(.*\)/\1/')
	if [ $tracked_url != $remote_url ]; then
		echo "remote $remote_name tracked with url $tracked_url"
		# prefer url in repo_list file
		remote_url=$tracked_url
	fi
else
	update_tracked=true
fi

if [ $(git remote get-url $remote_name | wc -c) -eq 0 ]; then
	git remote add $remote_name $remote_url
fi

# check if directory is present on subtree_dir
if [ ! -d "$remote_dir" ]; then
	git rev-parse --symbolic-full-name --abbrev-ref HEAD >/dev/null 2>&1 || exit_on_error "invalid ref HEAD, cannot add subtree" $?

	git diff-index --quiet HEAD || exit_on_error "Git status not clean, aborting !!\\n\\n$(git status)" $?

	# add the subtree
	git remote update $remote_name
	ref=$(git show-ref remotes/$remote_name/master -s)
	git subtree add --prefix="$remote_dir" "$remote_name" --squash master
	echo "Added new subtree $remote_dir"
	add_subtree=true
else
	echo "$remote_dir already exists"
fi

if $update_tracked ; then
	echo "$remote_name $remote_url" >> $repo_list
	git add $repo_list
	if [ $add_subtree ]; then
		git commit --amend --no-edit
	else
		git commit -m "update tracked remotes for $remote_name"
	fi
	add_subtree=true
fi

if $add_subtree ; then
	# push to subtree dir
	FORK_REMOTE=${FORK_REMOTE:-origin}
	fork_branch="add_tracked_upstream_$remote_name"	
	git push ${FORK_REMOTE} ${temp_branch}:"refs/heads/$fork_branch"
	echo "Pushed changes to ${FORK_REMOTE} ${temp_branch}:$fork_branch"
	echo "You can now create a PR for the update"
else
	echo "repository already present and tracked, nothing to do"
fi

cleanup_and_reset_branch

exit 0
